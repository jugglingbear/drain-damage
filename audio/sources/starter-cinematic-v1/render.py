#!/usr/bin/env python3
"""Render the two missing Tony preparation cues; retain approved water and Sean assets."""

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
BRIEF = (
    'Starter activation cinematic: Tony cranks a heavy water weapon then it trembles with trapped pressure. '
    'Short mechanical crank and escalating hardware chatter from retained CC0 metal/water recordings. '
    'Do not sound the full discharge until gameplay handoff. Sean reuses approved suction/strain/break cues. '
    'No dialogue or new damage timing.'
)


def main() -> None:
    """Append versioned missing cues and source evidence without changing runtime mappings."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this delivery')
    metal = H.load('metal', .85, 300, 6500)
    heavy = H.load('heavy', .8, 140, 5000)
    water = H.load('water', .8, 500, 3800)
    crank = H.mix(1.2, [
        (at, H.cut(metal, .09, offset=(index % 3) * .025), gain)
        for index, (at, gain) in enumerate([
            (0, .5), (.14, .3), (.27, .6), (.41, .35), (.55, .65),
            (.68, .4), (.81, .7), (.94, .4), (1.07, .7)])] + [(0, H.cut(heavy, .16), .3)])
    pressure = H.mix(1, [(0, H.cut(water, 1), .45)] + [
        (at, H.cut(metal, .06, offset=(index % 3) * .02), .12 + index * .035)
        for index, at in enumerate([0, .18, .34, .48, .60, .70, .79, .87, .94])])
    for index in range(len(pressure)):
        pressure[index] *= .25 + .75 * index / len(pressure)
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    outputs = []
    for index, (name, values, duration, gain) in enumerate([
        ('tony-crank', crank, 1.2, -5), ('tony-pressure', pressure, 1.0, -5)]):
        fade = round(.045 * H.RATE)
        for sample in range(fade):
            values[-sample - 1] *= sample / fade
        identity = f'DD-S{number + index:04d}'
        candidate = identity + '.1'
        evidence = H.write(ROOT / 'audio/alternatives' / identity / f'{candidate}.wav', H.normalize(values, -14))
        registry['sounds'].append({
            'id': identity, 'uuid': str(uuid.uuid4()), 'key': f'proposed-starter-cinematic/{name}',
            'section': 'Weapon sounds', 'group': 'Starter activation cinematics', 'name': name,
            'status': 'proposed', 'paths': [], 'source': MANIFEST,
            'alternatives': [{'id': candidate, 'path': evidence['path'],
                              'name': f'Cinematic {name} · {duration:.2f}s', 'source_manifest': MANIFEST,
                              'generation_prompt': BRIEF, 'provenance': 'Retained Kenney/rubberduck CC0 recordings.'}]})
        outputs.append({'id': candidate, 'cue': name, 'gain_db': gain, 'loop': False, **evidence})
    sources = {}
    for name in ['metal', 'heavy', 'water']:
        path, source_manifest, author, license_name = H.SOURCES[name]
        sources[name] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                         'source_manifest': source_manifest, 'author': author, 'license': license_name}
    manifest = {'date': '2026-11-05', 'status': 'Audio assets ready; action contract confirmation pending',
                'brief': BRIEF, 'sources': sources, 'processing': H.PROCESSING, 'outputs': outputs,
                'recipe': str(Path(__file__).relative_to(ROOT)), 'runtime_owner': 'Engineering',
                'package_owner': 'Art', 'listening': 'Technical validation only; subjective mix pending.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['cue'], o['id']) for o in outputs])


if __name__ == '__main__':
    main()
