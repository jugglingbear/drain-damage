#!/usr/bin/env python3
"""Mix original insect stridulation with a synthetic rat-like squeal for the one-second pounce tell."""

import hashlib
import json
import math
import struct
import wave
from pathlib import Path

RATE = 44100
DURATION = 1.0
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
INSECT = ROOT / 'assets/audio/sfx/cockroach-swarm-v2/insect-shriek.wav'
OUTPUT = ROOT / 'assets/audio/sfx/cockroach-swarm-v3/rat-insect-pounce-warning.wav'
PEAK_DB = -12


def main() -> None:
    """Render and document a deterministic layered warning; no animal recording or playback is used."""
    with wave.open(str(INSECT), 'rb') as source:
        assert (source.getnchannels(), source.getsampwidth(), source.getframerate()) == (1, 2, RATE)
        raw = source.readframes(source.getnframes())
    insect = struct.unpack('<' + 'h' * (len(raw) // 2), raw)
    insect_peak = max(map(abs, insect))
    samples = []
    phase = 0.0
    for index in range(round(RATE * DURATION)):
        time = index / RATE
        # Two uneven high squeals suggest a small mammal over the sustained insect rasp.
        envelope = math.exp(-((time - .25) / .14) ** 2) + .75 * math.exp(-((time - .66) / .18) ** 2)
        frequency = 2700 + 1050 * math.sin(math.pi * time) + 140 * math.sin(math.tau * 31 * time)
        phase += math.tau * frequency / RATE
        squeal = envelope * (math.sin(phase) + .22 * math.sin(2 * phase) + .08 * math.sin(3 * phase))
        value = .55 * insect[index] / insect_peak + .45 * squeal
        edge = max(0, min(1, time / .008, (DURATION - 1 / RATE - time) / .06))
        samples.append(value * edge)
    scale = 32767 * 10 ** (PEAK_DB / 20) / max(map(abs, samples))
    pcm = [round(value * scale) for value in samples]
    assert pcm[0] == pcm[-1] == 0 and max(map(abs, pcm)) < 9000
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32767
    manifest = {
        'schema_version': 1, 'date': '2026-10-19', 'creature_id': 'cockroach-swarm',
        'cues': [{'cue_id': 'rat-insect-pounce-warning', 'path': str(OUTPUT.relative_to(ROOT)),
                  'duration_seconds': DURATION, 'peak_dbfs': PEAK_DB, 'gain_db': -3, 'loop': False,
                  'rms_dbfs': round(20 * math.log10(rms), 2),
                  'sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}],
        'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
        'source': {'path': str(INSECT.relative_to(ROOT)), 'sha256': hashlib.sha256(INSECT.read_bytes()).hexdigest(),
                   'manifest': 'audio/sources/cockroach-swarm-v2/manifest.json'},
        'provenance': 'Original insect synthesis plus new original synthetic high squeal; no animal recording.',
        'rights': 'Project-generated material; no third-party sample licensing obligations introduced.',
        'procedure': 'First second of normalized insect source at .55 plus .45 two-envelope harmonic FM squeal; '
                     '8ms attack/60ms release; final peak normalization. Exact recipe preserved in generator.',
        'generator': str(Path(__file__).resolve().relative_to(ROOT)),
        'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'validation': 'PCM headers, duration, zero endpoints, peaks and reproducibility checked; no audition.',
        'limitations': 'Rat-like synthetic timbre is an approximation. Perceived animal/insect blend awaits listening.',
    }
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Rendered one-second synthetic rat/insect pounce warning without playback.')


if __name__ == '__main__':
    main()
