#!/usr/bin/env python3
"""Compose an original theatrical Italian-inspired battle loop with sample-free synthesis."""

import hashlib
import json
import math
import random
import struct
import subprocess
import wave
from array import array
from functools import lru_cache
from pathlib import Path

RATE = 32000
BPM = 160
BEAT = 60 / BPM
BARS = 32
DURATION = BARS * 4 * BEAT
FRAMES = round(RATE * DURATION)
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/music/clogfather-italian-battle-v2.ogg'
# New eight-bar melody: syncopated rising figures and alternating descending answers.
MELODY = [
    [(0, 74, .5), (.75, 77, .5), (1.5, 76, .5), (2.25, 81, .5), (3, 77, .75)],
    [(0, 76, .75), (1, 73, .5), (1.75, 76, .5), (2.5, 79, .5), (3.25, 76, .5)],
    [(0, 77, .5), (.5, 81, .75), (1.5, 79, .5), (2.25, 77, .5), (3, 74, .75)],
    [(0, 79, .75), (1, 76, .5), (2, 73, .5), (2.75, 71, .5), (3.5, 73, .25)],
    [(0, 74, .75), (1, 77, .5), (1.75, 82, .5), (2.5, 81, .5), (3.25, 77, .5)],
    [(0, 79, .5), (.75, 82, .5), (1.5, 81, .75), (2.5, 79, .5), (3.25, 76, .5)],
    [(0, 77, .5), (.75, 74, .5), (1.5, 76, .5), (2.25, 73, .5), (3, 76, .75)],
    [(0, 73, .5), (.75, 76, .5), (1.5, 81, .5), (2.25, 79, .5), (3, 73, .75)],
]
CHORDS = [(50, 57, 62, 65), (45, 57, 61, 64), (46, 58, 62, 65), (45, 57, 61, 64),
          (43, 55, 58, 62), (48, 60, 64, 67), (50, 57, 62, 65), (45, 57, 61, 64)]


@lru_cache(maxsize=None)
def voice(kind: str, midi: int, beats: float) -> array:
    """Render a harmonic instrument approximation with finite click-free release."""
    duration = beats * BEAT
    tail = .12 if kind == 'pluck' else .08
    count = round((duration + tail) * RATE)
    frequency = 440 * 2 ** ((midi - 69) / 12)
    result = array('f')
    for index in range(count):
        time = index / RATE
        phase = math.tau * frequency * time
        release = max(0, min(1, (duration + tail - time) / tail))
        if kind == 'pluck':
            value = sum(math.sin(phase * h) * math.exp(-time * (8 + h * 3)) / h for h in range(1, 6))
            envelope = min(1, time / .002) * release
        elif kind == 'reed':
            value = sum((math.sin(phase * h) + .32 * math.sin(phase * h * 1.003)) / h ** 1.5
                        for h in range(1, 6))
            envelope = min(1, time / .025) * release * (.9 + .1 * math.sin(math.tau * 5 * time))
        else:
            value = math.sin(phase) + .35 * math.sin(phase * 2) + .16 * math.sin(phase * 3)
            envelope = min(1, time / .015) * release * math.exp(-time * 1.8)
        result.append(value * envelope)
    return result


def add(mix: array, values: array, at: float, gain: float) -> None:
    """Wrap all note tails around the loop instead of truncating its last bar."""
    start = round(at * RATE)
    for index, value in enumerate(values):
        mix[(start + index) % FRAMES] += value * gain


def drum(kind: str, seed: int) -> array:
    """Generate original kick, snare or tambourine-like noise without samples."""
    rng = random.Random(seed)
    result = array('f')
    duration = .22 if kind != 'hat' else .055
    for index in range(round(duration * RATE)):
        time = index / RATE
        edge = min(1, time / .001) * min(1, (duration - time) / .015)
        noise = rng.uniform(-1, 1)
        if kind == 'kick':
            value = math.sin(math.tau * (54 * time + 2.3 * (1 - math.exp(-time * 32))))
            value *= math.exp(-time * 20)
        elif kind == 'snare':
            value = (.7 * noise + .3 * math.sin(math.tau * 185 * time)) * math.exp(-time * 24)
        else:
            value = noise * math.exp(-time * 70)
        result.append(value * edge)
    return result


def main() -> None:
    """Render a complete circular arrangement, PCM preview, Vorbis loop and source manifest."""
    mix = array('f', [0]) * FRAMES
    kick, snare, hat = drum('kick', 9231), drum('snare', 9232), drum('hat', 9233)
    for bar in range(BARS):
        at = bar * 4 * BEAT
        chord = CHORDS[bar % 8]
        section = bar // 8
        for beat in [0, 2, 3.5]:
            add(mix, voice('brass', chord[0] - 12, .65), at + beat * BEAT, .21)
            add(mix, kick, at + beat * BEAT, .28)
        for beat in [.5, 1.5, 2.5, 3.5]:
            for note in chord[1:]:
                add(mix, voice('reed', note, .42), at + beat * BEAT, .075)
        for beat in [1, 3]:
            add(mix, snare, at + beat * BEAT, .14)
        for tick in range(8):
            add(mix, hat, at + tick * .5 * BEAT, .065 if tick % 2 else .045)
        for beat, note, length in MELODY[bar % 8]:
            # Repeated plucks supply the mandolin-like tremolo; octave lift changes the final chorus.
            pitch = note + (12 if section == 3 else 0)
            for pulse in range(max(1, round(length * 4))):
                add(mix, voice('pluck', pitch, .25), at + (beat + pulse * .25) * BEAT, .25)
            if section in [1, 2]:
                add(mix, voice('reed', note - 12, length), at + beat * BEAT, .095)
        if section >= 2:
            for note in chord[1:]:
                add(mix, voice('brass', note - 12, 1.5), at, .06)
    # Circular short room echoes preserve the transition from the last bar to the first.
    wet = array('f', mix)
    for delay, gain in [(.09375, .12), (.1875, .07)]:
        offset = round(delay * RATE)
        for index in range(FRAMES):
            wet[index] += mix[(index - offset) % FRAMES] * gain
    compressed = [math.tanh(value * 1.7) for value in wet]
    scale = 32767 * 10 ** (-2 / 20) / max(map(abs, compressed))
    pcm = [round(value * scale) for value in compressed]
    preview = SOURCE / 'italian-battle-v2-preview.wav'
    with wave.open(str(preview), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(preview), '-c:a', 'libvorbis',
                    '-q:a', '6', str(OUTPUT)], check=True)
    manifest = {'schema_version': 1, 'title': 'Clogfather — Pressure Tarantella', 'date': '2026-10-23',
                'bpm': BPM, 'bars': BARS, 'duration_seconds': DURATION, 'loop': True,
                'runtime': str(OUTPUT.relative_to(ROOT)), 'preview': str(preview.relative_to(ROOT)),
                'format': {'sample_rate': RATE, 'channels': 1, 'source_pcm_bits': 16, 'runtime_codec': 'Vorbis q6'},
                'provenance': 'Original composition and deterministic sample-free synthesis; no borrowed melody, '
                              'recordings, soundfonts or third-party instrument samples.',
                'production': 'Synthetic mandolin-like tremolo, reed/accordion-like chords, low brass-like support, '
                              'kick/snare/tambourine-like percussion. Instrument approximations, not recordings.',
                'composition': 'New eight-bar syncopated D-minor/harmonic-minor motif, four arranged sections, '
                               'dominant final bar resolving into first tonic. No Godfather theme reference.',
                'loop_method': 'Integer bars/beats, circular note tails and room echoes; no fade-to-silence seam.',
                'generator': str(Path(__file__).resolve().relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'runtime_sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
                'preview_sha256': hashlib.sha256(preview.read_bytes()).hexdigest(),
                'pcm_boundary_step': abs(pcm[-1] - pcm[0]),
                'pcm_max_internal_step': max(abs(pcm[i] - pcm[i-1]) for i in range(1, len(pcm))),
                'status': 'Original loop rendered; see analysis.json for mix contract. Not auditioned.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
