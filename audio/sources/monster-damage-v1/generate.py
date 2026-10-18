#!/usr/bin/env python3
"""Render original deterministic monster impacts and insect death cues without playback."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
OUTPUT = ROOT / 'assets/audio/sfx/monster-damage-v1'
SPECS = [
    ('widow-hit', .20, -15, 6301), ('widow-death', 1.25, -12, 6302),
    ('flushfiend-hit', .18, -15, 6303), ('swarm-hit', .16, -15, 6304),
    ('swarm-death', .48, -12, 6305), ('gratecrawler-hit', .22, -15, 6306),
    ('gratecrawler-death', .68, -12, 6307),
]


def render(name: str, duration: float, seed: int) -> list[float]:
    """Synthesize material impacts or nonverbal stridulation with bounded, decaying envelopes."""
    rng = random.Random(seed)
    samples = []
    low = phase = 0.0
    for index in range(round(RATE * duration)):
        time = index / RATE
        progress = time / duration
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        if name.startswith('widow'):
            death = name.endswith('death')
            frequency = (2600 - 1750 * progress if death else 1800 - 900 * progress)
            frequency += 180 * math.sin(math.tau * 47 * time)
            phase += math.tau * frequency / RATE
            rasp = .6 * math.sin(phase) + .23 * math.sin(2.43 * phase) + .17 * (noise - low)
            pulse = .4 + .6 * (.5 + .5 * math.sin(math.tau * (67 if death else 93) * time))
            envelope = (math.sin(math.pi * progress) ** .55 if death else math.exp(-time * 23))
            value = rasp * pulse * envelope
        elif name == 'flushfiend-hit':
            value = sum(math.sin(math.tau * freq * time) * math.exp(-time * decay) * gain
                        for freq, decay, gain in [(860, 36, .6), (2340, 48, .3), (3710, 65, .18)])
            value += .25 * (noise - low) * math.exp(-time * 110)
        elif name.startswith('swarm'):
            death = name.endswith('death')
            phase += math.tau * (510 - (380 if death else 120) * progress) / RATE
            value = (.45 * math.sin(phase) + .2 * math.sin(phase * 3) + .35 * (noise - low))
            value *= (.3 + .7 * math.sin(math.tau * 73 * time) ** 2) * math.exp(-progress * 4)
        else:
            death = name.endswith('death')
            phase += math.tau * (185 - 110 * progress) / RATE
            value = (.65 * low + .3 * math.sin(phase) + .12 * noise) * math.exp(-progress * 5)
            if death:
                # Delayed wet contacts imply collapse without borrowing the dispenser's identity.
                for offset, gain in [(.16, .35), (.31, .20), (.44, .12)]:
                    age = time - offset
                    if age >= 0:
                        value += gain * (low + .3 * noise) * math.exp(-age * 35)
        edge = max(0, min(1, time / .003, (duration - 1 / RATE - time) / .035))
        samples.append(value * edge)
    return samples


def main() -> None:
    """Write reproducible PCM assets and their measured provenance manifest."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cues = []
    for name, duration, peak_db, seed in SPECS:
        samples = render(name, duration, seed)
        scale = 32767 * 10 ** (peak_db / 20) / max(map(abs, samples))
        pcm = [round(value * scale) for value in samples]
        path = OUTPUT / (name + '.wav')
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
        assert pcm[0] == pcm[-1] == 0 and max(map(abs, pcm)) < 9000
        rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32767
        cues.append({'cue_id': name, 'path': str(path.relative_to(ROOT)), 'duration_seconds': duration,
                     'peak_dbfs': peak_db, 'rms_dbfs': round(20 * math.log10(rms), 2), 'gain_db': -3,
                     'loop': False, 'seed': seed, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {
        'schema_version': 1, 'date': '2026-10-17', 'cues': cues,
        'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
        'provenance': 'Original deterministic procedural synthesis; no third-party samples, voices or music.',
        'rights': 'Project-generated material; no third-party sample licensing obligations introduced.',
        'direction': 'Widow: insect stridulation hit and longer descending screech; Flushfiend: ceramic tap; '
                     'swarm: insect crackle and dispersal; Gratecrawler: wet gravel impact and sludge collapse.',
        'generator': str(Path(__file__).resolve().relative_to(ROOT)),
        'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'validation': 'PCM headers, durations, peaks, zero endpoints and reproducibility checked; no audition.',
        'status': 'Asset delivery; subjective listening and runtime integration pending.',
        'limitations': 'Synthesized sound direction, not biological realism or added lore. Listening pending.',
    }
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(cues, indent=2))


if __name__ == '__main__':
    main()
