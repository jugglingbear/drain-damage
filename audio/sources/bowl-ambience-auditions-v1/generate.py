#!/usr/bin/env python3
"""Create six comic bodily ambience auditions, with no runtime mapping or recorded voices."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
SPECS = [
    ('strain-1', 'Short effort', 'One low, rounded effort grunt with a breathy release.', .8),
    ('strain-2', 'Double push', 'Two small effort pulses, with a higher second grunt.', 1.25),
    ('strain-3', 'Long squeeze', 'A sustained nasal effort wobble that relaxes at the end.', 1.65),
    ('body-1', 'Dry raspberry', 'A brief fluttering fart with a crisp, dry finish.', .55),
    ('body-2', 'Bubble sputter', 'An uneven wet fart with a few rounded bubble pops.', 1.05),
    ('body-3', 'Plop and ripple', 'A low dropping plop followed by small watery bubbles.', .85),
]
BRIEF = ('Auditions only: three struggling-to-poop grunt options and three poop/fart/plop options; '
         'comic bodily effort, not distress or horror; possible occasional above-bowl ambience. '
         'No dialogue, actual-person imitation, runtime scheduling or integration.')


def synth(kind: str, duration: float) -> list[float]:
    """Render distinct synthetic effort or bodily textures with finite, softened endpoints."""
    number = int(kind[-1])
    rng = random.Random(241000 + number + (10 if kind.startswith('body') else 0))
    values: list[float] = []
    phase = low = 0.0
    for index in range(round(duration * RATE)):
        time = index / RATE
        fraction = time / duration
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        if kind.startswith('strain'):
            pitch = [0, 108, 132, 155][number] * (1 + .045 * math.sin(math.tau * 5 * time))
            pitch *= 1 + .10 * math.sin(math.pi * fraction)
            phase += math.tau * pitch / RATE
            formant = 430 if number != 3 else 720
            voice = sum(math.sin(phase * harmonic) *
                        (.10 + math.exp(-((pitch * harmonic - formant) / 240) ** 2)) / harmonic
                        for harmonic in range(1, 13))
            envelope = math.sin(math.pi * fraction) ** .7
            if number == 2:
                envelope *= (.5 + .5 * math.cos(math.tau * fraction)) ** .7
            value = voice * envelope + .055 * low * math.sin(math.pi * fraction)
        elif number == 1:
            phase += math.tau * (65 - 23 * fraction) / RATE
            value = (math.tanh(4 * math.sin(phase)) * .22 + .14 * low) * (1 - fraction) ** 1.4
        elif number == 2:
            phase += math.tau * (48 + 12 * math.sin(math.tau * 7 * time)) / RATE
            flutter = (.6 + .4 * math.sin(math.tau * 11 * time))
            value = (.22 * math.tanh(3 * math.sin(phase)) + .2 * low) * flutter * (1 - fraction)
            value += .10 * math.sin(math.tau * (390 * time + 12 * math.sin(math.tau * 3 * time)))
            value *= math.sin(math.pi * fraction) ** .5
        else:
            phase += math.tau * (100 + 500 * math.exp(-time * 25)) / RATE
            value = .5 * math.sin(phase) * math.exp(-time * 14) + low * .35 * math.exp(-time * 20)
            for start, frequency in [(.16, 620), (.27, 840), (.39, 530)]:
                age = time - start
                if age >= 0:
                    value += .13 * math.sin(math.tau * frequency * age) * math.exp(-age * 35)
        value *= min(1, time / .012, max(0, (duration - 1 / RATE - time) / .05))
        values.append(value)
    rms = math.sqrt(sum(v*v for v in values) / len(values))
    gain = min(10 ** (-24 / 20) / rms, 10 ** (-12 / 20) / max(map(abs, values)))
    return [value * gain for value in values]


def main() -> None:
    """Save immutable first-pass WAVs and provenance; registration is coordinated separately."""
    choices = []
    for kind, name, description, duration in SPECS:
        values = synth(kind, duration)
        pcm = [round(value * 32767) for value in values]
        payload = struct.pack('<' + 'h' * len(pcm), *pcm)
        path = SOURCE / (kind + '.wav')
        if path.exists():
            with wave.open(str(path)) as existing:
                assert existing.readframes(existing.getnframes()) == payload, 'Preserve originals; version changes.'
        else:
            with wave.open(str(path), 'wb') as output:
                output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                output.writeframes(payload)
        choices.append({'key': kind, 'name': name, 'description': description,
                        'category': 'Comic straining' if kind.startswith('strain') else 'Fart and plop',
                        'path': str(path.relative_to(ROOT)), 'duration_seconds': duration,
                        'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                        'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'generation_brief': BRIEF, 'choices': choices, 'format': '32000 Hz mono PCM16 WAV',
                'provenance': 'Original deterministic sample-free synthesis; not human or real bodily recordings. '
                'No third-party samples, voice models, imitation targets or attribution obligations.',
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Auditions only; no runtime integration authorized.',
                'limitations': 'No subjective listening performed. May sound cartoon-like/electronic; '
                'human vocal realism and comic effectiveness are not established.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
