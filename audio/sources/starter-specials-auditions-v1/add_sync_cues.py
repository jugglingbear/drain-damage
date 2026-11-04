#!/usr/bin/env python3
"""Add Art's recoil/hinge landmarks and an independently sustained Main Break jet."""

import array
import hashlib
import json
import uuid
import wave

from generate import BRIEF, FAMILIES, HERE, MANIFEST, PROCESSING, ROOT, SOURCES, cut, load, mix, normalize, write


def read(path: str) -> list[float]:
    """Read an existing generated mono PCM candidate."""
    with wave.open(str(ROOT / path)) as source:
        return [v / 32767 for v in array.array('h', source.readframes(source.getnframes()))]


def main() -> None:
    """Append separate sync cues and preserve first-render previews before revision."""
    manifest = json.loads((HERE / 'manifest.json').read_text())
    registry = json.loads((ROOT / 'audio/sound-registry.json').read_text())
    records = {r['key'].split('/')[-1]: r for r in registry['sounds']
               if r['key'].startswith('proposed-starter-specials/')}
    if 'tony-recoil' in records:
        raise ValueError('Already registered')
    for key, member in [('scrape', 'wooded_box_open.ogg'), ('step', 'wooden_01.ogg')]:
        path = str((HERE / 'originals' / member).relative_to(ROOT))
        SOURCES[key] = (path, 'audio/sources/player-death-flush-v1/manifest.json', 'rubberduck', 'CC0-1.0')
        manifest['sources'][key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                                    'license_evidence': SOURCES[key][1], 'author': 'rubberduck', 'license': 'CC0-1.0',
                                    'note': 'Wood handling/impact designed as foot contact; not recorded feet.'}
        manifest['extracted_originals']['members'].append(member)
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    slots = [('tony-recoil', 'Tony Hydrojet Overdrive', 'Idle recoil — foot scrape'),
             ('tony-step', 'Tony Hydrojet Overdrive', 'Braced step — brief foot contact'),
             ('sean-hinge', 'Sean Main Break', 'Base hinge / metal strain'),
             ('sean-core', 'Sean Main Break', 'Following jet — loop-ready sustain')]
    for index, (event, group, name) in enumerate(slots):
        records[event] = {'id': f'DD-S{number + index:04d}', 'key': f'proposed-starter-specials/{event}',
                          'uuid': str(uuid.uuid4()), 'section': 'Weapon sounds',
                          'group': group + ' drafts — NOT IN GAME',
                          'name': name, 'paths': [], 'source': MANIFEST, 'status': 'proposed', 'alternatives': []}
        registry['sounds'].append(records[event])
    for family, (name, speed, high, low, _, _) in enumerate(FAMILIES, 1):
        scrape = load('scrape', speed, 300, min(low, 4000))
        step = load('step', speed, 100, 2400)
        metal = load('heavy', speed, 100, 2800)
        water = load('water', speed, high, low)
        core = read(records['tony-core']['alternatives'][family - 1]['path'])
        clips = {'tony-recoil': normalize(cut(scrape, .25), -23),
                 'tony-step': normalize(cut(step, .09), -24),
                 'sean-hinge': normalize(cut(metal, .26, reverse=True), -20),
                 'sean-core': normalize(core, -19)}
        for event, clip in clips.items():
            record = records[event]
            identity = f"{record['id']}.{family}"
            evidence = write(ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav', clip)
            record['alternatives'].append({'id': identity, 'path': evidence['path'],
                                           'name': f'{name} · {evidence["duration_seconds"]:.2f}s',
                                           'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                                           'provenance': 'Retained CC0 water, wood handling and metal recordings.'})
            manifest['outputs'].append({'id': identity, 'event': event, 'family': name,
                                        'loop': event == 'sean-core', **evidence})
        # Separate the water-follow gesture from the hinge strain for independent animation sync.
        replacement_tip = normalize(cut(water, .3, reverse=True), -17)
        seal = read(records['sean-seal']['alternatives'][family - 1]['path'])
        pull = read(records['sean-pull']['alternatives'][family - 1]['path'])
        release = read(records['sean-break']['alternatives'][family - 1]['path'])
        erupt = read(records['sean-erupt']['alternatives'][family - 1]['path'])
        stop = read(records['sean-stop']['alternatives'][family - 1]['path'])
        sustained = cut(clips['sean-core'], 1.2)
        preview = mix(2.5, [(0, seal, 1), (.3, pull, 1), (.72, release, 1), (.82, erupt, 1),
                            (1.05, sustained, 1), (1.5, clips['sean-hinge'], 1),
                            (1.5, replacement_tip, .5), (1.85, stop, 1)])
        for event, values in [('sean-tip', replacement_tip), ('sean-preview', preview)]:
            candidate = records[event]['alternatives'][family - 1]
            previous = candidate['path']
            target = (ROOT / previous).with_name(candidate['id'] + '-v2.wav')
            evidence = write(target, values)
            candidate['path'] = evidence['path']
            output = next(o for o in manifest['outputs'] if o['id'] == candidate['id'])
            output['preserved_first_render'] = {'path': previous, 'sha256': output['sha256']}
            output.update(evidence)
    manifest['processing'].extend(PROCESSING)
    manifest['sync_recipe'] = str((HERE / 'add_sync_cues.py').relative_to(ROOT))
    manifest['art_sync_notes'] = [
        'Tony idle recoil scrape differs from braced stepping; neither restarts the pressure loop.',
        'Tony direction reversal preserves pressure; no aim/reversal cue is added.',
        'Sean hinge strain is separate from initial pipe release and from the water-follow tip gesture.',
        'Sean following jet can sustain through arbitrary tilt duration, then crossfade into irregular decay.',
        'Preview uses one finite core pass; durations remain illustrative, not approved mechanics.']
    manifest['illustrative_timelines']['sean'] = [
        ['sean-seal', 0], ['sean-pull', .3], ['sean-break', .72], ['sean-erupt', .82],
        ['sean-core', 1.05], ['sean-hinge', 1.5], ['sean-tip', 1.5], ['sean-stop', 1.85]]
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (ROOT / 'audio/sound-registry.json').write_text(json.dumps(registry, indent=2) + '\n')
    print('Added 12 sync candidates; revised tip and Sean preview retain originals.')


if __name__ == '__main__':
    main()
