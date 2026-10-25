#!/usr/bin/env python3
"""Arrange the selected Air Running Out theme across the complete 45-second flush timeline."""

import hashlib
import json
import math
import random
import runpy
import struct
import subprocess
import wave
from pathlib import Path

RATE = 32000
DURATION = 45.0
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
RECIPE = ROOT / 'audio/sources/flush-countdown-auditions-v1/generate.py'
OUTPUT = ROOT / 'assets/audio/music/flush-air-running-out-v1.ogg'
PREVIEW = SOURCE / 'air-running-out-45s.wav'
MOTIF = [0, 6, 1, 8, 3, 7, 2, 6]
BRIEF = ('Expand selected DD-S0094.2 Air Running Out into a newly arranged 45-second cue, not slowed audio. '
         '0–8 quiet ticking/bass; 8–25 main figure accelerates; 25–35 add percussion/high notes; '
         '35–43 peak urgency during drain pull; 43–45 closing hit and fade at landing. '
         'Preserve original melody/timbres and all audition files. Original sample-free composition.')


def main() -> None:
    """Reuse preserved oscillator recipes, render a new score, and export a nonlooping Vorbis track."""
    voices = runpy.run_path(str(RECIPE))
    add_note = voices['add_note']
    drum = voices['drum']
    mix = [0.0] * round(RATE * DURATION)
    rng = random.Random(249401)
    at = 0.0
    step = 0
    phases = [(0, 8, 132, 140), (8, 25, 140, 178), (25, 35, 178, 208), (35, 43, 208, 226)]
    for start, end, initial, final in phases:
        # Start each phase on its visual transition, without carrying a late note trigger across it.
        at = float(start)
        while at < end:
            progress = (at - start) / (end - start)
            tempo = initial + (final - initial) * progress
            beat = 60 / tempo
            subdivision = beat / 2
            degree = MOTIF[step % len(MOTIF)]
            transpose = [0, 0, 1, -1][(step // 16) % 4]
            intro = start == 0
            strength = .55 if intro else .85 + .25 * (at - 8) / 35
            if not intro:
                add_note(mix, at, subdivision * .78, 78 + degree + transpose, .14 * strength, 'fm')
            if at >= 25 and step % 2 == 1:
                add_note(mix, at + subdivision / 2, subdivision * .38, 90 + degree, .065 * strength, 'fm')
            if step % 2 == 0:
                add_note(mix, at, beat * .65, 42 + (1 if step % 8 == 6 else 0), .19 * strength, 'bass')
                drum(mix, at, .18 * strength, 'kick', rng)
            drum(mix, at, .065 * strength, 'tick', rng)
            if not intro and step % 4 == 2:
                drum(mix, at, .11 * strength, 'snare', rng)
            if not intro and step % 8 == 0:
                for interval in (0, 6, 13):
                    add_note(mix, at, beat * 1.5, 66 + interval, .045 * strength, 'fm')
            if at >= 35 and step % 4 == 0:
                add_note(mix, at, beat * .8, 54, .075, 'fm')
            at += subdivision
            step += 1
    for interval in (0, 1, 6, 12):
        add_note(mix, 43, 1.85, 66 + interval, .11, 'fm')
    drum(mix, 43, .3, 'kick', rng)
    # A few soft descending echoes carry the resolution through the final two-second landing interval.
    for at, note, gain in [(43.35, 78, .055), (43.7, 73, .04), (44.05, 66, .025), (44.4, 54, .012)]:
        add_note(mix, at, min(.55, DURATION - at), note, gain, 'fm')
    delay = round(.085 * RATE)
    dry = mix[:]
    for index in range(delay, len(mix)):
        mix[index] += dry[index - delay] * .13
    for index in range(len(mix)):
        time = index / RATE
        mix[index] *= min(1, time / .012, max(0, (DURATION - 1 / RATE - time) / .6))
    rms = math.sqrt(sum(value * value for value in mix) / len(mix))
    gain = min(10 ** (-21 / 20) / rms, 10 ** (-3 / 20) / max(map(abs, mix)))
    pcm = [round(value * gain * 32767) for value in mix]
    payload = struct.pack('<' + 'h' * len(pcm), *pcm)
    if PREVIEW.exists():
        with wave.open(str(PREVIEW)) as existing:
            assert existing.readframes(existing.getnframes()) == payload, 'Preserve original; version changed score.'
    else:
        with wave.open(str(PREVIEW), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(payload)
    if not OUTPUT.exists():
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(PREVIEW), '-c:a', 'libvorbis', '-q:a', '6',
                        '-map_metadata', '-1', '-n', str(OUTPUT)], check=True)
    manifest = {'title': 'Air Running Out — full flush arrangement', 'selected_audition': 'DD-S0094.2',
                'duration_seconds': DURATION, 'loop': False, 'gain_db': -8,
                'preview': str(PREVIEW.relative_to(ROOT)), 'runtime': str(OUTPUT.relative_to(ROOT)),
                'preview_sha256': hashlib.sha256(PREVIEW.read_bytes()).hexdigest(),
                'runtime_sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
                'generation_brief': BRIEF, 'phases': phases, 'motif_semitones': MOTIF,
                'source_recipe': str(RECIPE.relative_to(ROOT)),
                'source_recipe_sha256': hashlib.sha256(RECIPE.read_bytes()).hexdigest(),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'provenance': 'Original deterministic composition and synthesis. Uses preserved original oscillator '
                'recipe from the approved audition; no borrowed melody, recordings or third-party samples.',
                'status': 'Approved direction; full arrangement supplied for Engineering integration/listening review.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
