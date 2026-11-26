#!/usr/bin/env python3
"""Render six audition-only flush gestures from retained CC0 recordings."""

import hashlib
import importlib.util
import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
BRIEF = ('Flush-only auditions: X/keyboard fire is a panicked watery gagging cry trying to catch breath; '
         'B is comedic watery gagging/puking. Recorded human mouth gestures and water, short responsive onset, '
         'no electronic voice, no runtime integration before selection.')
VOICE_MANIFEST = 'audio/sources/recorded-creatures-cc0-v1/manifest.json'
for name in ['scream_01', 'scream_02', 'cough_01', 'cough_02', 'cough_03', 'breath',
             'burble_01', 'burble_02', 'spit_01', 'spit_02', 'burp_01']:
    H.SOURCES[name] = (f'audio/sources/recorded-creatures-cc0-v1/rubberduck/{name}.ogg',
                       VOICE_MANIFEST, 'rubberduck', 'CC0-1.0')


def main() -> None:
    """Write new candidates, source hashes, recipes and proposed catalog slots."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve prior delivery')
    # Each tuple retains source, onset, slice duration, offset, gain and playback rate.
    recipes = [
        ('fire', 'A — Choked yelp and quick breath', 1.10, [
            ('scream_01', 0, .43, 0, 1, 1.06), ('burble_01', .18, .30, 0, .40, 1.05),
            ('cough_01', .43, .24, 0, .8, 1.05), ('breath', .70, .37, 0, .7, 1.1),
            ('splash', .10, .25, .1, .20, 1.1)]),
        ('fire', 'B — Broken cry with two sputters', 1.26, [
            ('scream_02', 0, .48, 0, 1, 1.0), ('cough_02', .40, .22, 0, .9, 1.1),
            ('cough_03', .65, .20, 0, .75, 1.12), ('breath', .90, .33, .1, .65, 1.05),
            ('burble_02', .12, .43, .05, .35, 1.1)]),
        ('fire', 'C — Low waterlogged cry and gasp', 1.38, [
            ('scream_01', 0, .65, .12, 1, .90), ('burble_02', .22, .45, 0, .50, .9),
            ('cough_03', .67, .27, 0, .8, .96), ('breath', .98, .37, .03, .8, .95),
            ('splash2', .35, .23, 0, .15, .95)]),
        ('gag', 'A — Quick wet double retch', .94, [
            ('cough_01', 0, .26, 0, 1, .96), ('burble_01', .16, .34, 0, .8, .95),
            ('cough_02', .47, .22, 0, .85, 1.02), ('spit_01', .64, .27, 0, .8, 1.0),
            ('splash', .65, .25, .1, .25, 1.0)]),
        ('gag', 'B — Deep rolling heave and spill', 1.34, [
            ('burp_01', 0, .39, 0, .7, .88), ('cough_03', .12, .34, 0, 1, .9),
            ('burble_02', .35, .59, 0, 1, .88), ('spit_02', .91, .39, 0, .75, .94),
            ('splash2', .90, .38, .08, .35, .95)]),
        ('gag', 'C — Rapid spluttering spit-take', 1.02, [
            ('cough_02', 0, .22, 0, 1, 1.14), ('spit_01', .19, .20, 0, .8, 1.14),
            ('burble_01', .34, .24, .1, .8, 1.15), ('cough_01', .53, .20, 0, .9, 1.15),
            ('spit_02', .72, .27, 0, .8, 1.1), ('splash', .73, .25, 0, .25, 1.15)]),
    ]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    number = max(int(row['id'][4:]) for row in registry['sounds']) + 1
    slots = {}
    for index, (key, name) in enumerate([
            ('fire', 'X / keyboard fire — panicked watery cry'), ('gag', 'B — watery gag / puke')]):
        slots[key] = {'id': f'DD-S{number + index:04d}', 'uuid': str(uuid.uuid4()),
                      'key': f'proposed-flush-button/{key}', 'section': 'Level 2',
                      'group': 'Flush button auditions — NOT IN GAME', 'name': name,
                      'status': 'proposed', 'paths': [], 'source': MANIFEST, 'alternatives': []}
    outputs = []
    used = set()
    for key, label, duration, layers in recipes:
        rendered = []
        for source, at, length, offset, gain, speed in layers:
            used.add(source)
            values = H.load(source, speed, 100, 9000)
            rendered.append((at, H.cut(values, length, offset), gain))
        values = H.mix(duration, rendered)
        # A short release avoids clicky cutoffs without an unresponsive trailing silence.
        fade = round(.055 * H.RATE)
        for index in range(fade):
            values[-index - 1] *= index / fade
        slot = slots[key]
        candidate = f"{slot['id']}.{len(slot['alternatives']) + 1}"
        evidence = H.write(ROOT / 'audio/alternatives' / slot['id'] / f'{candidate}.wav',
                           H.normalize(values, -6))
        slot['alternatives'].append({'id': candidate, 'path': evidence['path'],
                                     'name': f'{label} · {duration:.2f}s', 'source_manifest': MANIFEST,
                                     'generation_prompt': BRIEF,
                                     'provenance': 'Layered retained rubberduck CC0 mouth and water recordings.'})
        outputs.append({'id': candidate, 'action': key, 'description': label, 'layers': layers, **evidence})
    sources = {}
    for name in sorted(used):
        path, manifest, author, license_name = H.SOURCES[name]
        sources[name] = {'path': path, 'source_manifest': manifest, 'author': author, 'license': license_name,
                         'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest()}
    manifest = {'date': '2026-11-25', 'status': 'Auditions only; awaiting Sean selection; no runtime changes',
                'brief': BRIEF, 'sources': sources, 'processing': H.PROCESSING, 'outputs': outputs,
                'recipe': str(Path(__file__).relative_to(ROOT)),
                'validation': 'PCM format, headroom, onset/tail and non-silence checked; subjective listening pending.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry['sounds'].extend(slots.values())
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(item['id'], item['description'], item['duration_seconds']) for item in outputs])


if __name__ == '__main__':
    main()
