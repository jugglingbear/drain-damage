#!/usr/bin/env python3
"""Compose original Clogfather audio using deterministic, sample-free synthesis."""

import hashlib
import json
import math
import random
import struct
import wave
from array import array
from pathlib import Path

RATE = 32000
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
SFX = ROOT / 'assets/audio/sfx/clogfather-v1'
BEAT = 0.4
BARS = 32
DURATION = BARS * BEAT * 4
SPECS = [
    ('pressure-warning', 0.72, 80, 230, 0.32),
    ('sludge-fire-a', 0.24, 220, 48, 0.50),
    ('sludge-fire-b', 0.27, 190, 42, 0.55),
    ('sludge-impact-a', 0.34, 160, 35, 0.72),
    ('sludge-impact-b', 0.38, 135, 40, 0.65),
    ('groan-a', 1.15, 67, 48, 0.06),
    ('groan-b', 0.95, 59, 76, 0.08),
    ('hurt', 0.42, 95, 60, 0.16),
    ('weak-point-open', 0.48, 330, 550, 0.24),
    ('armored-hit', 0.16, 490, 230, 0.30),
    ('acid-warning', 0.85, 620, 850, 0.80),
    ('collapse', 1.8, 100, 24, 0.60),
]


def save(path: Path, samples: list[float] | array, peak_db: float) -> dict:
    """Write normalized mono PCM and return measured metadata."""
    gain = 10 ** (peak_db / 20) / max(map(abs, samples))
    pcm = [round(s * gain * 32767) for s in samples]
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(pcm) / RATE,
            'peak_dbfs': peak_db, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def effect(duration: float, start: float, end: float, noise: float, seed: int) -> list[float]:
    """Combine pressure resonances, flutter and clustered liquid-like transients."""
    rng = random.Random(seed)
    phase = 0.0
    filtered = 0.0
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        u = t / duration
        frequency = start * (end / start) ** u * (1 + .035 * math.sin(math.tau * 7 * t))
        phase += math.tau * frequency / RATE
        filtered += .16 * (rng.uniform(-1, 1) - filtered)
        voice = sum(math.sin(phase * k) / k ** 1.2 for k in range(1, 7))
        wet = math.sin(phase * 3 + 2.5 * math.sin(math.tau * 23 * t))
        envelope = math.sin(math.pi * u) ** (0.5 if duration > .7 else 1.1)
        edge = max(0, min(1, t / .008, (duration - t) / .04))
        pulse = .65 + .35 * math.sin(math.tau * 13 * t) ** 2
        samples.append(((1-noise) * (voice + .15 * wet) + noise * filtered * 4) * envelope * edge * pulse)
    return samples


def add_note(mix: array, at: float, length: float, midi: int, level: float, kind: str) -> None:
    """Add an enveloped instrument; wrap tails across the loop seam."""
    frequency = 440 * 2 ** ((midi - 69) / 12)
    offset = round(at * RATE)
    for index in range(round(length * RATE)):
        t = index / RATE
        phase = math.tau * frequency * t
        edge = max(0, min(1, t / .006, (length-t) / .025))
        if kind == 'bass':
            tone = math.sin(phase + .7 * math.sin(phase * 2)) + .2 * math.sin(phase * 3)
            envelope = math.exp(-t * 5)
        elif kind == 'pipe':
            tone = math.sin(phase) + .32 * math.sin(phase * 2.76) + .14 * math.sin(phase * 5.4)
            envelope = math.exp(-t * 13)
        else:
            tone = math.sin(phase) + .3 * math.sin(phase * 2) + .18 * math.sin(phase * 4)
            envelope = .75 + .25 * math.sin(math.tau * 5 * t)
        mix[(offset+index) % len(mix)] += level * tone * envelope * edge


def music() -> array:
    """Compose a 32-bar sewer shuffle with bass, pipe melody, organ and compact drums."""
    mix = array('f', [0]) * round(DURATION * RATE)
    roots = [38, 38, 39, 38, 34, 34, 37, 33]
    motif = [62, 65, 63, 62, 56, 57, 60, 63]
    rng = random.Random(43016)
    for bar in range(BARS):
        origin = bar * 4 * BEAT
        root = roots[bar % 8]
        for step, delta in [(0, 0), (.75, 12), (1.5, 0), (2, 7), (2.75, 0), (3.5, 1)]:
            add_note(mix, origin + step * BEAT, .24, root + delta, .25, 'bass')
        if bar % 4 in [0, 2]:
            for delta in [0, 7, 13]:
                add_note(mix, origin, .65, root + 24 + delta, .045, 'organ')
        for step in range(4):
            midi = motif[(bar * 2 + step) % len(motif)] + (12 if 16 <= bar < 24 else 0)
            add_note(mix, origin + (step + .5) * BEAT, .23, midi, .11, 'pipe')
        for step in range(8):
            at = origin + step * BEAT / 2
            offset = round(at * RATE)
            filtered = 0.0
            for index in range(round(.15 * RATE)):
                t = index / RATE
                noise = rng.uniform(-1, 1)
                filtered += .12 * (noise - filtered)
                hat = (noise-filtered) * math.exp(-t * 80) * .025
                kick = math.sin(math.tau * (48*t + 1.4*(1-math.exp(-t*35)))) * math.exp(-t*28)
                snare = (filtered * 1.3 + math.sin(math.tau*170*t)*.14) * math.exp(-t*32)
                hit = .20*kick if step in [0, 4, 7] else .18*snare if step in [2, 6] else 0
                edge = min(1, t/.002, (.15-t)/.01)
                mix[(offset+index) % len(mix)] += (hat+hit)*edge
    # A short circular echo suggests enclosed pipes without a silent gap at the loop boundary.
    dry = array('f', mix)
    delay = round(.1875 * RATE)
    for index in range(len(mix)):
        mix[index] += dry[(index-delay) % len(mix)] * .16
    return mix


def main() -> None:
    """Render versioned source audio and exact synthesis provenance."""
    SFX.mkdir(parents=True, exist_ok=True)
    cues = []
    for index, (name, duration, start, end, noise) in enumerate(SPECS):
        peak = -15 if 'impact' in name or name == 'armored-hit' else -12
        record = save(SFX / (name + '.wav'), effect(duration, start, end, noise, 43100+index), peak)
        record.update({'cue_id': name, 'gain_db': -5, 'loop': False, 'seed': 43100+index})
        cues.append(record)
    track = save(SOURCE / 'backpressure-boss-original-v1.wav', music(), -6)
    manifest = {'schema_version': 1, 'date': '2026-10-16', 'cues': cues, 'music_source': track,
                'music_title': 'Backpressure', 'bpm': 150, 'bars': BARS, 'meter': '4/4',
                'composition': 'Original Phrygian bass/pipe motif, organ, syncopated drums and pipe echo.',
                'format': {'sample_rate': RATE, 'channels': 1, 'bits': 16},
                'provenance': 'Original deterministic procedural composition and synthesis. No third-party samples.',
                'rights': 'Project-generated material; no third-party sample licensing obligations introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'First-pass original audio; subjective listening and runtime sync pending'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
