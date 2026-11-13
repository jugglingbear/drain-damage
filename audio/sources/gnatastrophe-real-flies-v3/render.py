#!/usr/bin/env python3
"""Create continuous fly-cloud auditions from a retained CC0 field recording."""

import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
SOURCE = HERE / '440809-PuzzleAudio-flies-hq.mp3'
BRIEF = (
    'Sean rejected DD-S0200.2 as not a buzzy insect cloud. Use actual recorded fly wing buzz as the whole identity. '
    'Three continuous six-second direction previews, not concatenated action reels. No monster mouth sounds, '
    'musical oscillators or digital chirps. Preserve current gameplay audio and all earlier candidates.'
)
CHOICES = [
    ('A — Close flying insects', [(1.0, 350, 9000, 2.0, 1.0), (1.02, 450, 8500, 19.0, .35)]),
    ('B — Dense restless cloud', [(1.0, 250, 8000, 5.0, .7), (.97, 250, 7500, 13.0, .65),
                                  (1.04, 350, 9000, 24.0, .55), (1.01, 500, 8500, 31.0, .45)]),
    ('C — Heavy sewer swarm', [(.86, 180, 6500, 8.0, .75), (.93, 200, 7000, 19.0, .7),
                                (1.0, 400, 8000, 29.0, .5)]),
]


def main() -> None:
    """Retain source and recipe and append fresh candidates without runtime promotion."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve original delivery')
    H.SOURCES['flies'] = (str(SOURCE.relative_to(ROOT)), MANIFEST, 'PuzzleAudio', 'CC0-1.0')
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    slot = next(record for record in registry['sounds'] if record['id'] == 'DD-S0200')
    for candidate in slot['alternatives']:
        if candidate['id'] == 'DD-S0200.2':
            candidate['review_status'] = 'Rejected by Sean: does not sound like a buzzy insect cloud.'
            candidate['name'] = 'REJECTED — ' + candidate['name']
    suffix = max(int(c['id'].split('.')[-1]) for c in slot['alternatives']) + 1
    outputs = []
    for index, (name, recipe) in enumerate(CHOICES):
        layers = []
        for speed, high, low, offset, gain in recipe:
            decoded = H.load('flies', speed, high, low)
            layers.append((0, H.cut(decoded, 6, offset), gain))
        values = H.mix(6, layers)
        fade_in, fade_out = round(.12 * H.RATE), round(.4 * H.RATE)
        for sample in range(fade_in):
            values[sample] *= sample / fade_in
        for sample in range(fade_out):
            values[-sample - 1] *= sample / fade_out
        identity = f'DD-S0200.{suffix + index}'
        evidence = H.write(ROOT / 'audio/alternatives/DD-S0200' / f'{identity}.wav', H.normalize(values, -12))
        candidate = {'id': identity, 'path': evidence['path'], 'name': f'REAL FLIES v3 · {name} · continuous 6s',
                     'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                     'provenance': 'PuzzleAudio CC0 actual fly field recording, public HQ MP3 preview; layered edits.'}
        slot['alternatives'].append(candidate)
        outputs.append({**candidate, **evidence, 'layers_speed_highpass_lowpass_offset_gain': recipe})
    manifest = {
        'date': '2026-11-11', 'status': 'Auditions only; no selection or runtime promotion', 'brief': BRIEF,
        'source': {'author': 'PuzzleAudio', 'title': 'Flies.wav', 'license': 'CC0-1.0',
                   'page': 'https://freesound.org/people/PuzzleAudio/sounds/440809/',
                   'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
                   'download': 'https://cdn.freesound.org/previews/440/440809_8523759-hq.mp3',
                   'format_note': 'Public HQ MP3 preview, not the original lossless WAV.',
                   'recording_description': 'Flies recorded with Rode NT3 and ZOOM H6.',
                   'license_evidence': 'https://freesound.org/people/PuzzleAudio/sounds/440809/',
                   'path': str(SOURCE.relative_to(ROOT)), 'sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest()},
        'recipe': str(Path(__file__).relative_to(ROOT)), 'processing': H.PROCESSING, 'outputs': outputs,
        'notes': ['Six-second continuous textures; not individual action mappings or runtime loops.',
                  'Slight rate differences and independent excerpts add insects; shared peak for comparison.',
                  'Original MP3 and rejected auditions retained. Listening selection pending.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['name']) for o in outputs])


if __name__ == '__main__':
    main()
