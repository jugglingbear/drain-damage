#!/usr/bin/env python3
"""Create twelve original water/plunger sound auditions, never replacing runtime audio."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
SOURCE = Path(__file__).resolve().parent
SAMPLES = SOURCE / 'samples'
SPECS = [
    ('T1', 'Quick spray', 'Short, airy spray with a small wet click.', .16),
    ('T2', 'Pressure punch', 'A heavier valve kick followed by a tight water burst.', .18),
    ('T3', 'Fine jet', 'A thin, bright jet with less low-end thump.', .13),
    ('T4', 'Wet sputter', 'Three uneven little splashes in each shot.', .24),
    ('T5', 'Hose pulse', 'A fuller rushing jet with a soft, rounded onset.', .25),
    ('T6', 'Droplet snap', 'A crisp spray followed by a small pitched droplet.', .21),
    ('S1', 'Suction pop', 'A short vacuum-like pull ending in a rubber pop.', .20),
    ('S2', 'Rubber thump', 'Low, blunt rubber impact with a small squeak.', .22),
    ('S3', 'Cup release', 'A rising suction squeak and hollow release.', .28),
    ('S4', 'Wet plop', 'A soft wet impact with a rounded, descending body.', .24),
    ('S5', 'Springy plunger', 'An elastic pitch wobble with a firmer attack.', .30),
    ('S6', 'Hollow punch', 'A deeper cup-like knock with a short suction tail.', .19),
]


def synth(identity: str, duration: float) -> list[float]:
    """Synthesize materially distinct candidates using original noise, resonances and envelopes."""
    number = int(identity[1:])
    rng = random.Random(12000 + number + (100 if identity.startswith('S') else 0))
    low = band = phase = 0.0
    values = []
    for index in range(round(duration * RATE)):
        time = index / RATE
        fraction = time / duration
        noise = rng.uniform(-1, 1)
        low += .025 * (noise - low)
        band += (.18 if number != 3 else .45) * (noise - band)
        if identity.startswith('T'):
            envelope = math.exp(-fraction * (4 if number != 5 else 2))
            attack = min(1, time / (.014 if number == 5 else .003))
            value = (band - low) * envelope * attack
            if number == 2:
                value += .12 * math.sin(math.tau * 130 * time) * math.exp(-time * 45)
            elif number == 3:
                value = (noise - band) * .4 * envelope * attack
            elif number == 4:
                pulse = sum(math.exp(-((time - center) / .016) ** 2) for center in [.02, .09, .16])
                value *= pulse
            elif number == 6:
                age = max(0, time - .07)
                value += .10 * math.sin(math.tau * (1200 * age - 1800 * age * age)) * math.exp(-age * 45)
        else:
            start = [0, 270, 150, 180, 240, 220, 110][number]
            pitch = start * (1.5 - fraction) if number != 3 else start * (.7 + 2.4 * fraction)
            if number == 5:
                pitch *= 1 + .18 * math.sin(math.tau * 28 * time)
            phase += math.tau * pitch / RATE
            envelope = math.exp(-fraction * 5)
            if number in [1, 3]:
                envelope = math.sin(math.pi * fraction) ** .7
            value = (.4 * math.sin(phase + .9 * math.sin(phase * 2)) + .15 * math.sin(phase * 3)) * envelope
            value += (band - low) * (.25 if number == 4 else .08) * math.exp(-fraction * 3)
            if number == 6:
                value += .18 * math.sin(phase * 1.62) * math.exp(-fraction * 8)
        value *= max(0, min(1, time / .002, (duration - 1 / RATE - time) / .02))
        values.append(value)
    return values


def save(path: Path, values: list[float]) -> dict[str, object]:
    """Write portable PCM WAV with signal measurements and file integrity metadata."""
    pcm = [round(max(-1, min(1, value)) * 32767) for value in values]
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    rms = math.sqrt(sum(v * v for v in values) / len(values))
    return {'path': str(path.relative_to(SOURCE)), 'duration_seconds': len(values) / RATE,
            'peak_dbfs': round(20 * math.log10(max(map(abs, values))), 2),
            'rms_dbfs': round(20 * math.log10(rms), 2), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main() -> None:
    """Render matched auditions and repeated-fire examples with explicit synthetic provenance."""
    SAMPLES.mkdir(exist_ok=True)
    choices = []
    for identity, name, description, duration in SPECS:
        values = synth(identity, duration)
        rms = math.sqrt(sum(v*v for v in values) / len(values))
        gain = min(10 ** (-24/20) / rms, 10 ** (-9/20) / max(map(abs, values)))
        values = [v * gain for v in values]
        single = save(SAMPLES / (identity + '.wav'), values)
        interval = .16 if identity.startswith('T') else .24
        demo = [0.0] * round((4 * interval + duration + .12) * RATE)
        for shot in range(5):
            offset = round(shot * interval * RATE)
            for index, value in enumerate(values):
                demo[offset + index] += value
        demo_gain = min(1, 10 ** (-6/20) / max(map(abs, demo)))
        repeated = save(SAMPLES / (identity + '-repeat.wav'), [v * demo_gain for v in demo])
        choices.append({'id': identity, 'name': name, 'description': description, 'single': single,
                        'repeated': repeated, 'repeat_interval_seconds': interval, 'repeat_shots': 5,
                        'repeat_extra_gain_db': round(20 * math.log10(demo_gain), 2),
                        'source': 'Original deterministic procedural synthesis; not a real-world recording.'})
    manifest = {'date': '2026-10-23', 'status': 'Audition only; no choice or runtime replacement authorized.',
                'choices': choices, 'provenance': 'All 12 candidates are original sample-free project-generated audio. '
                'No external recordings, models, soundfonts or third-party attribution obligations.',
                'rights': 'Project-generated material for this project; no third-party sample licenses apply.',
                'normalization': 'Single-shot target RMS-24dBFS, peak ceiling-9dBFS; demos use same shot gain unless '
                'overlap exceeds-6dBFS. Peak ceiling may prevent exact RMS matching. No subjective loudness claim.',
                'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'generator': 'generate.py', 'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'limitations': 'Synthetic interpretations, not recorded water or rubber. '
                'Auditory suitability awaits Sean.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Rendered 12 single shots and 12 five-shot demos; no playback.')


if __name__ == '__main__':
    main()
