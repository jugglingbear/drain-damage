#!/usr/bin/env python3
"""Lengthen and deepen the living-insect alligator calls while retaining crisp chitin detail."""

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    'Sean approves the living burbling rat calls and requests a bigger alligator equivalent: longer, deeper '
    'wet living-body churn with insectile detail. Improvise a fictional organism; no cute animal voice. '
    'Keep some high chitin texture above a slower lower body. Audition only, not approved runtime.'
)


def main() -> None:
    """Append three deep calls without overwriting any previous candidate."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve originals')
    p = ROOT / 'audio/sound-registry.json'
    registry = json.loads(p.read_text())
    record = next(r for r in registry['sounds'] if r['id'] == 'DD-S0024')
    suffix = max(int(a['id'].split('.')[-1]) for a in record['alternatives']) + 1
    outputs = []
    for index, (parent, speed, duration, name) in enumerate([
        ('DD-S0024.7', .70, 2.05, 'Deep wet gullet'),
        ('DD-S0024.8', .62, 2.4, 'Heavy living bellows'),
        ('DD-S0024.9', .50, 2.75, 'Slow carapace churn'),
    ]):
        source = ROOT / next(a['path'] for a in record['alternatives'] if a['id'] == parent)
        identity = f'DD-S0024.{suffix + index}'
        target = ROOT / 'audio/alternatives/DD-S0024' / f'{identity}.wav'
        filters = (
            f'[0:a]asplit=2[body][detail];[body]asetrate={round(44100 * speed)},aresample=44100,'
            'highpass=f=55,lowpass=f=4200[b];'
            '[detail]highpass=f=1600,volume=0.18[d];'
            f'[b][d]amix=inputs=2:normalize=0,apad,atrim=duration={duration},'
            f'afade=t=in:d=0.008,afade=t=out:st={duration - .45}:d=0.45[out]'
        )
        command = ['ffmpeg', '-v', 'error', '-n', '-i', str(source), '-filter_complex', filters,
                   '-map', '[out]', '-ar', '44100', '-ac', '1', '-c:a', 'pcm_s16le', str(target)]
        subprocess.run(command, check=True)
        record['alternatives'].append({'id': identity, 'path': str(target.relative_to(ROOT)),
            'name': f'DEEP LIVING v7 · {name} · {duration:.2f}s', 'source_manifest': MANIFEST,
            'generation_prompt': BRIEF,
            'provenance': 'Retained rubberduck CC0 burble/mouth/insect design, pitch/rate edit.'})
        outputs.append({'id': identity, 'parent': parent, 'path': str(target.relative_to(ROOT)),
                        'source_path': str(source.relative_to(ROOT)),
                        'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                        'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                        'speed': speed, 'duration_seconds': duration, 'command': command})
    manifest = {'date': '2026-11-05', 'brief': BRIEF, 'status': 'Longer deeper alligator auditions; selection pending',
                'source_manifest': 'audio/sources/skitterling-living-insect-v6/manifest.json',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'outputs': outputs,
                'integration_note': 'These exceed the current 1.4s assembly cutoff. If selected, allow the body tail '
                                    'to continue or create event-length edits without extending gameplay warnings.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    p.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['duration_seconds']) for o in outputs])


if __name__ == '__main__':
    main()
