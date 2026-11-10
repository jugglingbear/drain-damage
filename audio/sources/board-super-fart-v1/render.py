#!/usr/bin/env python3
"""Layer retained CC0 performed foley into a short exaggerated cosmetic board-super fart."""

import hashlib
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    'Approved board super: huge purely cosmetic fart with a giant cloud behind rider lasting about eight seconds. '
    'One exaggerated low wet flutter with a brief sputtering finish; '
    'sound shorter than cloud, no hop or gameplay effect.'
)


def main() -> None:
    """Create a new permanent audition and identical runtime asset without replacing originals."""
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    slot = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    identity = f'DD-S{slot:04d}'
    runtime = ROOT / 'assets/audio/sfx/board-super-fart-v1/huge-fart.wav'
    audition = ROOT / 'audio/alternatives' / identity / f'{identity}.1.wav'
    for path in (runtime, audition, HERE / 'manifest.json'):
        if path.exists():
            raise FileExistsError(path)
    sources = ['audio/alternatives/DD-S0109/DD-S0109.1.wav', 'audio/alternatives/DD-S0109/DD-S0109.2.wav']
    filters = (
        '[0:a]asetrate=28665,aresample=44100,highpass=f=45,lowpass=f=4200,volume=1.1[a];'
        '[1:a]asetrate=35280,aresample=44100,highpass=f=65,volume=0.55,adelay=1250[b];'
        '[a][b]amix=inputs=2:normalize=0,apad,atrim=duration=2.1,'
        'loudnorm=I=-20:TP=-7:LRA=7,aresample=44100,'
        'afade=t=in:d=0.008,afade=t=out:st=1.8:d=0.3[out]'
    )
    command = ['ffmpeg', '-v', 'error', '-n', '-i', str(ROOT / sources[0]), '-i', str(ROOT / sources[1]),
               '-filter_complex', filters, '-map', '[out]', '-ar', '44100', '-ac', '1',
               '-c:a', 'pcm_s16le', str(runtime)]
    runtime.parent.mkdir(parents=True, exist_ok=True)
    audition.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(command, check=True)
    audition.write_bytes(runtime.read_bytes())
    digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
    manifest = {'date': '2026-11-05', 'status': 'Approved behavior; audio delivered for runtime integration',
                'candidate': identity + '.1', 'runtime': str(runtime.relative_to(ROOT)),
                'audition': str(audition.relative_to(ROOT)), 'duration_seconds': 2.1,
                'sha256': digest, 'gain_db': -5, 'loop': False, 'brief': BRIEF,
                'sources': [{'path': p, 'sha256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()}
                            for p in sources],
                'provenance': 'LFA Gastric Distress, CC0-1.0, performed mouth/hand foley.',
                'license_evidence': 'audio/sources/ride-fidget-fart-v1/manifest.json',
                'source_url': 'https://opengameart.org/content/gastric-distress',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'ffmpeg_command': command,
                'trigger': 'One accepted super press; never loop for cloud duration. Ordinary fidget remains separate.',
                'playback': 'One bounded voice; suppress ordinary fart during this cue. Pause/resume, mute and '
                            'stop on death/reset/menu/dispose; no motion, damage or physics effect.',
                'cloud_seconds': 8,
                'validation_limit': 'In-game mix acceptance pending; charge behavior owned by Engineering.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry['sounds'].append({'key': 'proposed-board-super/fart', 'id': identity, 'uuid': str(uuid.uuid4()),
        'section': 'Level 2', 'name': 'Board super — huge cosmetic fart', 'paths': [],
        'source': MANIFEST, 'status': 'proposed', 'alternatives': [{
            'id': identity + '.1', 'path': str(audition.relative_to(ROOT)),
            'name': 'Huge wet flutter and sputter · 2.1s', 'source_manifest': MANIFEST,
            'generation_prompt': BRIEF, 'provenance': manifest['provenance']}]})
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(identity + '.1', digest)


if __name__ == '__main__':
    main()
