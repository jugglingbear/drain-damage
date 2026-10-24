#!/usr/bin/env python3
"""Render five original liquid-textured alternatives while preserving earlier auditions."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parent
SPECS = [
    ('T7', 'Splash jet', 'Full water rush with a clustered splash and scattered droplets.', .32, 24, .16, .10),
    ('T8', 'Bubbling squirt', 'A short squirt with rounded, overlapping water bubbles.', .28, 18, .11, .18),
    ('T9', 'Sloshing burst', 'A heavier liquid surge with low gurgles and a wet tail.', .38, 30, .18, .15),
    ('T10', 'Droplet spray', 'A lighter jet breaking into many small, bright droplets.', .30, 42, .10, .11),
    ('T11', 'Water gush', 'A sustained hose-like gush with turbulent splashes underneath.', .40, 35, .23, .10),
]


def render(number: int, duration: float, count: int, rush: float, bubbles: float) -> list[float]:
    """Combine turbulent flow with short, rising resonances resembling submerged bubbles."""
    rng = random.Random(23000 + number)
    values = [0.0] * round(duration * RATE)
    slow = fast = movement = 0.0
    for index in range(len(values)):
        time = index / RATE
        fraction = time / duration
        noise = rng.uniform(-1, 1)
        slow += .018 * (noise - slow)
        fast += .25 * (noise - fast)
        movement += .002 * (rng.uniform(-1, 1) - movement)
        envelope = min(1, time / .012) * math.exp(-fraction * 2.3)
        values[index] = rush * (fast - slow) * envelope * (1 + 9 * movement)
    for _ in range(count):
        start = rng.uniform(.008, duration * .80)
        length = rng.uniform(.016, .060)
        frequency = rng.uniform(450, 2100)
        if number == 9:
            frequency *= .55
        elif number == 10:
            frequency *= 1.5
        amplitude = bubbles * rng.uniform(.25, 1) * math.exp(-start / duration)
        offset = round(start * RATE)
        phase = 0.0
        for index in range(round(length * RATE)):
            if offset + index >= len(values):
                break
            age = index / RATE
            fraction = age / length
            phase += math.tau * frequency * (1 + .45 * fraction) / RATE
            envelope = min(1, age / .0015) * math.exp(-fraction * 5)
            # A damped bubble resonance and brief noisy splash avoid a pure electronic chirp.
            tone = math.sin(phase) + .18 * math.sin(phase * 1.73)
            splash = rng.uniform(-1, 1) * math.exp(-fraction * 15)
            values[offset + index] += amplitude * envelope * (tone + .35 * splash)
    for index in range(len(values)):
        values[index] *= min(1, index / (RATE * .003), (len(values) - 1 - index) / (RATE * .025))
    rms = math.sqrt(sum(value * value for value in values) / len(values))
    gain = min(10 ** (-24 / 20) / rms, 10 ** (-9 / 20) / max(map(abs, values)))
    return [value * gain for value in values]


def save(name: str, values: list[float]) -> dict[str, object]:
    """Save PCM WAV and record measurements of the quantized samples."""
    path = ROOT / (name + '.wav')
    pcm = [round(value * 32767) for value in values]
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32768
    return {'path': 'water-round-2/' + path.name, 'duration_seconds': len(pcm) / RATE,
            'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
            'rms_dbfs': round(20 * math.log10(rms), 2),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main() -> None:
    """Generate only new choices; never rewrite the preserved T5 or Sean samples."""
    choices = []
    for identity, name, description, duration, count, rush, bubbles in SPECS:
        values = render(int(identity[1:]), duration, count, rush, bubbles)
        single = save(identity, values)
        demo = [0.0] * round((.64 + duration + .12) * RATE)
        for shot in range(5):
            offset = round(shot * .16 * RATE)
            for index, value in enumerate(values):
                demo[offset + index] += value
        gain = min(1, 10 ** (-6 / 20) / max(map(abs, demo)))
        repeated = save(identity + '-repeat', [value * gain for value in demo])
        choices.append({'id': identity, 'name': name, 'description': description,
                        'single': single, 'repeated': repeated, 'repeat_interval_seconds': .16,
                        'repeat_shots': 5, 'repeat_extra_gain_db': round(20 * math.log10(gain), 2),
                        'source': 'Original sample-free liquid resonance and turbulent-noise synthesis.'})
    manifest = {'date': '2026-10-23', 'choices': choices,
                'provenance': 'Original project synthesis, no external recordings or third-party samples.',
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Audition only. T5 remains a candidate; no runtime selection.'}
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
