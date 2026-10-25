#!/usr/bin/env python3
"""Create original sample-free Level Two flush cues with reproducible provenance."""

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
OUTPUT = ROOT / 'assets/audio/sfx/level-two-flush-v1'
SPECS = [
    ('current-loop', 4.0, -18, -10, True),
    ('flush-onset', 1.2, -12, -6, False),
    ('flush-surge', 3.0, -14, -8, False),
    ('debris-impact', .32, -12, -6, False),
    ('debris-break', .48, -14, -6, False),
    ('radio-chirp', .13, -18, -4, False),
]


def synth(name: str, duration: float) -> list[float]:
    """Layer filtered turbulence and damped resonances; circularize the current bed."""
    rng = random.Random(24000 + sum(map(ord, name)))
    length = round(duration * RATE)
    looping = name == 'current-loop'
    overlap = RATE // 2 if looping else 0
    values: list[float] = []
    low = band = 0.0
    for index in range(length + overlap):
        time = index / RATE
        fraction = min(1, time / duration)
        noise = rng.uniform(-1, 1)
        low += .012 * (noise - low)
        band += .16 * (noise - band)
        water = .6 * low + .24 * (band - low)
        bubble = math.sin(math.tau * (150 * time + 9 * math.sin(math.tau * 2 * time)))
        if name == 'current-loop':
            value = water * (.75 + .25 * math.sin(math.tau * time / 2)) + .009 * bubble
        elif name == 'flush-onset':
            value = water * min(1, time / .22) * (1 - .6 * fraction)
            value += .035 * math.sin(math.tau * (90 * time - 18 * time * time)) * math.exp(-time * 4)
        elif name == 'flush-surge':
            value = water * min(1, time / .28) * (1 - .5 * fraction)
            value += .018 * bubble * math.sin(math.pi * fraction)
        elif name == 'debris-impact':
            value = (.3 * math.sin(math.tau * 170 * time)
                     + .16 * math.sin(math.tau * 391 * time) + .2 * band) * math.exp(-time * 20)
        elif name == 'debris-break':
            pulse = sum(math.exp(-max(0, time - at) * 45) if time >= at else 0 for at in [0, .06, .13])
            value = (band * .8 + .07 * bubble) * pulse
        else:
            tone = 1150 if time < .065 else 1550
            value = .15 * math.sin(math.tau * tone * time) + .015 * band
            value *= min(1, abs(time - .065) / .004)
        if not looping:
            value *= min(1, time / .006, max(0, (duration - 1 / RATE - time) / .035))
        values.append(value)
    if looping:
        # Blend the extra tail into the first half-second; the wrap follows contiguous noise samples.
        for index in range(overlap):
            weight = index / (overlap - 1)
            values[index] = values[length + index] * (1 - weight) + values[index] * weight
        values = values[:length]
    return values


def main() -> None:
    """Write six versioned WAVs and machine-readable event/mix metadata."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cues = []
    for name, duration, peak_db, gain_db, looping in SPECS:
        values = synth(name, duration)
        scale = 10 ** (peak_db / 20) / max(map(abs, values))
        pcm = [round(value * scale * 32767) for value in values]
        path = OUTPUT / (name + '.wav')
        payload = struct.pack('<' + 'h' * len(pcm), *pcm)
        # Re-running an unchanged recipe is safe; a changed recipe must use a new versioned directory.
        if path.exists():
            with wave.open(str(path)) as existing:
                assert existing.readframes(existing.getnframes()) == payload, 'Preserve original; version new audio.'
        else:
            with wave.open(str(path), 'wb') as output:
                output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                output.writeframes(payload)
        cues.append({'event': name.replace('-', '_'), 'path': str(path.relative_to(ROOT)),
                     'duration_seconds': duration, 'loop': looping, 'gain_db': gain_db,
                     'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                     'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                     'boundary_step_dbfs': round(20 * math.log10(max(1, abs(pcm[-1] - pcm[0])) / 32768), 2),
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'date': '2026-10-24', 'format': '32000 Hz mono PCM16 WAV', 'cues': cues,
                'provenance': 'Original deterministic synthesis; no recordings, soundfonts or third-party samples.',
                'rights': 'Project-generated material; no third-party sample licenses or attribution obligations.',
                'generation_brief': 'Short oblique porcelain-bowl flush: quiet current, full-flush onset and surge, '
                'debris impact and break, short radio chirp. Keep radio clear; no full downstream ride.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'First-pass assets; subjective listening and runtime integration pending.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
