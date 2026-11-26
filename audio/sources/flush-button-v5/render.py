#!/usr/bin/env python3
"""Prepare minimally edited excerpts of a newly sourced underwater scream performance."""

import array
import hashlib
import json
import math
import subprocess
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 48000
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = ('New natural performances for the flush special: audible human screaming through water, 3–5 seconds. '
         'Previous layered screams were rejected as raspy/8-bit. Preserve pitch and dynamics; only excerpt, '
         'level adjustment and edge fades. DD-S0205.7 remains the preferred normal attack.')


def excerpt(values: list[float], start: float, end: float) -> list[float]:
    """Cut at original speed with small edge fades, retaining the actual performance."""
    result = values[round(start * RATE):round(end * RATE)]
    count = round(.015 * RATE)
    for i in range(count):
        result[i] *= i / count
        result[-i - 1] *= i / count
    return result


def main() -> None:
    """Register two excerpts without adding synthesis, saturation or pitched layers."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this delivery')
    original = HERE / 'originals/752733-hq.mp3'
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(original), '-ac', '1', '-ar', str(RATE),
                          '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    values = list(array.array('f', raw))
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    slot = next(row for row in registry['sounds'] if row['id'] == 'DD-S0206')
    for candidate in slot['alternatives']:
        if candidate['id'] in ['DD-S0206.9', 'DD-S0206.10']:
            candidate['review_status'] = 'Rejected by Sean: raspy and 8-bit sounding. Preserved only as reference.'
    outputs = []
    for label, windows in [
            ('K — Underwater scream, two cries', [(1.08, 3.48), (4.26, 5.40)]),
            ('L — Underwater scream, later continuous passage', [(4.24, 7.49)])]:
        result = []
        for start, end in windows:
            result.extend(excerpt(values, start, end))
        gain = 10 ** (-6 / 20) / max(map(abs, result))
        pcm = array.array('h', [round(v * gain * 32767) for v in result])
        suffix = max(int(a['id'].split('.')[-1]) for a in slot['alternatives']) + 1
        candidate = f'DD-S0206.{suffix}'
        path = ROOT / 'audio/alternatives/DD-S0206' / f'{candidate}.wav'
        if path.exists():
            raise FileExistsError(path)
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(pcm.tobytes())
        relative = str(path.relative_to(ROOT))
        slot['alternatives'].append({'id': candidate, 'path': relative, 'name': label,
                                     'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                                     'provenance': 'simonjeffery13 CC0 actual underwater scream; public HQ MP3 source.'})
        outputs.append({'id': candidate, 'description': label, 'path': relative, 'source_windows_seconds': windows,
                        'duration_seconds': len(pcm) / RATE, 'gain_linear': gain, 'fade_seconds': .015,
                        'peak_dbfs': 20 * math.log10(max(map(abs, pcm)) / 32767),
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    source = json.loads((HERE / 'originals/752733-metadata.json').read_text())
    source.update({'path': str(original.relative_to(ROOT)),
                   'sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
                   'retained_license_page': str((HERE / 'originals/752733-source.html').relative_to(ROOT)),
                   'format_note': 'Public HQ MP3; original WAV requires login. WAV output does not restore lost detail.',
                   'performance': 'Creator describes himself screaming into a bathtub with an underwater microphone.'})
    (HERE / 'manifest.json').write_text(json.dumps({
        'date': '2026-11-25', 'status': 'New-source special auditions; awaiting Sean; no runtime integration',
        'brief': BRIEF, 'source': source, 'outputs': outputs, 'recipe': str(Path(__file__).relative_to(ROOT)),
        'processing': 'Mono decode at48kHz; native-speed cuts;15ms edge fades; linear peak normalization to-6dBFS.',
        'unused_research': 'originals/sources.json retains two other CC0 leads; neither used in these candidates.',
        'validation': 'Technical checks only. Source description establishes performance intent, not subjective approval.'
    }, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['duration_seconds']) for o in outputs])


if __name__ == '__main__':
    main()
