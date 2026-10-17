#!/usr/bin/env python3
"""Synthesize a layered cartoon wet impact and glass-slide without third-party samples."""

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
OUTPUT = ROOT / 'assets/audio/sfx/spare-employee-dispenser-v2'


def render(slide: bool) -> list[float]:
    """Layer filtered spray, pitched body and wet droplets with short, smooth tails."""
    duration = 0.56 if slide else 0.34
    rng = random.Random(16102 if slide else 16101)
    samples = []
    filtered = 0.0
    phase = 0.0
    for index in range(round(duration * RATE)):
        t = index / RATE
        u = t / duration
        noise = rng.uniform(-1, 1)
        filtered += (0.08 if slide else 0.28) * (noise - filtered)
        if slide:
            phase += math.tau * (190 * (0.3 ** u)) / RATE
            friction = filtered * (0.55 + 0.35 * math.sin(math.tau * (18 * t + 7 * t * t)))
            rubber = 0.18 * math.sin(phase + 1.2 * math.sin(math.tau * 19 * t))
            sample = (friction + rubber) * math.sin(math.pi * u) ** 0.65
        else:
            phase += math.tau * (60 + 190 * math.exp(-t * 35)) / RATE
            body = 0.75 * math.sin(phase) * math.exp(-t * 24)
            slap = filtered * 1.8 * math.exp(-t * 48)
            spray = filtered * 0.5 * math.exp(-t * 11)
            bubbles = 0.0
            for delay, frequency in [(0.025, 460), (0.055, 330), (0.10, 260), (0.16, 190)]:
                age = t - delay
                if age > 0:
                    angle = math.tau * frequency * (1 - math.exp(-age * 12)) / 12
                    bubbles += 0.28 * math.sin(angle) * math.exp(-age * 36) * min(1, age / 0.003)
            sample = body + slap + spray + bubbles
        edge = max(0, min(1, t / 0.003, (duration - t) / 0.035))
        samples.append(sample * edge)
    peak = 10 ** ((-15 if slide else -12) / 20)
    gain = peak / max(map(abs, samples))
    return [sample * gain for sample in samples]


def save(path: Path, samples: list[float]) -> None:
    """Write a mono PCM cue with sample-exact duration."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(s * 32767) for s in samples)))


def main() -> None:
    """Render versioned assets and preserve exact synthesis provenance."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    records = []
    for name, slide in [('screen-splat', False), ('screen-slide', True)]:
        samples = render(slide)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        records.append({'cue_id': name, 'path': str(path.relative_to(ROOT)),
                        'duration_seconds': len(samples) / RATE, 'gain_db': -3,
                        'peak_dbfs': -15 if slide else -12, 'loop': False,
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'version': 2, 'date': '2026-10-16', 'cues': records,
                'brief': 'Wet cartoon SPLAT, then short slide for X-eyed hero and fading blood trail.',
                'provenance': 'Original synthesis; no recordings, samples, voice models or external assets.',
                'rights': 'Project-generated audio; no third-party sample license requirements introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'seeds': {'screen-splat': 16101, 'screen-slide': 16102},
                'status': 'Candidate audio; technical checks only, not listening approved'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
