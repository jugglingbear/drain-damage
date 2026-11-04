#!/usr/bin/env python3
"""Create brief devil-spider event candidates while preserving all earlier auditions."""

import hashlib
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
# Cuts retain discrete gestures rather than accelerating an entire multi-action demonstration.
CUTS = [
    ('crawl', .0, .09, -20, 'Single claw tick'),
    ('launch', .08, .22, -9, 'Web spit'),
    ('attach', .0, .12, -12, 'Sticky catch'),
    ('haul', .0, .24, -16, 'One strained silk tug'),
    ('escape', .0, .28, -11, 'Escape snap'),
    ('hit', .0, .16, -13, 'Brief hurt'),
    ('death', .0, .48, -12, 'Death rasp'),
]
FAMILIES = ['A — Chitin', 'B — Wet brood', 'C — Breath stalker', 'D — Black maw']
BRIEF = (
    'Short distinctive devil-spider cues that leave room for music and other monsters: one walking tick, '
    'web shot, catch, individual silk tug, occasional hungry vocal while hauling, escape, hit and death. '
    'No continuous creature bed. Draft selection only; no gameplay hookup.'
)


def main() -> None:
    """Render four short families and append permanent candidate IDs."""
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    records = {r['key'].split('/')[-1]: r for r in registry['sounds']
               if r['key'].startswith('proposed-devil-spider/')}
    if 'hunger' in records:
        raise ValueError('Already generated; preserve originals and use a new version.')
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    hunger = {'key': 'proposed-devil-spider/hunger', 'id': f'DD-S{number:04d}', 'uuid': str(uuid.uuid4()),
              'section': 'Level 1', 'group': 'Devil spider drafts — NOT IN GAME',
              'name': 'Short hungry vocal while reeling', 'paths': [], 'source': MANIFEST,
              'status': 'proposed', 'alternatives': []}
    records['hunger'] = hunger
    registry['sounds'].append(hunger)
    outputs = []
    for event, start, duration, peak in [*[(e, s, d, p) for e, s, d, p, _ in CUTS], ('hunger', 0, .38, -14)]:
        record = records[event]
        next_suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
        for family, name in enumerate(FAMILIES):
            # Hunger uses the vocal onset of the matching original aim; it is a new action slot.
            source_record = records['aim'] if event == 'hunger' else record
            source = ROOT / source_record['alternatives'][family]['path']
            identity = f"{record['id']}.{next_suffix + family}"
            path = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
            path.parent.mkdir(parents=True, exist_ok=True)
            filters = (f'atrim=start={start}:duration={duration},asetpts=N/SR/TB,'
                       f'afade=t=in:d=0.004,afade=t=out:st={duration - .025}:d=0.025')
            # Measure the faded excerpt so source loudness does not bias the family comparison.
            measure = subprocess.run(['ffmpeg', '-v', 'info', '-i', str(source), '-af',
                                      filters + ',volumedetect', '-f', 'null', '-'],
                                     capture_output=True, text=True, check=True).stderr
            measured = float(measure.split('max_volume: ')[-1].split(' dB')[0])
            filters += f',volume={peak - measured}dB'
            command = ['ffmpeg', '-v', 'error', '-n', '-i', str(source), '-af', filters,
                       '-ar', '44100', '-ac', '1', '-c:a', 'pcm_s16le', str(path)]
            subprocess.run(command, check=True)
            label = 'Hungry mouth rasp' if event == 'hunger' else next(c[4] for c in CUTS if c[0] == event)
            candidate = {'id': identity, 'path': str(path.relative_to(ROOT)),
                         'name': f'SHORT v2 · {name} · {label} · {duration:.2f}s',
                         'source_manifest': MANIFEST, 'license': 'CC0-1.0', 'generation_prompt': BRIEF,
                         'provenance': 'Brief edits of retained rubberduck CC0 mouth/creature recordings; '
                                       'designed claw/silk textures, not actual spider recordings.'}
            record['alternatives'].append(candidate)
            outputs.append({**candidate, 'source': str(source.relative_to(ROOT)),
                            'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                            'duration_seconds': duration, 'target_peak_dbfs': peak, 'filters': filters})
    manifest = {'date': '2026-11-03', 'status': 'Short audition candidates; selection and integration pending',
                'brief': BRIEF, 'license': 'CC0-1.0',
                'original_provenance': 'audio/sources/recorded-creatures-cc0-v1/manifest.json',
                'parent_recipe': 'audio/sources/devil-spider-auditions-v1/manifest.json',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'outputs': outputs,
                'mix_proposal': {
                    'walk': 'Quiet selected footfalls only; do not sound every leg or every visible spider.',
                    'launch': 'Prioritize the short attack transient over movement.',
                    'haul': 'One cue per visible pull; stop instantly when hauling ends; no continuous loop.',
                    'hunger': 'Occasional vocal on the spider holding the hero, not every pull or all spiders.',
                    'voice_budget': 'Propose two shared spider voices, with capture/escape priority over walk/hunger.',
                    'omit_by_default': 'No ambient cocoon bed or repeated struggle vocals in the busy mix.',
                    'status': 'Recommendations only; cooldowns, priorities and mix require gameplay validation.'}}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(f'Created {len(outputs)} short candidates; hunger slot {hunger["id"]}')


if __name__ == '__main__':
    main()
