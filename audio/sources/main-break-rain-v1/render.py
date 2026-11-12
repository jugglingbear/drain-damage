#!/usr/bin/env python3
"""Prepare a broad water-patter loop and illustrative geyser-to-rain audition."""

import hashlib
import importlib.util
import json
import random
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    'helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))


def main() -> None:
    """Register versioned rain candidates without promoting runtime audio."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve delivery')
    rng = random.Random(121126)
    water = H.load('water', 1.12, 1200, 9500)
    splash = H.load('splash', 1.0, 650, 9000)
    size = 3 * H.RATE
    values = [0.0] * size
    layers = []
    for index in range(54):
        duration = rng.uniform(.08, .22)
        offset = rng.uniform(0, max(0, len(splash) / H.RATE - duration))
        at = index / 18
        gain = rng.uniform(.12, .32)
        clip = H.cut(splash, duration, offset)
        layers.append([at, duration, offset, gain])
        for sample, value in enumerate(clip):
            values[(round(at * H.RATE) + sample) % size] += value * gain
    for index in range(6):
        clip = H.cut(water, .8, index * .1)
        for sample, value in enumerate(clip):
            values[(round(index * .5 * H.RATE) + sample) % size] += value * .28
    values = H.normalize(values, -14)
    values[-1] = values[0]
    preview = [values[i % size] for i in range(round(7.5 * H.RATE))]
    for index in range(len(preview)):
        t = index / H.RATE
        preview[index] *= max(0, min(1, t / .1, (7.5 - t) / .6))
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    number = max(int(s['id'].split('S')[-1]) for s in registry['sounds']) + 1
    slot = {'id': f'DD-S{number:04d}', 'uuid': str(uuid.uuid4()),
            'key': 'proposed-starter-specials/sean-rain-core', 'section': 'Weapon sounds',
            'group': 'Sean Main Break', 'name': 'Broad rain sustain — redesign candidate',
            'status': 'proposed', 'paths': [], 'source': MANIFEST, 'alternatives': []}
    registry['sounds'].append(slot)
    preview_slot = next(s for s in registry['sounds'] if s['key'] == 'proposed-starter-specials/sean-preview')
    outputs = []
    for record, label, clip in [(slot, 'RAIN v1 · continuous3s loop', values),
                                (preview_slot, 'RAIN v1 · 7.5s rain phase with complete ending', preview)]:
        suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
        identity = f"{record['id']}.{suffix}"
        evidence = H.write(ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav', clip)
        record['alternatives'].append({'id': identity, 'path': evidence['path'], 'name': label,
            'source_manifest': MANIFEST,
            'provenance': 'Original rain-like texture layered from retained rubberduck CC0 water/splash recordings.'})
        outputs.append({'id': identity, **evidence})
    sources = {}
    for key in ['water', 'splash']:
        path, provenance, author, license_name = H.SOURCES[key]
        sources[key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                        'source_manifest': provenance, 'author': author, 'license': license_name}
    manifest = {'date': '2026-11-12', 'status': 'Rain audition candidate; subjective review and runtime adoption pending',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'sources': sources, 'outputs': outputs,
                'processing': H.PROCESSING, 'seed': 121126, 'splash_layers': layers,
                'loop_seconds': 3, 'suggested_gain_db': -8,
                'mapping': 'Rain clock0–7.5; loop offset0,fadein0.1,fadeout6.9–7.5. No independent stop tail.',
                'geyser': 'Reuse DD-S0133.4 at Art-confirmed onset (candidate3.2); crossfade to rain3.4–3.5.',
                'fallback': 'Keep current182 behavior until redesign integrated; never silently reuse bent-jet timing. '
                            'If new rain asset unavailable in redesigned runtime, fail preflight rather than ship silence.',
                'notes': ['Designed rain from existing water recordings, not a literal rainfall field recording.',
                          'Preview is rain phase only; no gameplay or damage timing implied.',
                          'No runtime files changed; final marker and listening review pending.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['path']) for o in outputs])


if __name__ == '__main__':
    main()
