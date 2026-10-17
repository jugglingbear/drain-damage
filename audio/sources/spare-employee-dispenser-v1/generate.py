#!/usr/bin/env python3
"""Render original dispenser effects and a timing reference using only synthesized signals."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / 'assets/audio/sfx/spare-employee-dispenser-v1'
SOURCE = Path(__file__).resolve().parent
PEAK = 10 ** (-12 / 20)
# Name, duration, frequency sweep, noise blend, modulation, event time.
CUES = [
    ('scan-whirr', 0.38, 260, 540, 0.08, 18, 0.0),
    ('grab-servo', 0.30, 160, 95, 0.15, 32, 0.4),
    ('compression-squeak', 0.72, 310, 820, 0.12, 9, 0.66),
    ('flick-whoosh', 0.32, 560, 95, 0.82, 0, 1.4),
    ('screen-splat', 0.30, 155, 48, 0.65, 23, 1.76),
    ('screen-slide', 0.72, 210, 70, 0.42, 11, 2.1),
    ('vending-motor', 1.25, 105, 160, 0.20, 28, 2.15),
    ('vending-clunk', 0.20, 160, 62, 0.40, 0, 3.4),
    ('release-confirm', 0.30, 660, 990, 0.0, 0, 5.12),
    ('checkpoint-stamp', 0.22, 220, 130, 0.30, 0, 0.0),
]


def render(duration: float, start: float, end: float, noise: float, modulation: float, seed: int) -> list[float]:
    """Synthesize soft-edged tones and low-pass noise, with deterministic variation."""
    rng = random.Random(seed)
    phase = 0.0
    filtered = 0.0
    samples = []
    for index in range(round(duration * RATE)):
        time = index / RATE
        progress = time / duration
        frequency = start * (end / start) ** progress
        phase += math.tau * frequency / RATE
        filtered += 0.18 * (rng.uniform(-1, 1) - filtered)
        tone = math.sin(phase) + 0.22 * math.sin(phase * 2) + 0.08 * math.sin(phase * 3)
        envelope = min(1.0, time / 0.012, (duration - time) / 0.045)
        envelope *= math.sin(math.pi * progress) ** 0.45
        pulse = 0.8 + 0.2 * math.cos(math.tau * modulation * time)
        samples.append(((1 - noise) * tone + noise * filtered * 3) * envelope * pulse)
    scale = PEAK / max(abs(value) for value in samples)
    return [value * scale for value in samples]


def save(path: Path, samples: list[float]) -> None:
    """Write mono 16-bit PCM with no looping or leading delay."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(value * 32767) for value in samples)))


def main() -> None:
    """Generate immutable-version cues, provenance and a non-runtime sequence preview."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    preview = [0.0] * round(5.5 * RATE)
    records = []
    for index, (name, duration, start, end, noise, modulation, event_time) in enumerate(CUES):
        samples = render(duration, start, end, noise, modulation, 1600 + index)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        if name != 'checkpoint-stamp':
            offset = round(event_time * RATE)
            for position, value in enumerate(samples):
                preview[offset + position] += value
        records.append({
            'event': name, 'file': str(path.relative_to(ROOT)), 'duration_seconds': duration,
            'reference_start_seconds': event_time, 'suggested_player_gain_db': -3,
            'peak_dbfs': -12, 'rms_dbfs': round(20 * math.log10(
                math.sqrt(sum(value * value for value in samples) / len(samples))), 2),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'seed': 1600 + index,
        })
    assert max(abs(value) for value in preview) < 1.0
    save(SOURCE / 'sequence-reference-5.5s.wav', preview)
    metadata = {
        'id': 'spare-employee-dispenser-audio-v1', 'date': '2026-10-16',
        'status': 'synthesized_candidates_ready_for_integration_review_not_listening_approved',
        'provenance': 'Original procedural synthesis in adjacent generate.py. No recordings, samples or voice models.',
        'rights': 'Project-generated audio; no third-party sample licenses or attribution requirements introduced.',
        'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
        'generator': 'audio/sources/spare-employee-dispenser-v1/generate.py',
        'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'creative_brief': 'Cartoon machine, rubbery compression, flick, wet splat, slide, vending and release. '
                          'No gore, speech or BJ line. Soft attacks and short tails; retro synthetic palette.',
        'cues': records,
        'integration': {
            'full_sequence_target_seconds': 5.5, 'control_lock_hard_ceiling_seconds': 7,
            'trigger_policy': 'Animation events trigger cues; times are reference only. Never await audio end.',
            'skip_policy': 'Cancel queued cues; fade voices over 30ms on skip, scene exit or restart.',
            'concurrency': 'Separate one-shot voices allow slide and vending to overlap; no individual cue loops.',
            'respawn': [{'event': 'vending-motor', 'at': 0}, {'event': 'vending-clunk', 'at': 1.25},
                        {'event': 'release-confirm', 'at': 1.55}],
            'respawn_control_target_seconds': 2,
            'full_health': 'checkpoint-stamp only; release control within 0.5s; omit destruction cues.',
            'mix': 'Start each cue at -3dB player gain; rendered peaks -12dBFS. Respect SFX mute and music mix. '
                   'No loudness claim until in-game listening. Reference WAV is for audition only.',
        },
        'validation': 'PCM structure, finite samples, peaks, tail endpoints, hashes and reference duration checked. '
                      'Listening, animation sync and runtime integration pending.',
    }
    (SOURCE / 'manifest.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print('Generated 10 original cues and 5.5-second reference; peak:', max(abs(value) for value in preview))


if __name__ == '__main__':
    main()
