#!/usr/bin/env python3
"""Render original generic creature hunger and material-specific bite auditions."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
VOCALS = [
    ('Basement hunger', 'Low sustained growl with slow uneven pulses; lurking anticipation.', 2.5),
    ('Empty cavern', 'Hollow descending groan with broad vowel-like resonance.', 2.7),
    ('Teeth first', 'Three clipped guttural urges, rising toward a final snarl.', 1.8),
    ('Ravenous inhale', 'A rough inhaling swell followed by a short throaty release.', 2.2),
    ('Bottomless appetite', 'Deep irregular rumble with a bubbling throat texture.', 3.0),
    ('Mouth opening', 'A strained upward growl that expands into a large raspy roar.', 2.4),
]
MATERIALS = [
    ('wood', 'Splinter snap', 'A dry hard bite followed by scattered brittle wood-like cracks.', .55),
    ('wood', 'Beam crush', 'A deeper compressing crunch with several staggered breaks.', .80),
    ('porcelain', 'Ceramic bite', 'Sharp hollow fracture with brief bright fragments.', .48),
    ('porcelain', 'Basin crunch', 'A heavier ceramic crack followed by a granular fragment cascade.', .72),
    ('metal', 'Tin crumple', 'Thin metallic buckling with a short rattle.', .60),
    ('metal', 'Pipe bite', 'Low metal deformation followed by a strained ringing crunch.', .85),
]
BRIEF = ('Auditions only for an enormous insatiably hungry head lurking in shadows, opening an impossible mouth '
         'and leaping to eat hero/track. Six distinct imposing hunger/growl/groan/anticipation vocal candidates '
         'and two each wood, porcelain and metal biting/crunching sounds. Generic fictional creature, '
         'no imitation of any reference person, no dialogue, no playful character voice. Preserve all candidates.')


def vocal(number: int, duration: float) -> list[float]:
    """Synthesize an unvoiced/voiced creature texture without human samples or voice models."""
    rng = random.Random(261030 + number)
    values: list[float] = []
    phase = low = band = 0.0
    for index in range(round(RATE * duration)):
        time = index / RATE
        fraction = time / duration
        noise = rng.uniform(-1, 1)
        low += .018 * (noise - low)
        band += .16 * (noise - band)
        base = [58, 83, 105, 73, 43, 92][number]
        pitch = base * (1 + .04 * math.sin(math.tau * 4.7 * time))
        pitch *= (1.3 - .6 * fraction) if number == 1 else (1 + .6 * fraction if number == 5 else 1)
        phase += math.tau * pitch / RATE
        formant = [310, 560, 760, 450, 230, 650][number]
        throat = sum(math.sin(phase * harmonic + .35 * math.sin(phase * .51)) *
                     (.1 + math.exp(-((pitch * harmonic - formant) / 260) ** 2)) / harmonic
                     for harmonic in range(1, 17))
        growl = math.sin(phase * .5) * .35 + throat
        envelope = math.sin(math.pi * fraction) ** .65
        if number == 0:
            growl *= .65 + .35 * math.sin(math.tau * 2.3 * time) ** 2
            growl += low * 2
        elif number == 1:
            growl += .3 * math.sin(phase * 1.013)
        elif number == 2:
            envelope *= sum(math.exp(-((fraction - center) / .12) ** 2) for center in [.15, .48, .8])
            growl += band * .9
        elif number == 3:
            growl = growl * (.2 + fraction * .5) + (band - low) * (2.5 - 1.5 * fraction)
            envelope *= min(1, fraction * 3)
        elif number == 4:
            growl *= .4 + .6 * math.sin(math.tau * (3.2 * time + .3 * math.sin(time * 7))) ** 2
            growl += .25 * math.sin(phase + 2 * math.sin(phase * .31)) + low * 2
        else:
            growl += (band - low) * fraction * 2
            envelope *= .3 + .7 * fraction
        values.append(growl * envelope)
    return values


def crunch(number: int, duration: float) -> list[float]:
    """Layer finite resonances and staggered noise fractures for three distinct materials."""
    rng = random.Random(261060 + number)
    values = [0.0] * round(RATE * duration)
    material = number // 2
    heavy = number % 2
    for hit in range(8 if heavy else 5):
        at = 0.0 if hit == 0 else rng.uniform(.025, duration * .72)
        length = min(duration - at, .20 if material == 2 else .13)
        frequency = ([150, 780, 230][material]) * rng.uniform(.75, 1.4)
        gain = 1 if hit == 0 else rng.uniform(.15, .45)
        low = 0.0
        for index in range(round(length * RATE)):
            target = round(at * RATE) + index
            if target >= len(values):
                break
            age = index / RATE
            noise = rng.uniform(-1, 1)
            low += (.16 if material == 0 else .4) * (noise - low)
            phase = math.tau * frequency * age
            if material == 0:
                value = low * 1.3 + .25 * math.sin(phase) + .1 * math.sin(phase * 1.39)
            elif material == 1:
                value = noise * .4 + .4 * math.sin(phase) + .3 * math.sin(phase * 2.73)
            else:
                value = low * .5 + .4 * math.sin(phase + 1.2 * math.sin(phase * .63))
                value += .2 * math.sin(phase * 3.61)
            envelope = min(1, age / .0015) * math.exp(-age * (35 if material == 0 else 23))
            values[target] += value * gain * envelope
    return values


def main() -> None:
    """Write versioned descriptive source WAVs; permanent candidate copies follow ID coordination."""
    choices = []
    specs = [('vocal', *spec) for spec in VOCALS] + MATERIALS
    for index, (category, name, description, duration) in enumerate(specs):
        values = vocal(index, duration) if category == 'vocal' else crunch(index - 6, duration)
        for frame in range(len(values)):
            time = frame / RATE
            values[frame] *= min(1, time / .012, max(0, (duration - 1 / RATE - time) / .08))
        rms = math.sqrt(sum(v*v for v in values) / len(values))
        gain = min(10 ** (-23 / 20) / rms, 10 ** (-9 / 20) / max(map(abs, values)))
        pcm = [round(v * gain * 32767) for v in values]
        path = SOURCE / (name.lower().replace(' ', '-') + '.wav')
        payload = struct.pack('<' + 'h' * len(pcm), *pcm)
        if path.exists():
            with wave.open(str(path)) as existing:
                assert existing.readframes(existing.getnframes()) == payload, 'Preserve originals; version changes.'
        else:
            with wave.open(str(path), 'wb') as output:
                output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                output.writeframes(payload)
        choices.append({'name': name, 'description': description, 'category': category,
                        'path': str(path.relative_to(ROOT)), 'duration_seconds': duration, 'loop': False,
                        'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                        'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'date': '2026-10-26', 'choices': choices, 'generation_brief': BRIEF,
                'provenance': 'Original sample-free deterministic synthesis, no human/animal/material recordings, '
                'voice models or third-party samples. No person imitation or attribution obligations.',
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Audition only; recognition, realism and game mix await subjective review.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
