#!/usr/bin/env python3
"""Render bounded environmental hit/break sets from retained CC0 metal and water."""

import hashlib
import importlib.util
import json
import math
import random
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'special_audio_helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
HELPERS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPERS)
RATE = HELPERS.RATE
BRIEF = (
    'Harmless basement environmental props: water-heater metal split, water gush and settling; '
    'cast-iron boiler heavy collapse and steam; pressure-tank seam pop, crumple and water. '
    'Short nonlethal hit cues. Target 0.8s destruction animation with visual debris allowed to linger silently. '
    'No monster screams, explosive fireball sounds or implications of hero damage.'
)


def hiss(seconds: float, seed: int) -> list[float]:
    """Create a finite steam/pressure release with filtered noise and no tonal alarm."""
    rng = random.Random(seed)
    count = round(seconds * RATE)
    low = 0.0
    result = []
    for i in range(count):
        noise = rng.uniform(-1, 1)
        low += .15 * (noise - low)
        value = (noise - low) * math.exp(-i / RATE * 4)
        value *= min(1, i / 350, (count - 1 - i) / 1400)
        result.append(value)
    return result


def main() -> None:
    """Append permanent proposed event slots and preserve identical runtime/audition bytes."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve originals; revisions require new version paths.')
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    metal_root = 'audio/sources/ride-human-fall-and-smash-v1/sfx_breaking_and_falling/'
    for key, filename in [('fall', 'bfh1_metal_falling_02.ogg'), ('iron', 'bfh1_metal_hit_04.ogg')]:
        HELPERS.SOURCES[key] = (metal_root + filename, 'audio/sources/ride-human-fall-and-smash-v1/manifest.json',
                               'rubberduck', 'CC0-1.0')
    load, cut, mix, norm = HELPERS.load, HELPERS.cut, HELPERS.mix, HELPERS.normalize
    sheet = load('metal', .85, 100, 6000)
    fall = load('fall', .85, 100, 5000)
    iron = load('iron', .65, 60, 2800)
    heavy = load('heavy', .67, 65, 3000)
    splash = load('splash', .9, 100, 6500)
    water = load('water', .95, 130, 5000)
    sets = {
        'water-heater': {
            'hit': norm(cut(sheet, .12), -17),
            'split': norm(mix(.27, [(0, cut(sheet, .16), .8), (.05, cut(fall, .22), .6)]), -10),
            'gush': norm(mix(.52, [(0, cut(splash, .35), .8), (.1, cut(water, .42), .6)]), -15),
            'settle': norm(mix(.2, [(0, cut(sheet, .08, .08), .5), (.1, cut(fall, .1, .2), .25)]), -21),
        },
        'cast-iron-boiler': {
            'hit': norm(cut(iron, .18), -16),
            'collapse': norm(mix(.4, [(0, cut(heavy, .3), 1), (.12, cut(iron, .28), .6)]), -10),
            'steam': norm(hiss(.5, 114201), -19),
            'settle': norm(cut(iron, .22, .12), -23),
        },
        'pressure-tank': {
            'hit': norm(cut(sheet, .1, .03), -18),
            'seam-pop': norm(mix(.16, [(0, cut(sheet, .09), .8), (.03, hiss(.13, 114202), .2)]), -11),
            'crumple': norm(cut(fall, .31, .09), -15),
            'water': norm(mix(.45, [(0, cut(splash, .23), .6), (.08, cut(water, .37), .45)]), -17),
        },
    }
    timelines = {
        'water-heater': [('split', 0), ('gush', .12), ('settle', .6)],
        'cast-iron-boiler': [('collapse', 0), ('steam', .15), ('settle', .58)],
        'pressure-tank': [('seam-pop', 0), ('crumple', .09), ('water', .3)],
    }
    outputs = []
    for prop, clips in sets.items():
        clips['break'] = norm(mix(.8, [(at, clips[event], 1) for event, at in timelines[prop]]), -9)
        # Show the combined destruction first, then clean sync components and the nonlethal hit.
        for event in ['break', *[e for e in clips if e != 'break']]:
            slot = f'DD-S{number:04d}'
            number += 1
            identity = slot + '.1'
            runtime = ROOT / 'assets/audio/sfx/basement-platforms-v1' / f'{prop}-{event}.wav'
            evidence = HELPERS.write(runtime, clips[event])
            audition = ROOT / 'audio/alternatives' / slot / f'{identity}.wav'
            if audition.exists():
                raise FileExistsError(audition)
            audition.parent.mkdir(parents=True, exist_ok=True)
            audition.write_bytes(runtime.read_bytes())
            label = ('Combined destruction — use this OR isolated stages'
                     if event == 'break' else event.replace('-', ' '))
            registry['sounds'].append({
                'key': f'proposed-basement-props/{prop}/{event}', 'id': slot, 'uuid': str(uuid.uuid4()),
                'section': 'Level 1', 'group': prop.replace('-', ' ').title() + ' — environmental audio',
                'name': label, 'paths': [], 'source': MANIFEST, 'status': 'proposed',
                'alternatives': [{'id': identity, 'path': str(audition.relative_to(ROOT)),
                                  'name': f'{label} · {evidence["duration_seconds"]:.2f}s',
                                  'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                                  'provenance': 'CC0 water/metal recordings and original steam hiss.'}]})
            outputs.append({'id': identity, 'prop': prop, 'event': event, 'loop': False,
                            'suggested_gain_db': -3 if event == 'break' else -2,
                            'audition': str(audition.relative_to(ROOT)), **evidence})
    used = {p['source'] for p in HELPERS.PROCESSING}
    sources = {}
    for key in used:
        path, evidence, author, license_name = HELPERS.SOURCES[key]
        sources[key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                        'license_evidence': evidence, 'author': author, 'license': license_name}
    manifest = {
        'date': '2026-11-04', 'status': 'Delivered for environmental prop integration; no runtime mapping yet',
        'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
        'helper_recipe': 'audio/sources/starter-specials-auditions-v1/generate.py',
        'sources': sources, 'processing': HELPERS.PROCESSING, 'timelines_seconds': timelines, 'outputs': outputs,
        'trigger_guidance': [
            'Use combined break once on intact-to-destroyed transition OR schedule components; never both.',
            'Nonlethal accepted damage plays hit only; lethal damage plays break only, not hit plus break.',
            'Suggested hit cooldown 0.12s; bounded shared environmental voices with pause/mute/reset disposal.',
            'No loop, no lingering debris chatter. Death/break and water are harmless to the hero.',
            '0.8s timing fits a 0.6–1.0s collapse; adapt animation event offsets without stretching all clips.'],
        'limitations': 'Technical checks only; final in-game listening/mix and runtime implementation are pending.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['prop'], o['event']) for o in outputs])


if __name__ == '__main__':
    main()
