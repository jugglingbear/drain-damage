#!/usr/bin/env python3
"""Synthesize a fictional nonverbal suction cry without recordings or voice imitation."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
DURATION = 3.0
FADE_START = 1.4
PEAK_DBFS = -12.0
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/sfx/level-two-flush-v2/suction-burble.wav'
BRIEF = ('Generic panicked burbling/drowning scream fading away while the fictional hero is pulled down '
         'the drain and disappears. Three seconds, no dialogue, no actual person voice imitation.')


def render() -> list[int]:
    """Combine descending harmonic cry, interrupted bubbles and progressively muffled turbulence."""
    rng = random.Random(992410)
    values: list[float] = []
    phase = low = filtered = 0.0
    for index in range(round(RATE * DURATION)):
        time = index / RATE
        progress = time / DURATION
        pitch = (310 - 170 * progress) * (1 + .045 * math.sin(math.tau * 7 * time))
        phase += math.tau * pitch / RATE
        # Broad shifting resonances suggest a stylized vowel without synthesizing words or a person's voice.
        voice = 0.0
        for harmonic in range(1, 13):
            frequency = pitch * harmonic
            weight = (.18 + math.exp(-((frequency - 720) / 320) ** 2)
                      + .45 * math.exp(-((frequency - 1250) / 420) ** 2)) / harmonic
            voice += weight * math.sin(phase * harmonic)
        gate = .30 + .70 * (0.5 + 0.5 * math.sin(math.tau * (5 * time + 1.8 * time * time))) ** 2
        noise = rng.uniform(-1, 1)
        low += .08 * (noise - low)
        bubble = math.sin(math.tau * (260 * time + 22 * math.sin(math.tau * 3.1 * time)))
        raw = voice * gate + .16 * bubble * (1 - gate) + .22 * low
        filtered += (.30 - .24 * progress) * (raw - filtered)
        attack = min(1, time / .045)
        fade = max(0, (DURATION - 1 / RATE - time) / (DURATION - FADE_START)) ** 2
        envelope = attack * min(1, fade)
        values.append(filtered * envelope)
    gain = 10 ** (PEAK_DBFS / 20) / max(map(abs, values))
    return [round(value * gain * 32767) for value in values]


def main() -> None:
    """Preserve the versioned cue and record exact playback, provenance and measured levels."""
    pcm = render()
    payload = struct.pack('<' + 'h' * len(pcm), *pcm)
    if OUTPUT.exists():
        with wave.open(str(OUTPUT)) as existing:
            assert existing.readframes(existing.getnframes()) == payload, 'Version changed audio; keep originals.'
    else:
        with wave.open(str(OUTPUT), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(payload)
    manifest = {'event': 'suction_burble', 'path': str(OUTPUT.relative_to(ROOT)),
                'duration_seconds': DURATION, 'frames': len(pcm), 'format': '32000 Hz mono PCM16 WAV',
                'loop': False, 'gain_db': -4, 'attack_seconds': .045,
                'fade': {'start_seconds': FADE_START, 'end_seconds': DURATION, 'curve': 'squared amplitude'},
                'peak_dbfs': round(20 * math.log10(max(map(abs, pcm)) / 32768), 2),
                'rms_dbfs': round(20 * math.log10(math.sqrt(sum(v*v for v in pcm) / len(pcm)) / 32768), 2),
                'sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(), 'generation_brief': BRIEF,
                'provenance': 'Original deterministic sample-free synthesis; no human recordings, voice models or '
                'third-party samples. Fictional nonverbal effect, not an imitation of Tony, Sean or another person.',
                'rights': 'Project-generated material; no third-party sample license or attribution obligations.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'First pass; no subjective listening approval.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
