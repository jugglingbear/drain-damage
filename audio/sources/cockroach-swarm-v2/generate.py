#!/usr/bin/env python3
"""Render Skitterling encounter supplements while preserving the original damage and loop assets."""

import hashlib
import json
import math
import random
import runpy
import struct
import wave
from pathlib import Path

RATE = 44100
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/sfx/cockroach-swarm-v2'
BASE = ROOT / 'audio/sources/cockroach-swarm-v1/generate.py'
SPECS = [('swarm-entry', .65, -15, -4), ('insect-shriek', 1.25, -12, -3),
         ('assembly', 2.5, -18, -5), ('rat-false-collapse', .9, -15, -4),
         ('pipe-warning', 2.0, -12, -3), ('pipe-launch', .35, -15, -3),
         ('landing', .40, -15, -3), ('water-dive', .65, -15, -4),
         ('water-emerge', .75, -15, -4), ('tail-warning', 1.0, -12, -3),
         ('debris-release', .35, -15, -4), ('debris-impact', .30, -15, -4)]


def main() -> None:
    """Produce deterministic original one-shots with click-free edges and recorded provenance."""
    texture = runpy.run_path(str(BASE))['texture']
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cues = []
    for number, (name, duration, peak_db, gain_db) in enumerate(SPECS):
        seed = 65200 + number
        samples = texture(duration, round(duration * 95), seed, False)
        rng = random.Random(seed)
        phase = low = 0.0
        for index in range(len(samples)):
            time = index / RATE
            fraction = time / duration
            low += .08 * (rng.uniform(-1, 1) - low)
            if name == 'insect-shriek':
                phase += math.tau * (2300 - 1400 * fraction + 180 * math.sin(math.tau * 51 * time)) / RATE
                voice = (.55 * math.sin(phase) + .22 * math.sin(phase * 2.31))
                voice *= (.4 + .6 * math.sin(math.tau * 71 * time) ** 2) * math.sin(math.pi * fraction) ** .6
                samples[index] = .2 * samples[index] + voice
            elif name.endswith('warning'):
                pulse = math.sin(math.pi * ((fraction * (4 if name == 'pipe-warning' else 2)) % 1)) ** 6
                samples[index] = .3 * samples[index] + .15 * pulse * math.sin(math.tau * 1200 * time)
            elif name == 'assembly':
                samples[index] *= .12 + fraction ** 1.5
            elif name.startswith('water'):
                envelope = math.sin(math.pi * fraction) if name == 'water-emerge' else math.exp(-fraction * 4)
                samples[index] = (.12 * samples[index] + .8 * low) * envelope
                samples[index] += .04 * math.sin(math.tau * (160 * time - 55 * time * time)) * envelope
            else:
                decay = 4 if name in ['swarm-entry', 'pipe-launch'] else 7
                samples[index] *= math.exp(-fraction * 2)
                samples[index] += .16 * math.sin(math.tau * (190 * time - 80 * time * time))
                samples[index] *= math.exp(-fraction * decay)
            samples[index] *= max(0, min(1, time / .004, (duration - 1 / RATE - time) / .055))
        scale = 32767 * 10 ** (peak_db / 20) / max(map(abs, samples))
        pcm = [round(value * scale) for value in samples]
        assert pcm[0] == pcm[-1] == 0 and max(map(abs, pcm)) < 9000
        path = OUTPUT / (name + '.wav')
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
        rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32767
        cues.append({'cue_id': name, 'path': str(path.relative_to(ROOT)), 'duration_seconds': duration,
                     'peak_dbfs': peak_db, 'rms_dbfs': round(20 * math.log10(rms), 2), 'gain_db': gain_db,
                     'loop': False, 'seed': seed, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'schema_version': 1, 'creature_id': 'cockroach-swarm', 'display_name': 'Skitterling',
                'date': '2026-10-17', 'cues': cues, 'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'provenance': 'Original deterministic procedural synthesis; no third-party samples or voices.',
                'rights': 'Project-generated material; no third-party sample licensing obligations introduced.',
                'generator': str(Path(__file__).resolve().relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'dependency': {'path': str(BASE.relative_to(ROOT)),
                               'sha256': hashlib.sha256(BASE.read_bytes()).hexdigest()},
                'procedure': 'Reuse original circular-grain texture function for nonlooping grains; FM insect shriek, '
                             'pulsed warning tones, filtered water noise and decaying material impacts; '
                             'final edge fades.',
                'status': 'Delivered for authorized encounter integration; runtime and listening pending.',
                'validation': 'Deterministic PCM headers/frame counts/hashes/peaks/zero endpoints; no audition.'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Rendered twelve Skitterling encounter cues without playback.')


if __name__ == '__main__':
    main()
