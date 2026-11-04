#!/usr/bin/env python3
"""Preserve first renders and smooth the aim tail in versioned final candidates."""

import array
import hashlib
import json
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100


def main() -> None:
    """Fade the last 20 ms of aim and its corresponding combined preview passage."""
    manifest = json.loads((HERE / 'manifest.json').read_text())
    registry = json.loads((ROOT / 'audio/sound-registry.json').read_text())
    for output in manifest['outputs']:
        if output['event'] not in ('aim', 'sequence'):
            continue
        source = ROOT / output['path']
        target = source.with_name(source.stem + '-v2.wav')
        if target.exists():
            raise FileExistsError(target)
        with wave.open(str(source)) as audio:
            params = audio.getparams()
            samples = array.array('h', audio.readframes(audio.getnframes()))
        end = round((1.05 if output['event'] == 'aim' else 2.4) * RATE)
        count = round(.02 * RATE)
        for index in range(count):
            samples[end - count + index] = round(samples[end - count + index] * (count - index - 1) / count)
        with wave.open(str(target), 'wb') as audio:
            audio.setparams(params)
            audio.writeframes(samples.tobytes())
        output['preserved_first_render'] = {'path': output['path'], 'sha256': output['sha256']}
        output['path'] = str(target.relative_to(ROOT))
        output['sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
        for record in registry['sounds']:
            for candidate in record['alternatives']:
                if candidate['id'] == output['id']:
                    candidate['path'] = output['path']
    manifest['finishing_recipe'] = str(Path(__file__).relative_to(ROOT))
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (ROOT / 'audio/sound-registry.json').write_text(json.dumps(registry, indent=2) + '\n')


if __name__ == '__main__':
    main()
