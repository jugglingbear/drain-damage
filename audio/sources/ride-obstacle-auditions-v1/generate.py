#!/usr/bin/env python3
"""Generate original synthetic movement/contact auditions for the ten-obstacle ride prototype."""

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
FAMILIES = [
    ('DD-S0098', 'Metal impact', 'Impact: valve01v2, elbow02, flange05, cap07, spike grate09v2.',
     [('Damped pipe knock', .32), ('Bright grate clang', .55)]),
    ('DD-S0099', 'Porcelain contact', 'Landing/impact: broken basin08; porcelain facing if present on cap07.',
     [('Solid ceramic clack', .28), ('Hollow basin knock', .45)]),
    ('DD-S0100', 'Soft contact', 'Impact: rubber plug03, brush curtain04, float body06.',
     [('Rubber cup thump', .30), ('Bristle scrape', .48)]),
    ('DD-S0101', 'Float-arm movement', 'Movement: float06 sweep start; chain03 only if moving (future option).',
     [('Short hinge creak', .65), ('Chain and hinge rattle', .80)]),
    ('DD-S0102', 'Flume launch', 'Movement: successful ramp10 launch; existing approved wet landing remains available.',
     [('Rising water rush', .70), ('Gushing launch pulse', .85)]),
]
BRIEF = ('Audition proposals for ride obstacles: two distinct options per shared material/event family. '
         'Metal and porcelain contacts, soft rubber/bristle impacts, moving float hinge, water flume launch. '
         'Original synthetic effects with clear movement versus impact labels. No runtime integration '
         'before Sean selects. Static valve01v2 and spike grate09v2 do not get invented movement sounds.')


def render(family: int, variant: int, duration: float) -> list[int]:
    """Layer original resonances, filtered noise and envelopes without external recordings."""
    rng = random.Random(261060 + family * 10 + variant)
    low = band = phase = 0.0
    values: list[float] = []
    for index in range(round(RATE * duration)):
        time = index / RATE
        fraction = time / duration
        noise = rng.uniform(-1, 1)
        low += .025 * (noise - low)
        band += .2 * (noise - band)
        if family in (0, 1):
            base = ([190, 370] if family == 0 else [780, 420])[variant]
            ratios = [1, 2.71, 4.13, 5.39] if family == 0 else [1, 1.57, 2.38, 3.17]
            decay = (18 if variant == 0 else 9) if family == 0 else (24 if variant == 0 else 13)
            value = sum(math.sin(math.tau * base * ratio * time) * math.exp(-time * decay * (1 + n * .4))
                        / (n + 1) for n, ratio in enumerate(ratios))
            value += band * .6 * math.exp(-time * 70)
        elif family == 2:
            if variant == 0:
                phase += math.tau * (100 + 160 * math.exp(-time * 28)) / RATE
                value = math.sin(phase) * math.exp(-time * 18) + .15 * band * math.exp(-time * 22)
            else:
                value = (noise - band) * math.sin(math.pi * fraction) ** .7
                value *= .5 + .5 * math.sin(math.tau * 32 * time) ** 2
        elif family == 3:
            phase += math.tau * (180 + 110 * math.sin(math.pi * fraction)) / RATE
            value = math.sin(phase + 1.4 * math.sin(phase * 2)) * .22
            value *= (.3 + .7 * math.sin(math.tau * 19 * time) ** 2) * math.sin(math.pi * fraction)
            if variant == 1:
                value *= .45
                for at in [.05, .14, .29, .43, .61]:
                    age = time - at
                    if age >= 0:
                        value += .2 * (math.sin(math.tau * 1450 * age)
                                       + .5 * math.sin(math.tau * 3510 * age)) * math.exp(-age * 55)
        else:
            envelope = math.sin(math.pi * fraction) ** (.8 if variant == 0 else .5)
            value = ((band - low) * .8 + low * .7) * envelope
            value *= .7 + .3 * fraction if variant == 0 else .75 + .25 * math.sin(math.tau * 13 * time)
            phase += math.tau * (170 + 370 * fraction) / RATE
            value += .045 * math.sin(phase + .7 * math.sin(phase * 1.5)) * envelope
        value *= min(1, time / .003, max(0, (duration - 1 / RATE - time) / .035))
        values.append(value)
    rms = math.sqrt(sum(v*v for v in values) / len(values))
    gain = min(10 ** (-24 / 20) / rms, 10 ** (-10 / 20) / max(map(abs, values)))
    return [round(v * gain * 32767) for v in values]


def main() -> None:
    """Preserve numbered PCM candidates with exact source and signal metadata."""
    choices = []
    for family, (slot, title, use, variants) in enumerate(FAMILIES):
        folder = ROOT / 'audio/alternatives' / slot
        folder.mkdir(parents=True, exist_ok=True)
        for variant, (name, duration) in enumerate(variants):
            identity = f'{slot}.{variant + 1}'
            path = folder / (identity + '.wav')
            pcm = render(family, variant, duration)
            payload = struct.pack('<' + 'h' * len(pcm), *pcm)
            if path.exists():
                with wave.open(str(path)) as existing:
                    assert existing.readframes(existing.getnframes()) == payload, 'Keep originals; use next suffix.'
            else:
                with wave.open(str(path), 'wb') as output:
                    output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                    output.writeframes(payload)
            choices.append({'id': identity, 'slot': slot, 'family': title, 'name': name, 'intended_use': use,
                            'path': str(path.relative_to(ROOT)), 'duration_seconds': duration, 'loop': False,
                            'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                            'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'date': '2026-10-26', 'choices': choices, 'generation_brief': BRIEF,
                'provenance': 'Original deterministic sample-free synthesis, not material recordings. '
                'No external samples, soundfonts, voice models or third-party attribution obligations.',
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Proposed auditions only; none selected or integrated.',
                'limitations': 'No subjective listening; material recognition and mix remain unverified.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
