#!/usr/bin/env python3
"""Compose five original accelerating tension cues, without borrowed melodies or samples."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
DURATION = 22.0
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'audio/alternatives/DD-S0094'
BRIEF = ('Five original intense/stressful music auditions for the pre-Level-2 flush sequence. '
         'Use accelerating countdown urgency, insistent rhythm and mounting tension inspired by the feeling '
         'of a classic platformer low-air warning; compose new motifs, harmony and timbres. '
         'No copied Sonic melody, recording or arrangement. Auditions only, no runtime change.')
SPECS = [
    ('Pressure Clock', 'Dry ticking, tight square-wave notes and a steadily accelerating bass pulse.',
     118, 212, 50, 'pulse', [0, 1, 7, 6, 0, 10, 3, 1]),
    ('Air Running Out', 'Bright metallic synth alarms over a galloping bass; sharper and more arcade-like.',
     132, 226, 54, 'fm', [0, 6, 1, 8, 3, 7, 2, 6]),
    ('Porcelain Panic', 'Low industrial knocks, clipped chords and an increasingly frantic upper line.',
     104, 196, 43, 'metal', [0, 3, 1, 6, 0, 7, 4, 1]),
    ('Last Breath', 'Trembling string-like clusters and a heartbeat that grows into a rapid chase rhythm.',
     96, 192, 47, 'strings', [0, 2, 3, 8, 7, 1, 6, 3]),
    ('Drain Spiral', 'Bubbling electronic arpeggios climb above a pounding pulse and an unstable repeating figure.',
     126, 222, 48, 'bubble', [0, 7, 1, 6, 3, 10, 4, 8]),
]


def add_note(mix: list[float], at: float, duration: float, midi: float, gain: float, kind: str) -> None:
    """Add one enveloped original oscillator voice with optional synthetic metallic modulation."""
    offset = round(at * RATE)
    frequency = 440 * 2 ** ((midi - 69) / 12)
    for index in range(min(round(duration * RATE), len(mix) - offset)):
        time = index / RATE
        phase = math.tau * frequency * time
        if kind == 'pulse':
            value = sum(math.sin(phase * harmonic) / harmonic for harmonic in (1, 3, 5)) * .65
        elif kind == 'fm':
            value = math.sin(phase + 2.1 * math.exp(-time * 15) * math.sin(phase * 2))
        elif kind == 'metal':
            value = .6 * math.sin(phase) + .25 * math.sin(phase * 2.76) + .15 * math.sin(phase * 4.13)
        elif kind == 'strings':
            value = sum(math.sin(phase * h) / h for h in (1, 2, 3, 4)) * .5
            value *= .78 + .22 * math.sin(math.tau * 12 * time)
        elif kind == 'bubble':
            value = math.sin(phase + 1.2 * math.exp(-time * 22) * math.sin(phase * .5))
        else:
            value = math.sin(phase) + .2 * math.sin(phase * 2)
        envelope = min(1, time / .004, max(0, (duration - time) / .025))
        envelope *= math.exp(-time * (2 if kind == 'strings' else 7))
        mix[offset + index] += value * gain * envelope


def drum(mix: list[float], at: float, gain: float, kind: str, rng: random.Random) -> None:
    """Add a short synthesized tick, kick or noisy snare without external percussion samples."""
    duration = .13 if kind != 'tick' else .035
    offset = round(at * RATE)
    phase = low = 0.0
    for index in range(min(round(duration * RATE), len(mix) - offset)):
        time = index / RATE
        noise = rng.uniform(-1, 1)
        low += .18 * (noise - low)
        if kind == 'kick':
            phase += math.tau * (50 + 100 * math.exp(-time * 55)) / RATE
            value = math.sin(phase) * math.exp(-time * 28)
        else:
            value = (noise - low) * math.exp(-time * (130 if kind == 'tick' else 32))
        envelope = min(1, time / .001, max(0, (duration - time) / .01))
        mix[offset + index] += value * gain * envelope


def compose(number: int) -> list[float]:
    """Build a 20-second accelerando followed by an original two-second closing sting."""
    _, _, initial, final, root, kind, motif = SPECS[number]
    mix = [0.0] * round(DURATION * RATE)
    rng = random.Random(249400 + number)
    at = 0.0
    step = 0
    while at < 20:
        progress = at / 20
        tempo = initial + (final - initial) * progress
        beat = 60 / tempo
        subdivision = beat / 2
        degree = motif[step % len(motif)]
        transposition = [0, 0, 1, -1][(step // 16) % 4]
        gain = .10 + .05 * progress
        add_note(mix, at, subdivision * .78, root + 24 + degree + transposition, gain, kind)
        if progress > .55 and step % 2 == 1:
            add_note(mix, at + subdivision / 2, subdivision * .38, root + 36 + degree, gain * .42, kind)
        if step % 2 == 0:
            bass = root - 12 + (1 if step % 8 == 6 else 0)
            add_note(mix, at, beat * .65, bass, .19, 'bass')
            drum(mix, at, .16 + .04 * progress, 'kick', rng)
        drum(mix, at, .04 + .04 * progress, 'tick', rng)
        if step % 4 == 2:
            drum(mix, at, .08 + .04 * progress, 'snare', rng)
        if step % 8 == 0:
            for interval in (0, 6, 13):
                add_note(mix, at, beat * 1.5, root + 12 + interval, .045, kind)
        at += subdivision
        step += 1
    for interval in (0, 1, 6, 12):
        add_note(mix, 20, 1.85, root + 12 + interval, .10, kind)
    drum(mix, 20, .3, 'kick', rng)
    # A quiet short echo gives space while keeping the accelerating note attacks distinct.
    delay = round(.085 * RATE)
    dry = mix[:]
    for index in range(delay, len(mix)):
        mix[index] += dry[index - delay] * .13
    for index in range(len(mix)):
        time = index / RATE
        mix[index] *= min(1, time / .012, max(0, (DURATION - 1 / RATE - time) / .6))
    rms = math.sqrt(sum(v*v for v in mix) / len(mix))
    gain = min(10 ** (-21 / 20) / rms, 10 ** (-3 / 20) / max(map(abs, mix)))
    return [value * gain for value in mix]


def main() -> None:
    """Write immutable numbered PCM candidates and full composition/provenance metadata."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    choices = []
    for number, (name, description, initial, final, root, kind, motif) in enumerate(SPECS):
        identity = f'DD-S0094.{number + 1}'
        pcm = [round(v * 32767) for v in compose(number)]
        payload = struct.pack('<' + 'h' * len(pcm), *pcm)
        path = OUTPUT / (identity + '.wav')
        if path.exists():
            with wave.open(str(path)) as existing:
                assert existing.readframes(existing.getnframes()) == payload, 'Preserve original; use next suffix.'
        else:
            with wave.open(str(path), 'wb') as output:
                output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                output.writeframes(payload)
        choices.append({'id': identity, 'name': name, 'description': description,
                        'path': str(path.relative_to(ROOT)), 'duration_seconds': DURATION,
                        'tempo_bpm': [initial, final], 'acceleration_seconds': 20, 'ending_seconds': 2,
                        'root_midi': root, 'timbre': kind, 'original_motif_semitones': motif,
                        'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                        'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'generation_brief': BRIEF, 'choices': choices, 'format': '32000 Hz mono PCM16 WAV',
                'provenance': 'Original sample-free composition and synthesis; no borrowed melody, recording, '
                'soundfonts, voice models or third-party samples. No third-party sample attribution obligations.',
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Auditions only; no runtime mapping or looping. Timing may be adapted after selection.',
                'limitations': 'Signal QA only; perceived urgency, musical quality and game mix need listening review.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
