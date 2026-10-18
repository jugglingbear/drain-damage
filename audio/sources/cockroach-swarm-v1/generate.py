#!/usr/bin/env python3
"""Create original roach-swarm textures and event cues without playing audio."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/sfx' / SOURCE.name
SPECS = [('formed-loop', 2.0, -20, -9, True), ('dispersed-loop', 2.0, -20, -9, True),
         ('hit', .20, -15, -3, False), ('collapse', .65, -15, -4, False),
         ('reform', .60, -15, -4, False), ('death', 1.1, -12, -3, False),
         ('rat-warning', .80, -12, -3, False), ('alligator-warning', 1.0, -12, -3, False)]


def texture(duration: float, density: int, seed: int, circular: bool) -> list[float]:
    """Mix independently enveloped grains; circular placement preserves a continuous periodic bed."""
    rng = random.Random(seed)
    count = round(duration * RATE)
    samples = [0.0] * count
    for _ in range(density):
        start = rng.randrange(count)
        length = round(rng.uniform(.009, .065) * RATE)
        frequency = rng.uniform(650, 3200)
        gain = rng.uniform(.15, .65)
        smooth = 0.0
        for index in range(length):
            target = start + index
            if not circular and target >= count:
                break
            smooth += .32 * (rng.uniform(-1, 1) - smooth)
            envelope = math.sin(math.pi * index / (length - 1)) ** 2
            grain = .75 * smooth + .25 * math.sin(math.tau * frequency * index / RATE)
            samples[target % count] += gain * envelope * grain
    for index in range(count):
        time = index / RATE
        samples[index] += .035 * (math.sin(math.tau * 87 * time) + .4 * math.sin(math.tau * 133 * time))
    return samples


def main() -> None:
    """Write eight PCM cues, measured levels, hashes and exact synthesis provenance."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cues = []
    for number, (name, duration, peak_db, gain_db, loop) in enumerate(SPECS):
        seed = 64100 + number
        samples = texture(duration, 190 if name == 'dispersed-loop' else 130, seed, loop)
        if not loop:
            for index in range(len(samples)):
                time = index / RATE
                fraction = time / duration
                if name.endswith('warning'):
                    pulses = 3 if name == 'rat-warning' else 2
                    pulse = math.sin(math.pi * ((fraction * pulses) % 1)) ** 6
                    samples[index] += .12 * pulse * math.sin(math.tau * 980 * time)
                    envelope = .3 + .7 * pulse
                elif name == 'reform':
                    envelope = .08 + fraction ** 1.5
                elif name == 'collapse':
                    envelope = .5 + .5 * math.sin(math.pi * fraction)
                else:
                    envelope = math.exp(-fraction * (6 if name == 'hit' else 3))
                impact = math.sin(math.tau * (230 * time - 100 * time * time)) * math.exp(-time * 22)
                impact_gain = .0 if name == 'reform' or name.endswith('warning') else .18
                samples[index] = samples[index] * envelope + impact_gain * impact
                samples[index] *= max(0, min(1, time / .004, (duration - 1 / RATE - time) / .055))
        scale = 32767 * 10 ** (peak_db / 20) / max(map(abs, samples))
        pcm = [round(value * scale) for value in samples]
        path = OUTPUT / (name + '.wav')
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
        steps = [abs(pcm[i] - pcm[i - 1]) for i in range(1, len(pcm))]
        seam = abs(pcm[-1] - pcm[0])
        assert max(map(abs, pcm)) < 9000
        if loop:
            assert seam <= max(steps)
        else:
            assert pcm[0] == pcm[-1] == 0
        rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32767
        cues.append({'cue_id': name, 'path': str(path.relative_to(ROOT)), 'duration_seconds': duration,
                     'gain_db': gain_db, 'peak_dbfs': peak_db, 'rms_dbfs': round(20 * math.log10(rms), 2),
                     'loop': loop, 'loop_begin_frame': 0, 'loop_end_frame_exclusive': len(pcm),
                     'boundary_step_pcm': seam, 'max_internal_step_pcm': max(steps), 'seed': seed,
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'schema_version': 1, 'date': '2026-10-17', 'cues': cues,
                'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'provenance': 'Original deterministic synthesis; no third-party samples, voices or music.',
                'rights': 'Project-generated audio; no third-party sample licensing obligations introduced.',
                'procedure': 'Seeded filtered-noise/chitin grains, sinusoidal grain envelopes, circular placement '
                             'for periodic loops, integer-period low churn. One-shot phase envelopes and edge fades.',
                'generator': str(Path(__file__).resolve().relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Source assets only; runtime integration and subjective listening pending.',
                'validation': 'Headers, peaks, endpoints, loop boundary step and deterministic hashes checked. '
                              'Boundary check is mathematical continuity evidence, not an audition.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(cues, indent=2))


if __name__ == '__main__':
    main()
