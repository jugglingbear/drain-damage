#!/usr/bin/env python3
"""Fit approved Skitterling voices to Level Design's action windows, preserving pitch and all originals."""

import hashlib
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    'Sean approved rat DD-S0016.7–9 and alligator DD-S0024.10–12; consult Level Design and synchronize all moves. '
    'Short fades must end warnings before takeoff/charge/sweep; no screech through flight or recovery. '
    'Formation may span assembly plus harmless ready phase. No gameplay timing changes.'
)
SPECS = [
    ('rat_rush_warning', 'DD-S0016.8', 0, .74, .006, 8000, -4),
    ('rat_pounce_warning', 'DD-S0016.9', 0, .92, .006, 8000, -4),
    ('alligator_assembly', 'DD-S0024.11', 0, 1.85, .008, 8000, -4),
    ('alligator_jaw_warning', 'DD-S0024.10', 0, .82, .006, 8000, -4),
    ('alligator_tail_warning', 'DD-S0024.12', 0, .90, .006, 8000, -4),
    ('tail_warning', 'DD-S0024.11', .1, .72, .006, 8000, -4),
    ('surface_warning', 'DD-S0024.10', .4, .90, .13, 1400, -3),
]


def main() -> None:
    """Append sync-ready cues under their event identities and produce an Engineering contract."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this delivery')
    p = ROOT / 'audio/sound-registry.json'
    registry = json.loads(p.read_text())
    next_slot = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    outputs = []
    for event, parent, offset, duration, attack, lowpass, gain in SPECS:
        source_record = next(r for r in registry['sounds'] if r['id'] == parent.split('.')[0])
        source_candidate = next(a for a in source_record['alternatives'] if a['id'] == parent)
        source = ROOT / source_candidate['path']
        record = next((r for r in registry['sounds'] if r['key'] == 'skitterling/' + event), None)
        if record is None:
            record = {'id': f'DD-S{next_slot:04d}', 'uuid': str(uuid.uuid4()), 'key': 'skitterling/' + event,
                      'section': 'Level 1', 'name': 'Skitterling — surface warning', 'paths': [],
                      'status': 'proposed', 'source': MANIFEST, 'alternatives': []}
            registry['sounds'].append(record)
            next_slot += 1
        suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
        identity = f"{record['id']}.{suffix}"
        runtime = ROOT / 'assets/audio/sfx/skitterling-action-sync-v8' / f'{event}.wav'
        filters = (f'atrim=start={offset}:duration={duration},asetpts=N/SR/TB,lowpass=f={lowpass},'
                   f'afade=t=in:d={attack},afade=t=out:st={duration - .09}:d=0.09')
        command = ['ffmpeg', '-v', 'error', '-n', '-i', str(source), '-af', filters,
                   '-ar', '44100', '-ac', '1', '-c:a', 'pcm_s16le', str(runtime)]
        subprocess.run(command, check=True)
        audition = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
        if audition.exists():
            raise FileExistsError(audition)
        audition.parent.mkdir(parents=True, exist_ok=True)
        audition.write_bytes(runtime.read_bytes())
        record['alternatives'].append({'id': identity, 'path': str(audition.relative_to(ROOT)),
            'name': f'ACTION SYNC v8 · {event} · {duration:.2f}s', 'source_candidate': parent,
            'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
            'provenance': 'Timing edit of Sean-approved CC0 recorded-source living-insect design; pitch preserved.'})
        record['selected_candidate'] = identity
        outputs.append({'event': event, 'path': str(runtime.relative_to(ROOT)), 'candidate': identity,
                        'source_candidate': parent, 'source_path': source_candidate['path'],
                        'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                        'sha256': hashlib.sha256(runtime.read_bytes()).hexdigest(),
                        'duration_seconds': duration, 'gain_db': gain, 'loop': False, 'command': command})
    manifest = {'date': '2026-11-05',
                'status': 'Approved voices edited to Level Design timing; Engineering integration pending',
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)), 'cues': outputs,
                'source_manifests': ['audio/sources/skitterling-living-insect-v6/manifest.json',
                                     'audio/sources/skitterling-alligator-deep-v7/manifest.json'],
                'action_contract': [
                    'Rat assembly remains approved V4 .7,1.15s within1.4s. No old shriek/assembly layer.',
                    'Rat rush .74s within.8 tell; pounce .92s within1s tell; stop warning at actual attack start too.',
                    'Pounce flight .9s has only launch contact; one landing contact on recovery entry; no vocal tail.',
                    'Rat wall/climb/rush use quiet skitter, no repeated voices; stop/fade motion effects on exit.',
                    'Pipe warning capped1.9s; each occupied retry replaces rather than stacks warning.',
                    'Pipe launch/abort/hide stop warning and obsolete launch tails; landing contact once.',
                    'Alligator formation1.85s spans1.4assembly+.6ready; replace only alligator old1.4s cutoff.',
                    'Charge and turn each get .82s cue in.9s tell; attack_start stops warning on both legs.',
                    'Tail .90s within1s tell; keep .35s physical sweep contact and recovery silent except shared bed.',
                    'Underwater volley .72s within.8s; keep six short debris releases .22s apart, impact throttle.10s.',
                    'Add alligator_surface_warning→surface_warning event, .90s in1s tell. Muffled swelling envelope '
                    'differs from immediate brighter charge; stop on abort/swim_start, dive, emerge or death/reset.',
                    'Keep wet dive/emerge contacts, jaw snap at charge onset, hit/death and shared beds.',
                    'No vocal loop during charge or recovery; no extra sound in.1s surface recovery.',
                    'One warning voice; new tell replaces prior; duck bed-6dB and prevent effects masking tells.',
                    'Pause/resume continues phase, mute/reset/death preempts; sound completion never controls combat.'],
                'validation_required': ['Both charge legs; rat pounce takeoff/landing and rush; pipe repeat/abort;',
                                        'surface abort/retry; death during tell; pause/mute/reset;',
                                        'actual listening for full alligator cycle and surface/charge distinctness.'],
                'limitations': 'Timing and technical checks do not establish in-game listening acceptance.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    p.write_text(json.dumps(registry, indent=2) + '\n')
    print([(c['event'], c['candidate'], c['duration_seconds']) for c in outputs])


if __name__ == '__main__':
    main()
