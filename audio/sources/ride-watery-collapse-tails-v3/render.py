#!/usr/bin/env python3
"""Give the two favored ruptures diminishing water tails without adding a persistent ambience bed."""

import array
import hashlib
import importlib.util
import json
import math
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'audio_helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
HELPERS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPERS)
RATE = 44100
BRIEF = (
    'Sean favors DD-S0108.5 and .6 but hears abrupt endings. Keep the sharp rupture, then soften the rubble and '
    'let a quieter water wash diminish smoothly to silence. No new constant environment loop or runtime change.'
)


def main() -> None:
    """Append two immutable revisions, retaining preferred originals and the current game sound."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve original delivery')
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    record = next(r for r in registry['sounds'] if r['id'] == 'DD-S0108')
    suffix = max(int(a['id'].split('.')[-1]) for a in record['alternatives']) + 1
    water = HELPERS.load('water', .78, 100, 2300)
    outputs = []
    for index, (original, name, end, tail_start) in enumerate([
        ('DD-S0108.5', 'Cascading washout — soft water tail', 2.05, .58),
        ('DD-S0108.6', 'Violent channel collapse — soft water tail', 2.4, .72),
    ]):
        source = ROOT / next(a['path'] for a in record['alternatives'] if a['id'] == original)
        with wave.open(str(source)) as stream:
            values = [v / 32767 for v in array.array('h', stream.readframes(stream.getnframes()))]
        source_length = len(values)
        # Preserve the initial attack exactly; taper the event body before its old endpoint.
        fade_start = round(tail_start * RATE)
        for i in range(fade_start, source_length):
            fraction = (i - fade_start) / max(1, source_length - fade_start - 1)
            values[i] *= (1 - fraction) ** 1.5
        values += [0.0] * (round(end * RATE) - len(values))
        tail = HELPERS.cut(water, end - tail_start, .25)
        tail = HELPERS.normalize(tail, -24)
        for i, value in enumerate(tail):
            t = i / RATE
            duration = len(tail) / RATE
            envelope = min(1, t / .16) * math.exp(-t * 2.8) * max(0, 1 - t / duration)
            values[fade_start + i] += value * envelope
        identity = f'DD-S0108.{suffix + index}'
        path = ROOT / 'audio/alternatives/DD-S0108' / f'{identity}.wav'
        evidence = HELPERS.write(path, values)
        record['alternatives'].append({'id': identity, 'path': evidence['path'], 'name': name,
            'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
            'provenance': 'Revision of retained CC0 water/rock + original turbulence mix; CC0 water tail.'})
        outputs.append({'id': identity, 'parent': original, 'parent_path': str(source.relative_to(ROOT)),
                        'parent_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                        'attack_unchanged_until_seconds': tail_start, **evidence})
    record['preferred_candidates'] = ['DD-S0108.5', 'DD-S0108.6']
    manifest = {'date': '2026-11-05', 'status': 'Preferred directions revised; tail acceptance pending',
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)), 'outputs': outputs,
                'parent_sources': 'audio/sources/ride-watery-collapse-v2/manifest.json',
                'tail_source': {'path': HELPERS.SOURCES['water'][0],
                                'sha256': hashlib.sha256((ROOT / HELPERS.SOURCES['water'][0]).read_bytes()).hexdigest(),
                                'license': 'CC0-1.0', 'author': 'rubberduck',
                                'evidence': 'audio/sources/player-death-flush-v1/manifest.json'},
                'processing': HELPERS.PROCESSING,
                'mix_note': 'Low-pass water at 2300Hz, quiet tail with exponential decay; event fades to silence.',
                'runtime_note': 'Current runtime track smash unchanged. Existing current_loop is configured at -12dB; '
                                'its perceived audibility under music has not been verified. No ambience added.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['duration_seconds']) for o in outputs])


if __name__ == '__main__':
    main()
