#!/usr/bin/env python3
"""Measure source and proposed runtime levels without sending samples to an audio device."""

import json
import math
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
RATE = 8000
ASSETS = {
    'old_music': ('assets/audio/music/clogfather-backpressure-v1.ogg', -18),
    'new_music': ('assets/audio/music/clogfather-italian-battle-v2.ogg', -16),
    'pressure_warning': ('assets/audio/sfx/clogfather-v1/pressure-warning.wav', -5),
    'acid_warning': ('assets/audio/sfx/clogfather-v1/acid-warning.wav', -5),
    'reinforcement_warning': ('assets/audio/sfx/clogfather-v1/groan-b.wav', -5),
    'swarm_maximum': ('assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav', -8),
}


def db(value: float) -> float:
    """Convert a normalized amplitude to dBFS with a finite silence floor."""
    return round(20 * math.log10(max(value, 1e-12)), 2)


def decode(path: str, filters: str = 'anull') -> tuple[float, ...]:
    """Decode and optionally isolate a comparison band, downsampling for RMS analysis only."""
    result = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(ROOT / path), '-af', filters,
                             '-ar', str(RATE), '-ac', '1', '-f', 'f32le', 'pipe:1'],
                            check=True, capture_output=True)
    return struct.unpack('<' + 'f' * (len(result.stdout) // 4), result.stdout)


def levels(values: tuple[float, ...], gain: float) -> dict[str, float]:
    """Measure overall RMS and the loudest 0.1-second block at the proposed player gain."""
    power = [v * v for v in values]
    window = RATE // 10
    maximum = max(sum(power[i:i + window]) / len(power[i:i + window])
                  for i in range(0, len(power), window))
    return {'rms_dbfs_at_gain': round(db(math.sqrt(sum(power) / len(power))) + gain, 2),
            'max_100ms_rms_dbfs_at_gain': round(db(math.sqrt(maximum)) + gain, 2)}


def main() -> None:
    """Save reproducible objective mix comparisons; hearing and perception remain untested."""
    measurements = {}
    for name, (path, gain) in ASSETS.items():
        bands = {}
        for label, filters in [('full', 'anull'), ('80_500hz', 'highpass=f=80,lowpass=f=500'),
                               ('500_3500hz', 'highpass=f=500,lowpass=f=3500')]:
            bands[label] = levels(decode(path, filters), gain)
        measurements[name] = {'path': path, 'player_gain_db': gain, 'bands': bands}
        if 'music' in name:
            result = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(ROOT / path),
                                     '-af', 'ebur128=peak=true', '-f', 'null', '-'], capture_output=True, check=True)
            summary = result.stderr.decode().split('Summary:')[-1]
            measurements[name]['ebur128_summary'] = summary.split('[out#')[0].strip()
    # Runtime firing uses a +/-0.075 square oscillator with min(remaining*30,1) decay at22.05kHz.
    for frequency in [310, 110]:
        values = tuple((.075 if ((i * frequency / 22050) % 1) < .5 else -.075)
                       * min((.055 - i / 22050) * 30, 1) for i in range(round(.055 * 22050)))
        measurements[f'weapon_{frequency}hz'] = {'peak_dbfs': db(max(map(abs, values))),
            'rms_dbfs': db(math.sqrt(sum(v*v for v in values) / len(values))), 'duration_seconds': .055}
    report = {'date': '2026-10-23', 'measurements': measurements,
              'method': 'FFmpeg ebur128 true peak at native rate; band RMS via two-pole high/lowpass and8kHz '
                        'analysis decode. 100ms nonoverlapping block maxima are conservative time-density '
                        'comparisons, not simultaneous perceptual masking measurements.',
              'limitations': 'No audition; warning masking and device variation require listening.'}
    (SOURCE / 'analysis.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(measurements, indent=2))


if __name__ == '__main__':
    main()
