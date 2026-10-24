#!/usr/bin/env python3
"""Render an original festering-swamp score and nonverbal pressure roars without samples."""

import hashlib
import json
import math
import random
import struct
import subprocess
import wave
from array import array
from pathlib import Path

RATE = 32000
DURATION = 48.0
FRAMES = round(RATE * DURATION)
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
MUSIC = ROOT / 'assets/audio/music/clogfather-festering-v3.ogg'
SFX = ROOT / 'assets/audio/sfx/clogfather-festering-v3'
SEED = 96023


def mix_at(target: array, values: array, offset: float, gain: float) -> None:
    """Circularly accumulate tails so the score has no terminal fade or truncated echo."""
    start = round(offset * RATE)
    for index, value in enumerate(values):
        target[(start + index) % len(target)] += gain * value


def wet_grain(duration: float, frequency: float, seed: int, roar: bool = False) -> array:
    """Synthesize damp resonances, filtered noise and irregular glottal pressure pulses."""
    rng = random.Random(seed)
    values = array('f')
    low = phase = 0.0
    for index in range(round(duration * RATE)):
        time = index / RATE
        fraction = time / duration
        low += .065 * (rng.uniform(-1, 1) - low)
        pitch = frequency * (1.35 - .65 * fraction) * (1 + .045 * math.sin(math.tau * 17 * time))
        phase += math.tau * pitch / RATE
        if roar:
            voice = sum(math.sin(phase * h) / h ** 1.35 for h in range(1, 8))
            value = (.72 * voice + 1.8 * low) * (.65 + .35 * math.sin(math.tau * 21 * time) ** 2)
            envelope = math.sin(math.pi * fraction) ** .65
        else:
            value = math.sin(phase + 1.8 * math.sin(phase * .47)) + 2.5 * low
            envelope = math.sin(math.pi * fraction) ** 2 * math.exp(-fraction * 3)
        edge = max(0, min(1, time / .012, (duration - 1 / RATE - time) / .06))
        values.append(value * envelope * edge)
    return values


def save(path: Path, values: array, peak_db: float) -> dict[str, object]:
    """Write peak-bounded mono PCM and measured content metadata."""
    peak = max(map(abs, values))
    scale = 32767 * 10 ** (peak_db / 20) / peak
    pcm = [round(value * scale) for value in values]
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    rms = math.sqrt(sum(v * v for v in pcm) / len(pcm)) / 32767
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(pcm) / RATE,
            'peak_dbfs': peak_db, 'rms_dbfs': round(20 * math.log10(rms), 2),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'boundary_step_pcm': abs(pcm[-1] - pcm[0]),
            'max_internal_step_pcm': max(abs(pcm[i] - pcm[i-1]) for i in range(1, len(pcm)))}


def main() -> None:
    """Compose slow pressure cycles, unstable low clusters, bubbling and two bounded roar variants."""
    rng = random.Random(SEED)
    mix = array('f', [0]) * FRAMES
    # Integer-cycle tones and modulation preserve exact48s periodicity, without a jaunty lead melody.
    for index in range(FRAMES):
        time = index / RATE
        pressure = .55 + .25 * math.sin(math.tau * time / 12) + .2 * math.sin(math.tau * time / 48)
        drone = sum(math.sin(math.tau * frequency * time + .35 * math.sin(math.tau * time / 6)) * gain
                    for frequency, gain in [(36.75, .14), (55, .12), (58.25, .065), (77.75, .045), (110, .025)])
        scrape = math.sin(math.tau * 311 * time + 2 * math.sin(math.tau * time / 8))
        scrape *= .018 * (.5 + .5 * math.sin(math.tau * time / 24))
        mix[index] = drone * pressure + scrape
    for index in range(128):
        start = rng.uniform(0, DURATION)
        grain = wet_grain(rng.uniform(.09, .42), rng.uniform(120, 520), SEED + index)
        mix_at(mix, grain, start, rng.uniform(.025, .085))
    for index in range(32):
        # Slow uneven thumps and sucking answers create menace rather than dance syncopation.
        mix_at(mix, wet_grain(.65, 48, SEED + 200 + index), index * 1.5, .22)
        if index % 4 in [1, 3]:
            mix_at(mix, wet_grain(1.3, 82, SEED + 300 + index), index * 1.5 + .7, .075)
    for index in range(8):
        mix_at(mix, wet_grain(3.2, 43 + index % 3 * 4, SEED + 500 + index, True), index * 6 + 2, .035)
    wet = array('f', mix)
    for delay, gain in [(.23, .14), (.61, .08)]:
        offset = round(delay * RATE)
        for index in range(FRAMES):
            wet[index] += mix[(index - offset) % FRAMES] * gain
    music = save(SOURCE / 'preview.wav', array('f', (math.tanh(v * 2) for v in wet)), -3)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(ROOT / str(music['path'])),
                    '-c:a', 'libvorbis', '-q:a', '6', str(MUSIC)], check=True)
    cues = []
    for name, duration, frequency, seed in [('ambient-roar', 1.65, 62, SEED + 900),
                                            ('reactive-roar', 1.25, 85, SEED + 901)]:
        cue = save(SFX / (name + '.wav'), wet_grain(duration, frequency, seed, True), -15)
        cue.update(cue_id=name, gain_db=-8 if name == 'ambient-roar' else -6, loop=False)
        cues.append(cue)
    manifest = {'schema_version': 1, 'title': 'Clogfather — Festering Pressure', 'date': '2026-10-23',
                'duration_seconds': DURATION, 'pulse_bpm': 80, 'loop': True, 'seed': SEED,
                'runtime': str(MUSIC.relative_to(ROOT)),
                'runtime_sha256': hashlib.sha256(MUSIC.read_bytes()).hexdigest(),
                'preview': music, 'cues': cues, 'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'provenance': 'Original deterministic sample-free composition/synthesis; no recordings, voices, '
                              'soundfonts, borrowed melodies or third-party samples.',
                'production': 'Low beating clusters, pressure pulses, irregular wet resonances, scraping drone and '
                              'filtered bubbling. Roars are synthetic pressure, not human or animal voices.',
                'loop_method': 'Periodic oscillators/modulation, wrapped grain tails and echoes; no end fade.',
                'generator': str(Path(__file__).resolve().relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Rendered candidate; mix analysis/runtime tests/listening pending.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
