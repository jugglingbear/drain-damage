#!/usr/bin/env python3
"""Create two progressive compression gestures from preserved original dispenser synthesis."""

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main() -> None:
    """Keep staged cues short enough for the two distinct half-second animation beats."""
    manifest_path = HERE / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    squeeze = 'assets/audio/sfx/spare-employee-dispenser-v1/compression-squeak.wav'
    clunk = 'assets/audio/sfx/spare-employee-dispenser-v1/vending-clunk.wav'
    recipes = [
        ('compress-stage-one', .38, -6,
         '[0:a]atrim=duration=0.38,asetpts=N/SR/TB,afade=t=in:d=0.005,'
         'afade=t=out:st=0.33:d=0.05[out]'),
        ('compress-stage-two', .46, -3,
         '[0:a]asetrate=26240,aresample=44100,atrim=duration=0.46[a];'
         '[1:a]aresample=44100,asetrate=33075,aresample=44100,volume=0.45[b];'
         '[a][b]amix=inputs=2:normalize=0,apad,atrim=duration=0.46,'
         'alimiter=limit=0.2511886:level=0,afade=t=in:d=0.005,afade=t=out:st=0.39:d=0.07[out]'),
    ]
    for event, duration, gain, filters in recipes:
        path = ROOT / 'assets/audio/sfx/dispenser-verdict-v3' / f'{event}.wav'
        command = ['ffmpeg', '-v', 'error', '-n', '-i', str(ROOT / squeeze), '-i', str(ROOT / clunk),
                   '-filter_complex', filters, '-map', '[out]', '-ar', '44100', '-ac', '1',
                   '-c:a', 'pcm_s16le', str(path)]
        subprocess.run(command, check=True)
        manifest['cues'].append({'cue_id': event, 'path': str(path.relative_to(ROOT)),
                                'duration_seconds': duration, 'gain_db': gain, 'loop': False,
                                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
        manifest.setdefault('compression_recipes', []).append({'event': event, 'command': command})
    manifest['compression_sources'] = [{'path': p, 'sha256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()}
                                       for p in [squeeze, clunk]]
    manifest['compression_recipe'] = str(Path(__file__).relative_to(ROOT))
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
