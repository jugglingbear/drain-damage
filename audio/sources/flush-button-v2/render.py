#!/usr/bin/env python3
"""Render six longer drowning-panic and retching auditions from retained CC0 recordings."""

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
BRIEF = ('Unexpectedly thrown into a gigantic flushing toilet, swimming desperately toward safety while debris falls. '
         'Normal button: frightened human cries breaking into swallowed-water gurgles and gasps, not a monster. '
         'Special button: 3–5 seconds of coughing, gagging and puking, with irregular effort and recovery breath. '
         'DD-S0206.1 is only a relative preference, not approved. Preserve all prior candidates. Auditions only.')
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
        ('fire', 'D — Cry swallowed by water, then gasp', 1.85, [
            ('scream_01', 0, .78, 0, 1, 1.0), ('burble_01', .34, .66, .05, .65, 1.0),
            ('cough_01', .89, .34, 0, .8, 1.0), ('breath', 1.23, .58, 0, .85, 1.0),
            ('splash', .40, .28, .1, .10, 1.0)]),
        ('fire', 'E — Frantic cry, choke, second cry', 2.32, [
            ('scream_02', 0, .72, 0, 1, 1.03), ('burble_02', .37, .59, 0, .65, 1.05),
            ('cough_02', .83, .30, 0, .8, 1.0), ('scream_01', 1.10, .62, .13, .85, 1.04),
            ('burble_01', 1.36, .42, .20, .55, 1.05), ('breath', 1.76, .52, .03, .8, 1.05)]),
        ('fire', 'F — Strangled cry through a mouthful of water', 2.08, [
            ('scream_01', 0, .84, 0, 1, .97), ('burble_02', .15, .81, 0, .7, .98),
            ('cough_03', .88, .60, .05, .8, 1.05), ('breath', 1.48, .56, 0, .85, 1.0),
            ('spit_01', 1.25, .30, 0, .4, 1.0)]),
        ('gag', 'D — Double choke, wet heave, recovery breath', 3.65, [
            ('cough_01', 0, .38, 0, 1, 1.0), ('burble_01', .20, .50, 0, .65, 1.0),
            ('cough_02', .58, .32, 0, .9, 1.0), ('breath', .94, .43, .06, .65, 1.04),
            ('cough_03', 1.35, .72, 0, .95, 1.0), ('burble_02', 1.64, .85, 0, .85, .97),
            ('spit_02', 2.27, .60, 0, .8, 1.0), ('splash2', 2.43, .35, .1, .12, 1.0),
            ('cough_01', 2.87, .30, 0, .65, 1.07), ('breath', 3.14, .47, .05, .8, 1.0)]),
        ('gag', 'E — Repeated desperate coughs and long watery retch', 4.35, [
            ('cough_03', 0, .72, 0, 1, 1.0), ('cough_02', .59, .30, 0, .85, 1.03),
            ('burble_01', .78, .61, .06, .75, 1.0), ('breath', 1.35, .48, 0, .8, 1.08),
            ('cough_03', 1.85, .72, .03, 1, .96), ('burble_02', 2.13, .88, 0, .85, .96),
            ('spit_02', 2.81, .63, 0, .8, .98), ('cough_01', 3.31, .36, 0, .85, 1.0),
            ('breath', 3.70, .60, 0, .8, 1.0), ('splash', 2.90, .32, .1, .1, 1.0)]),
        ('gag', 'F — Fast sputtering fit with two wet heaves', 3.25, [
            ('cough_02', 0, .30, 0, 1, 1.04), ('cough_01', .29, .37, 0, .9, 1.0),
            ('burble_01', .49, .63, 0, .8, 1.05), ('spit_01', .94, .39, 0, .7, 1.04),
            ('breath', 1.27, .42, .05, .7, 1.08), ('cough_03', 1.66, .66, 0, 1, 1.03),
            ('burble_02', 1.92, .66, .05, .8, 1.0), ('spit_02', 2.34, .49, .03, .75, 1.04),
            ('breath', 2.78, .43, .05, .8, 1.06)]),
    ]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    slots = {key: next(row for row in registry['sounds'] if row['key'] == f'proposed-flush-button/{key}')
             for key in ['fire', 'gag']}
    slots['gag']['alternatives'][0]['review_status'] = (
        'Relative preference only; Sean says none match intended drowning panic. Not approved for integration.')
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
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(item['id'], item['description'], item['duration_seconds']) for item in outputs])


if __name__ == '__main__':
    main()
