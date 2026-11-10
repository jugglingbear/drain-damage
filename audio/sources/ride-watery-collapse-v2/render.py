#!/usr/bin/env python3
"""Create four water-led track-collapse alternatives without changing the game mapping."""

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
    'Level 2 track opening fractures into a deep water-filled gap: stronger watery intense break/collapse/destruction. '
    'Four distinct short samples, dominated by water displacement and turbulent falling water with structural failure '
    'underneath. No hero scream, music, fireball or long ambience. Preserve previous candidates and runtime mapping.'
)


def main() -> None:
    """Register versioned auditions with exact source and mixing recipes."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this delivery; revisions need new paths.')
    base = 'audio/sources/ride-human-fall-and-smash-v1/sfx_breaking_and_falling/'
    for key, filename in [('fracture', 'bfh1_rock_breaking_02.ogg'), ('rubble', 'bfh1_rock_falling_01.ogg'),
                          ('thump', 'bfh1_rock_hit_01.ogg')]:
        HELPERS.SOURCES[key] = (base + filename, 'audio/sources/ride-human-fall-and-smash-v1/manifest.json',
                               'rubberduck', 'CC0-1.0')
    HELPERS.SOURCES['torrent'] = ('assets/audio/sfx/starter-specials-v1/tony-core.wav',
                                 'audio/sources/starter-specials-torrent-v2/manifest.json',
                                 'rubberduck / Drain Damage', 'CC0 recording + original filtered turbulence')
    load, cut, mix, norm = HELPERS.load, HELPERS.cut, HELPERS.mix, HELPERS.normalize
    splash = load('splash', .82, 90, 7000)
    splash2 = load('splash2', .94, 100, 8500)
    water = load('water', .78, 70, 5500)
    torrent = load('torrent', .85, 80, 6500)
    fracture = load('fracture', .82, 120, 4500)
    rubble = load('rubble', .9, 150, 5000)
    thump = load('thump', .67, 60, 1900)
    # Every source is peak-normalized on decode. Water carries the foreground; rubble stays subordinate.
    candidates = [
        ('A — Floodgate rupture', 1.15, [
            (0, cut(fracture, .24), .35), (.015, cut(splash, .5), 1),
            (.08, cut(torrent, .95), .55), (.46, cut(splash2, .43), .6),
            (.62, cut(rubble, .38), .15)]),
        ('B — Heavy plunge', 1.45, [
            (0, cut(thump, .28), .45), (.035, cut(splash2, .58), 1),
            (.15, cut(water, 1.12), .7), (.22, cut(torrent, .85), .35),
            (.72, cut(splash, .5), .55), (.94, cut(rubble, .3), .12)]),
        ('C — Cascading washout', 1.3, [
            (0, cut(fracture, .18), .3), (.015, cut(splash2, .32), .9),
            (.21, cut(splash, .38, .13), 1), (.49, cut(splash2, .4, .2), .75),
            (.07, cut(torrent, 1.05), .38), (.58, cut(rubble, .37), .23),
            (.85, cut(water, .36, .2), .4)]),
        ('D — Violent channel collapse', 1.65, [
            (0, cut(fracture, .28), .48), (.02, cut(thump, .25), .28),
            (.035, cut(splash, .6), 1), (.11, cut(torrent, 1.4), .65),
            (.46, cut(splash2, .5), .75), (.8, cut(rubble, .42), .2),
            (1.07, cut(splash, .43, .15), .45)]),
    ]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    record = next(r for r in registry['sounds'] if r['key'] == 'level-two-ride/track_smash')
    suffix = max(int(a['id'].split('.')[-1]) for a in record['alternatives']) + 1
    outputs = []
    for index, (name, duration, parts) in enumerate(candidates):
        identity = f"{record['id']}.{suffix + index}"
        values = norm(mix(duration, parts), -6)
        path = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
        evidence = HELPERS.write(path, values)
        record['alternatives'].append({'id': identity, 'path': evidence['path'],
            'name': f'WATERY v2 · {name} · {duration:.2f}s', 'generation_prompt': BRIEF,
            'source_manifest': MANIFEST,
            'provenance': 'CC0 rubberduck water/splash/rock recordings plus original torrent turbulence.'})
        outputs.append({'id': identity, 'name': name, **evidence})
    sources = {}
    for key in {p['source'] for p in HELPERS.PROCESSING}:
        path, evidence, author, license_name = HELPERS.SOURCES[key]
        sources[key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                        'source_manifest': evidence, 'author': author, 'license': license_name}
    manifest = {'date': '2026-11-05', 'status': 'Awaiting Sean selection; current track-smash runtime unchanged',
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
                'helper_recipe': 'audio/sources/starter-specials-auditions-v1/generate.py',
                'sources': sources, 'processing': HELPERS.PROCESSING, 'outputs': outputs,
                'mix': 'All samples peak -6dBFS for comparison; final runtime gain must be set under music.',
                'trigger': 'One cue at visible track fracture; independent of contact, separate from hero fall scream.',
                'validation_limit': 'Technical audio validation; subjective fit and in-game mix require listening.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['name']) for o in outputs])


if __name__ == '__main__':
    main()
