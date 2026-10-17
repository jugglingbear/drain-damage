#!/usr/bin/env python3
"""Render original short mechanical door cues with deterministic additive synthesis."""

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
OUTPUT = ROOT / 'assets/audio/sfx/sliding-progress-door-v1'
SPECS = [('latch', 0.12, -15), ('motor-slide', 0.9, -18), ('end-stop', 0.18, -15)]


def synthesize(name: str, duration: float, peak_db: float, seed: int) -> list[float]:
    """Layer muted metal resonances with band-limited motor and friction noise."""
    rng = random.Random(seed)
    result = []
    filtered = 0.0
    for index in range(round(duration * RATE)):
        t = index / RATE
        filtered += 0.12 * (rng.uniform(-1, 1) - filtered)
        if name == 'motor-slide':
            motor = math.sin(math.tau * 95 * t) + 0.25 * math.sin(math.tau * 190 * t)
            gear = 0.12 * math.sin(math.tau * 665 * t) * (0.7 + 0.3 * math.sin(math.tau * 28 * t))
            value = 0.4 * motor + gear + filtered * 0.5
            edge = min(1, t / 0.06, (duration - t) / 0.08)
        else:
            base = 270 if name == 'latch' else 115
            decay = 40 if name == 'latch' else 27
            value = sum(math.sin(math.tau * base * ratio * t) * weight * math.exp(-decay * ratio * t)
                        for ratio, weight in [(1, 0.7), (2.31, 0.3), (4.17, 0.12)])
            value += filtered * math.exp(-65 * t) * 0.7
            edge = min(1, t / 0.003, (duration - t) / 0.03)
        result.append(value * max(0, edge))
    scale = 10 ** (peak_db / 20) / max(map(abs, result))
    return [value * scale for value in result]


def save(path: Path, samples: list[float]) -> None:
    """Save a mono 16-bit PCM file with no leading delay or looping metadata."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(s * 32767) for s in samples)))


def main() -> None:
    """Generate runtime cues, a reference mix and the provenance manifest."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    preview = [0.0] * round(1.08 * RATE)
    cues = []
    for index, (name, duration, peak) in enumerate(SPECS):
        samples = synthesize(name, duration, peak, 16200 + index)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        offset = round((0.9 if name == 'end-stop' else 0) * RATE)
        for position, value in enumerate(samples):
            preview[offset + position] += value * 10 ** (-3 / 20)
        cues.append({'cue_id': 'door-' + name, 'path': str(path.relative_to(ROOT)),
                     'duration_seconds': duration, 'peak_dbfs': peak, 'gain_db': -3, 'loop': False,
                     'rms_dbfs': round(20 * math.log10(math.sqrt(sum(s * s for s in samples) / len(samples))), 2),
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'seed': 16200 + index})
    assert max(map(abs, preview)) < 1
    save(SOURCE / 'door-opening-reference-v1.wav', preview)
    manifest = {'schema_version': 1, 'date': '2026-10-16', 'cues': cues,
                'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'brief': 'Brief latch, restrained motor/metal movement over 0.9s downward slide, separate end clunk.',
                'provenance': 'Original deterministic synthesis; no recordings, samples, voice or external assets.',
                'rights': 'Project-generated audio; no third-party sample license obligations introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Technical candidate delivery; subjective listening and runtime integration pending'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
