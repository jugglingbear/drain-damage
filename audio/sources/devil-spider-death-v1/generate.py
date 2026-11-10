#!/usr/bin/env python3
"""Create a brief lethal scream with fire onset and falling-ash crackle."""

import array
import hashlib
import json
import math
import random
import subprocess
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100
DURATION = .95
SOURCE = 'audio/sources/recorded-creatures-cc0-v1/rubberduck/scream_01.ogg'
FILTER = 'aresample=44100,asetrate=35280,aresample=44100,highpass=f=180,lowpass=f=6200'
BRIEF = (
    'Direct devil-spider death request: burst into flames, short horrifying creature scream, ash collapse, '
    'doll heads fall and persist. One readable lethal cue, fire onset then scream and short crackling tail; '
    'no continuous bed or repeated head-impact clutter. Distinct from still-unselected web auditions.'
)


def main() -> None:
    """Preserve originals, register the next death candidate and copy identical runtime bytes."""
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    record = next(r for r in registry['sounds'] if r['key'] == 'creature/devil-spider/death')
    suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
    identity = f"{record['id']}.{suffix}"
    runtime = ROOT / 'assets/audio/sfx/devil-spider-death-v1/scream-burn.wav'
    audition = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
    for path in (runtime, audition, HERE / 'manifest.json'):
        if path.exists():
            raise FileExistsError(path)
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(ROOT / SOURCE), '-af', FILTER,
                          '-ac', '1', '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    voice = list(array.array('f', raw))
    source_peak = max(map(abs, voice))
    onset = next(i for i, v in enumerate(voice) if abs(v) > source_peak * .04)
    voice = [v / source_peak for v in voice[max(0, onset - 100):]]
    rng = random.Random(114043)
    low = band = 0.0
    samples = []
    crackles = [(.08, .18), (.23, .12), (.47, .12), (.63, .1), (.76, .07), (.85, .04)]
    for index in range(round(DURATION * RATE)):
        time = index / RATE
        noise = rng.uniform(-1, 1)
        low += .045 * (noise - low)
        band += .32 * (noise - band)
        # Broadband pressure bloom and brief crackles; no musical oscillator or repeated ambience.
        burst = (low * 1.9 + band * .5) * math.exp(-time * 13) * .65
        crackle = sum(gain * math.exp(-(time - at) * 95) for at, gain in crackles if time >= at)
        fire = burst + (noise - band) * crackle
        source_index = index - round(.025 * RATE)
        scream = voice[source_index] if 0 <= source_index < len(voice) else 0.0
        scream *= min(1, max(0, source_index) / 400) * min(1, max(0, (.76 - time) / .16))
        value = .8 * scream + fire
        value *= min(1, index / 220, (round(DURATION * RATE) - 1 - index) / 1102)
        samples.append(value)
    gain = 10 ** (-7 / 20) / max(map(abs, samples))
    pcm = array.array('h', (round(v * gain * 32767) for v in samples))
    audition.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(audition), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    runtime.parent.mkdir(parents=True, exist_ok=True)
    runtime.write_bytes(audition.read_bytes())
    digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
    manifest_path = str((HERE / 'manifest.json').relative_to(ROOT))
    manifest = {'date': '2026-11-04', 'status': 'Directly requested death cue; ready for Engineering mapping',
                'candidate': identity, 'runtime': str(runtime.relative_to(ROOT)),
                'audition': str(audition.relative_to(ROOT)), 'duration_seconds': DURATION,
                'sha256': digest, 'peak_dbfs': -7, 'suggested_gain_db': -4, 'loop': False,
                'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
                'source': {'path': SOURCE, 'sha256': hashlib.sha256((ROOT / SOURCE).read_bytes()).hexdigest(),
                           'author': 'rubberduck', 'license': 'CC0-1.0',
                           'url': 'https://opengameart.org/content/80-cc0-creature-sfx',
                           'evidence': 'audio/sources/recorded-creatures-cc0-v1/manifest.json',
                           'filters': FILTER, 'pitch_semitones': 12 * math.log2(.8),
                           'leading_trim_samples': max(0, onset - 100)},
                'fire_layer': 'Original deterministic filtered-noise fire burst/crackle, seed 114043; no samples.',
                'trigger': 'Exactly once on lethal damage; suppress nonlethal hit cue on same event.',
                'sync': 'Fire onset at 0s; scream onset 0.025s, fades out by 0.76s; ash crackles end 0.95s.',
                'limits': 'Use bounded death voices with pause/mute/cancel. No per-head impact cues needed.',
                'validation_limit': 'Technical validation only; in-game mix and listening remain unverified.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    record['alternatives'].append({'id': identity, 'path': str(audition.relative_to(ROOT)),
                                  'name': 'Death — scream, flame burst and ash crackle · 0.95s',
                                  'source_manifest': manifest_path, 'generation_prompt': BRIEF,
                                  'provenance': 'CC0 rubberduck creature scream + original synthesized fire/crackle.'})
    record['selected_candidate'] = identity
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(identity, digest)


if __name__ == '__main__':
    main()
