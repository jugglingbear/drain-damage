#!/usr/bin/env python3
"""Generate an original periodic swarm buzz without external samples."""

import hashlib
import json
import math
import struct
import wave
from pathlib import Path

RATE = 44100
DURATION = 2
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav'


def main() -> None:
    """Render integer-period voices so the whole two-second buffer loops continuously."""
    samples = []
    for index in range(RATE * DURATION):
        t = index / RATE
        value = 0.0
        for frequency, flutter, offset in [(173, 3, 0), (191, 4.5, 1.2), (211, 2.5, 2.4)]:
            phase = math.tau * frequency * t + 0.7 * math.sin(math.tau * flutter * t + offset)
            amplitude = 0.7 + 0.3 * math.sin(math.tau * 1.5 * t + offset)
            value += amplitude * sum(math.sin(phase * harmonic) / harmonic ** 1.5 for harmonic in range(1, 9))
        samples.append(value)
    gain = 10 ** (-18 / 20) / max(map(abs, samples))
    pcm = [round(value * gain * 32767) for value in samples]
    with wave.open(str(OUTPUT), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    manifest = {'id': 'sewer-fly-buzz-v1', 'path': str(OUTPUT.relative_to(ROOT)),
                'duration_seconds': DURATION, 'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16,
                'peak_dbfs': -18, 'suggested_gain_db': -8, 'loop': True,
                'provenance': 'Original additive synthesis; no third-party recordings or samples.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
                'status': 'Technical candidate; listening and runtime verification pending',
                'loop_boundary_step_pcm': abs(pcm[-1] - pcm[0])}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert max(map(abs, pcm)) < 4200
    assert abs(pcm[-1] - pcm[0]) < 500


if __name__ == '__main__':
    main()
