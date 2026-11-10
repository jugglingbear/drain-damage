#!/usr/bin/env python3
"""Audition recorded creature/chitin hybrids for the rat and alligator-shaped Skitterling phases."""

import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'audio_helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
HELPERS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPERS)
BRIEF = (
    'Higher-quality Skitterling phase voice auditions. A crawling cockroach swarm forms a rat, then an alligator: '
    'retain disgusting insect clicks/chitter and add nervous rat-like squeals or throaty alligator-like growls/hisses '
    'respectively. Three choices each, brief readable gestures, recorded-source texture rather than chiptune. '
    'Fictional hybrids, not claims of real rat/alligator field recordings. No runtime changes before selection.'
)


def main() -> None:
    """Append six signature calls to permanent phase-assembly slots, preserving runtime and earlier auditions."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this version')
    names = ['bug_01', 'bug_02', 'bug_03', 'cute_04', 'cute_07', 'weird_02',
             'breath', 'monster_06', 'troll_02', 'burble_02', 'eat_01', 'spit_02']
    for name in names:
        HELPERS.SOURCES[name] = (
            f'audio/sources/recorded-creatures-cc0-v1/rubberduck/{name}.ogg',
            'audio/sources/recorded-creatures-cc0-v1/manifest.json', 'rubberduck', 'CC0-1.0')
    load, cut, mix, norm = HELPERS.load, HELPERS.cut, HELPERS.mix, HELPERS.normalize
    # More spectral room for chitin in the rat, lower throat weight beneath the alligator's same insect body.
    chitin = load('bug_01', 1.13, 600, 8500)
    scratch = load('eat_01', 1.1, 1000, 9000)
    hiss = load('breath', .9, 700, 7500)
    rat_a = load('cute_04', 1.24, 420, 7800)
    rat_b = load('weird_02', 1.35, 550, 8500)
    rat_c = load('cute_07', 1.12, 350, 7000)
    bug_b = load('bug_02', 1.23, 700, 8500)
    bug_c = load('bug_03', 1.1, 500, 8000)
    gator_a = load('monster_06', .65, 80, 4800)
    gator_b = load('troll_02', .76, 100, 5500)
    gator_c = load('burble_02', .68, 90, 4500)
    spit = load('spit_02', .82, 220, 6000)
    ticks = mix(.85, [(0, cut(scratch, .055), .3), (.12, cut(chitin, .11), .4),
                       (.29, cut(scratch, .08, .12), .35), (.52, cut(chitin, .13, .18), .3),
                       (.72, cut(scratch, .07, .23), .2)])
    choices = [
        ('rat_assembly', 'R1 — Needle squeal and scuttle', .95,
         [(0, ticks, .7), (.08, cut(rat_a, .56), .85), (.5, cut(bug_b, .32, .1), .45)]),
        ('rat_assembly', 'R2 — Chattering sewer rat', 1.1,
         [(0, ticks, .8), (.045, cut(rat_b, .3), .75), (.37, cut(rat_b, .24, .25), .55),
          (.56, cut(bug_c, .43), .7), (.8, cut(hiss, .25), .15)]),
        ('rat_assembly', 'R3 — Wet gnashing squeak', 1.15,
         [(0, cut(spit, .15), .35), (.04, ticks, .65), (.1, cut(rat_c, .6), .85),
          (.61, cut(bug_b, .4), .6), (.92, cut(scratch, .14, .1), .3)]),
        ('alligator_assembly', 'G1 — Chitin-backed throat growl', 1.3,
         [(0, ticks, .55), (.04, cut(gator_a, 1.1), .85), (.5, cut(bug_c, .55), .4),
          (.96, cut(hiss, .3), .15)]),
        ('alligator_assembly', 'G2 — Jaw rasp and warning hiss', 1.2,
         [(0, cut(scratch, .12), .45), (.035, cut(gator_b, .65), .8), (.16, ticks, .5),
          (.58, cut(hiss, .58), .65), (.86, cut(bug_b, .25), .3)]),
        ('alligator_assembly', 'G3 — Wet belly rumble', 1.35,
         [(0, cut(gator_c, .96), .9), (.07, ticks, .65), (.38, cut(gator_a, .65, .25), .5),
          (.88, cut(spit, .29), .4), (1.08, cut(hiss, .23), .15)]),
    ]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    outputs = []
    for event, name, duration, parts in choices:
        record = next(r for r in registry['sounds'] if r['key'] == 'skitterling/' + event)
        suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
        identity = f"{record['id']}.{suffix}"
        values = norm(mix(duration, parts), -10)
        path = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
        evidence = HELPERS.write(path, values)
        record['alternatives'].append({'id': identity, 'path': evidence['path'],
            'name': f'RECORDED HYBRID · {name} · {duration:.2f}s', 'source_manifest': MANIFEST,
            'generation_prompt': BRIEF,
            'provenance': 'rubberduck CC0 creature recordings; fictional rat/gator-like insect hybrids.'})
        outputs.append({'id': identity, 'event': event, 'name': name, **evidence})
    sources = {}
    for name in {p['source'] for p in HELPERS.PROCESSING}:
        path, evidence, author, license_name = HELPERS.SOURCES[name]
        sources[name] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                         'author': author, 'license': license_name, 'license_evidence': evidence}
    manifest = {'date': '2026-11-05', 'status': 'Six auditions ready; awaiting phase direction selections',
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
                'helper_recipe': 'audio/sources/starter-specials-auditions-v1/generate.py',
                'sources': sources, 'processing': HELPERS.PROCESSING, 'outputs': outputs,
                'integration_notes': [
                    'Rat and alligator assembly slots hold signature-call auditions; no runtime mapping changed.',
                    'All calls fit under the present 1.4s assembly cutoff; future warning edits follow selection.',
                    'The shared insect texture preserves the cockroach-swarm identity across both forms.',
                    'No automatic ambient repetition; existing beds and attack-warning timing remain unchanged.',
                    'Peak-matched at -10dBFS for comparison; subjective character and music mix need listening.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['name']) for o in outputs])


if __name__ == '__main__':
    main()
