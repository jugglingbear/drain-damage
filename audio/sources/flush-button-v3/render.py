#!/usr/bin/env python3
"""Create water-filled vocal auditions from newly retained CC0 gargling performances."""

import hashlib
import importlib.util
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location('helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
BRIEF = ('Normal: trying to talk through a mouthful of water. Special: sustained gurgle-screaming through water, '
         '3–5 seconds. No cough/spit montage. New recorded gargles shaped into speech-like or forceful sustained '
         'gestures; these are approximations, not recordings of the exact requested acting performance.')
SOURCES = [('784056', 'FriendComIndustries'), ('119915', 'ftpalad'), ('218195', 'edhutschek')]


def main() -> None:
    """Preserve downloads and register four new, unselected treatments."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve existing delivery')
    source_records = []
    for identity, author in SOURCES:
        path = HERE / 'originals' / f'{identity}-hq.mp3'
        H.SOURCES[identity] = (str(path.relative_to(ROOT)), MANIFEST, author, 'CC0-1.0')
        source_records.append({'author': author, 'license': 'CC0-1.0',
                               'page': f'https://freesound.org/people/{author}/sounds/{identity}/',
                               'path': str(path.relative_to(ROOT)),
                               'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                               'format_note': 'Public HQ MP3 preview; not the login-gated original WAV/AIFF.',
                               'retained_license_page': str((path.parent / f'{identity}-source.html').relative_to(ROOT))})
    recipes = [
        ('fire', 'G — Short bubbling attempted phrase', '784056', 1.40, .15, 1.0),
        ('fire', 'H — Lower muffled attempted phrase', '218195', 1.75, .75, .96),
        ('gag', 'G — Rising voiced gargle', '784056', 3.30, 0, 1.08),
        ('gag', 'H — Deeper underwater gurgle', '119915', 3.80, .50, .98),
    ]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    outputs = []
    for key, label, source, duration, offset, speed in recipes:
        slot = next(row for row in registry['sounds'] if row['key'] == f'proposed-flush-button/{key}')
        values = H.cut(H.load(source, speed, 110, 7000), duration, offset)
        for i, value in enumerate(values):
            t = i / H.RATE
            if key == 'fire':
                # Unequal vocal stresses suggest attempted syllables without inserting coughs or other sounds.
                envelope = .24 + .76 * abs(math.sin(math.pi * (2.6 * t + .35 * t * t))) ** .65
                values[i] = value * envelope
            else:
                # Mild saturation brings forward the voice already inside the gargle; not a separate dry scream.
                values[i] = math.tanh(value * 2.0) * (.72 + .28 * min(1, t / .5))
        fade = round(.09 * H.RATE)
        for i in range(fade):
            values[-i - 1] *= i / fade
        candidate = slot['id'] + '.' + str(max(int(a['id'].split('.')[-1]) for a in slot['alternatives']) + 1)
        evidence = H.write(ROOT / 'audio/alternatives' / slot['id'] / f'{candidate}.wav', H.normalize(values, -6))
        slot['alternatives'].append({'id': candidate, 'path': evidence['path'], 'name': label,
                                     'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                                     'provenance': 'New CC0 recorded gargling; public HQ preview, edited and filtered.'})
        outputs.append({'id': candidate, 'description': label, 'source_id': source, 'speed': speed,
                        'offset_seconds_after_leading_trim': offset, **evidence})
    for slot in registry['sounds']:
        if slot['key'] in ['proposed-flush-button/fire', 'proposed-flush-button/gag']:
            for candidate in slot['alternatives']:
                if int(candidate['id'].split('.')[-1]) <= 6:
                    candidate['review_status'] = 'Not selected; Sean rejected the direction. Retained for reference.'
    (HERE / 'manifest.json').write_text(json.dumps({
        'date': '2026-11-25', 'status': 'Audition only; subjective selection pending; no runtime changes',
        'brief': BRIEF, 'sources': source_records, 'outputs': outputs, 'processing': H.PROCESSING,
        'recipe': str(Path(__file__).relative_to(ROOT)),
        'limitation': 'Source performances are gargles, not verified speech or screams; processing approximates intent.'
    }, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['description'], o['duration_seconds']) for o in outputs])


if __name__ == '__main__':
    main()
