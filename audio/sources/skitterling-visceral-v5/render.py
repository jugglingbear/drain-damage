#!/usr/bin/env python3
"""Replace the rejected cute audition direction with layered harsh recorded growls and wet insect textures."""

import hashlib
import importlib.util
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'audio_helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
HELPERS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPERS)
BRIEF = (
    'Previous Skitterling hybrids rejected as cute and harmless. Dangerous, gross, visceral cockroach-swarm '
    'rat/alligator forms: strained snarls, grinding mouth sounds, wet clicks and harsh insect rasp. '
    'Rat is frantic and vicious; alligator is heavy, guttural and threatening. No cute squeaks, barks, '
    'musical chirps or comic burps. Layer recorded growls and mouth textures; no new runtime mapping.'
)


def grit(values: list[float]) -> list[float]:
    """Add controlled dense rasp without digital clipping or a synthetic pitch oscillator."""
    return [math.tanh(v * 1.8) / math.tanh(1.8) for v in values]


def main() -> None:
    """Append six harsher candidates and mark the earlier direction rejected, preserving all files."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this delivery')
    for name in ['roar_01', 'roar_03', 'monster_04', 'monster_07', 'bug_02', 'eat_02', 'eat_04', 'spit_03', 'breath']:
        HELPERS.SOURCES[name] = (
            f'audio/sources/recorded-creatures-cc0-v1/rubberduck/{name}.ogg',
            'audio/sources/recorded-creatures-cc0-v1/manifest.json', 'rubberduck', 'CC0-1.0')
    for number in [3, 13]:
        HELPERS.SOURCES[f'growl{number}'] = (
            f'audio/sources/recorded-creatures-cc0-v1/starninjas/monster.{number}.ogg',
            'audio/sources/recorded-creatures-cc0-v1/manifest.json', 'StarNinjas', 'CC0-1.0')
    load, cut, mix, norm = HELPERS.load, HELPERS.cut, HELPERS.mix, HELPERS.normalize
    snarl = grit(load('growl3', .94, 170, 7500))
    rasp = grit(load('monster_04', .87, 220, 7000))
    shriek = grit(load('roar_03', 1.02, 280, 8200))
    throat = grit(load('growl13', .62, 65, 4700))
    roar = grit(load('roar_01', .67, 75, 5500))
    jaw = grit(load('monster_07', .72, 90, 5000))
    insect = load('bug_02', .84, 850, 9000)
    teeth = load('eat_02', .9, 900, 8500)
    wet = load('eat_04', .75, 200, 6000)
    spit = load('spit_03', .8, 170, 6500)
    hiss = load('breath', .74, 1100, 8500)
    chatter = mix(1.1, [(t, cut(teeth, .07, i * .055), g) for i, (t, g) in enumerate([
        (0, .7), (.075, .55), (.2, .9), (.29, .65), (.43, .8), (.62, .7), (.8, .45), (.95, .3)])])
    choices = [
        ('rat_assembly', 'R4 — Feral swarm snarl', 1.15,
         [(0, chatter, .55), (.02, cut(snarl, .95), 1), (.13, cut(insect, .72), .55),
          (.58, cut(wet, .42), .4)]),
        ('rat_assembly', 'R5 — Wet teeth and throat rasp', 1.25,
         [(0, cut(spit, .17), .5), (.025, cut(rasp, 1.08), 1), (.06, chatter, .65),
          (.5, cut(snarl, .57, .25), .5), (.87, cut(wet, .31), .4)]),
        ('rat_assembly', 'R6 — Lunging insect shriek', 1.1,
         [(0, cut(insect, .2), .7), (.025, cut(shriek, .87), .9), (.03, chatter, .55),
          (.15, cut(rasp, .72), .55), (.78, cut(spit, .25), .3)]),
        ('alligator_assembly', 'G4 — Choking jaw growl', 1.35,
         [(0, cut(wet, .3), .45), (.02, cut(throat, 1.22), 1), (.07, chatter, .45),
          (.22, cut(insect, .83), .5), (.83, cut(jaw, .43), .6)]),
        ('alligator_assembly', 'G5 — Wet bellow and mandibles', 1.4,
         [(0, cut(spit, .2), .45), (.025, cut(roar, 1.25), 1), (.08, chatter, .5),
          (.24, cut(throat, .85), .55), (.82, cut(wet, .46), .5)]),
        ('alligator_assembly', 'G6 — Grinding jaws and hostile hiss', 1.3,
         [(0, chatter, .65), (.015, cut(jaw, 1.12), 1), (.2, cut(insect, .78), .55),
          (.58, cut(hiss, .67), .75), (.96, cut(wet, .25), .35)]),
    ]
    p = ROOT / 'audio/sound-registry.json'
    registry = json.loads(p.read_text())
    outputs = []
    for event, name, duration, layers in choices:
        record = next(r for r in registry['sounds'] if r['key'] == 'skitterling/' + event)
        for candidate in record['alternatives']:
            if candidate.get('source_manifest') == 'audio/sources/skitterling-recorded-phases-v4/manifest.json':
                candidate['review_status'] = 'Rejected by Sean: too cute/harmless'
                if not candidate['name'].startswith('REJECTED'):
                    candidate['name'] = 'REJECTED — ' + candidate['name']
        suffix = max(int(a['id'].split('.')[-1]) for a in record['alternatives']) + 1
        identity = f"{record['id']}.{suffix}"
        values = norm(mix(duration, layers), -9)
        path = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
        evidence = HELPERS.write(path, values)
        record['alternatives'].append({'id': identity, 'path': evidence['path'],
            'name': f'VISCERAL v5 · {name} · {duration:.2f}s', 'source_manifest': MANIFEST,
            'generation_prompt': BRIEF, 'provenance': 'CC0 StarNinjas and rubberduck recorded growls/mouth textures.'})
        outputs.append({'id': identity, 'name': name, 'event': event, **evidence})
    sources = {}
    for key in {r['source'] for r in HELPERS.PROCESSING}:
        path, evidence, author, license_name = HELPERS.SOURCES[key]
        sources[key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                        'license_evidence': evidence, 'author': author, 'license': license_name}
    manifest = {'date': '2026-11-05', 'status': 'Revised after cute/harmless rejection; awaiting listening selection',
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
                'helper_recipe': 'audio/sources/starter-specials-auditions-v1/generate.py',
                'sources': sources, 'processing': HELPERS.PROCESSING, 'outputs': outputs,
                'notes': ['No sources tagged cute are used. Growls, wet mouth textures and chitin transients dominate.',
                          'Fictional hybrids from performed recordings, not literal animal field recordings.',
                          'All calls at or below current 1.4s assembly cutoff; no runtime or warning timing changes.',
                          'Technical checks do not establish subjective danger/grossness; Sean listening pending.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    p.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['name']) for o in outputs])


if __name__ == '__main__':
    main()
