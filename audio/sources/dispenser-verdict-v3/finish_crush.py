#!/usr/bin/env python3
"""Preserve first render and trim stage two to the agreed sub-0.45s synchronization budget."""

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main() -> None:
    """Update canonical metadata and audition paths to a versioned .44-second second stage."""
    source = 'assets/audio/sfx/dispenser-verdict-v3/compress-stage-two.wav'
    target = 'assets/audio/sfx/dispenser-verdict-v3/compress-stage-two-v2.wav'
    command = ['ffmpeg', '-v', 'error', '-n', '-i', str(ROOT / source), '-af',
               'atrim=duration=0.44,afade=t=out:st=0.36:d=0.08', '-c:a', 'pcm_s16le', str(ROOT / target)]
    subprocess.run(command, check=True)
    digest = hashlib.sha256((ROOT / target).read_bytes()).hexdigest()
    manifest = json.loads((HERE / 'manifest.json').read_text())
    cue = next(c for c in manifest['cues'] if c['cue_id'] == 'compress-stage-two')
    manifest['preserved_stage_two'] = dict(cue)
    cue.update(path=target, duration_seconds=.44, sha256=digest)
    manifest['finish_command'] = command
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    p = ROOT / 'handoffs/spare-employee-dispenser-audio.json'
    handoff = json.loads(p.read_text())
    current = next(c for c in handoff['cues'] if c['cue_id'] == 'compress-stage-two')
    current.update(path=target, duration_seconds=.44, sha256=digest)
    p.write_text(json.dumps(handoff, indent=2) + '\n')
    p = ROOT / 'audio/sound-registry.json'
    registry = json.loads(p.read_text())
    record = next(r for r in registry['sounds'] if r['key'] == 'dispenser/compress-stage-two')
    alternative = record['alternatives'][0]
    candidate = Path(alternative['path']).with_name(alternative['id'] + '-v2.wav')
    if (ROOT / candidate).exists():
        raise FileExistsError(candidate)
    (ROOT / candidate).write_bytes((ROOT / target).read_bytes())
    alternative['path'] = str(candidate)
    p.write_text(json.dumps(registry, indent=2) + '\n')


if __name__ == '__main__':
    main()
