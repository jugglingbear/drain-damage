#!/usr/bin/env python3
"""Prepare Sputtervalve metal damage cues from preserved CC0 foley and original pressure noise."""

import hashlib
import json
import math
import random
import shutil
import struct
import subprocess
import wave
import zipfile
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
OUTPUT = ROOT / 'assets/audio/sfx/sputtervalve-v1'
PACK = ROOT / 'audio/sources/menu-navigation-candidates-v1/kenney-impact-sounds.zip'
LICENSE = PACK.with_name(PACK.name + '-License.txt')
MEMBERS = ['impactMetal_light_001.ogg', 'impactMetal_light_003.ogg', 'impactMetal_heavy_002.ogg']
SEED = 171026


def digest(path: Path) -> str:
    """Return a preserved file's SHA-256 fingerprint."""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decode(name: str, pitch: float, duration: float) -> list[float]:
    """Decode and filter a source at a documented pitch ratio without playing it."""
    filters = (
        f'asetrate=44100*{pitch},aresample=44100,highpass=f=180,lowpass=f=6500,'
        f'silenceremove=start_periods=1:start_threshold=-45dB,apad,atrim=duration={duration}'
    )
    result = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(SOURCE / name), '-af', filters,
         '-ar', str(RATE), '-ac', '1', '-f', 'f32le', 'pipe:1'],
        check=True, capture_output=True,
    )
    values = list(struct.unpack('<' + 'f' * (len(result.stdout) // 4), result.stdout))
    peak = max(map(abs, values))
    return [value / peak for value in values]


def layer(target: list[float], values: list[float], at: float, gain: float) -> None:
    """Mix a source at a fixed offset, clipping only its duration to the target buffer."""
    offset = round(at * RATE)
    for index, value in enumerate(values[:len(target) - offset]):
        target[offset + index] += value * gain


def save(name: str, values: list[float], peak_db: float) -> dict[str, object]:
    """Apply click-preventing edges and exact peak normalization, then write mono PCM16."""
    for index in range(len(values)):
        values[index] *= max(0, min(1, index / (RATE * .002), (len(values) - 1 - index) / (RATE * .035)))
    gain = 32767 * 10 ** (peak_db / 20) / max(map(abs, values))
    pcm = [round(value * gain) for value in values]
    path = OUTPUT / (name + '.wav')
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    assert pcm[0] == pcm[-1] == 0 and max(map(abs, pcm)) < 9000
    rms = math.sqrt(sum(value * value for value in pcm) / len(pcm)) / 32767
    return {'cue_id': name, 'path': str(path.relative_to(ROOT)), 'duration_seconds': len(pcm) / RATE,
            'peak_dbfs': peak_db, 'rms_dbfs': round(20 * math.log10(rms), 2),
            'gain_db': -3, 'loop': False, 'sha256': digest(path)}


def main() -> None:
    """Render three versioned cues, preserving exact source members and processing provenance."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(PACK) as archive:
        for name in MEMBERS:
            (SOURCE / name).write_bytes(archive.read('Audio/' + name))
    shutil.copyfile(LICENSE, SOURCE / 'Kenney-License.txt')
    light_a = decode(MEMBERS[0], .95, .20)
    light_b = decode(MEMBERS[1], .86, .22)
    heavy = decode(MEMBERS[2], .78, .45)
    cues = []
    for name, source, duration in [('hit-a', light_a, .18), ('hit-b', light_b, .22)]:
        samples = [0.0] * round(duration * RATE)
        layer(samples, source, 0, 1)
        # Small late contacts suggest loose gauge hardware without a sustained ringing tail.
        layer(samples, source[:round(.045 * RATE)], .065, .18)
        layer(samples, source[:round(.035 * RATE)], .11, .08)
        cues.append(save(name, samples, -15))
    death = [0.0] * round(.72 * RATE)
    layer(death, heavy, 0, 1)
    layer(death, light_b[:round(.14 * RATE)], .12, .27)
    layer(death, light_a[:round(.12 * RATE)], .265, .17)
    layer(death, light_b[:round(.10 * RATE)], .43, .09)
    rng = random.Random(SEED)
    low = 0.0
    smooth = 0.0
    for index in range(round(.08 * RATE), len(death)):
        age = index / RATE - .08
        low += .035 * (rng.uniform(-1, 1) - low)
        smooth += .34 * (rng.uniform(-1, 1) - smooth)
        envelope = min(1, age / .025) * math.exp(-age * 5.5)
        death[index] += .32 * (smooth - low) * envelope
    cues.append(save('death', death, -12))
    manifest = {
        'schema_version': 1, 'date': '2026-10-17', 'creature_id': 'sputtervalve',
        'status': 'Assets validated; runtime integration and listening pending',
        'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16}, 'cues': cues,
        'direction': 'Dry metal hit with short gauge rattle; heavier collapse with escaping pressure and loose metal.',
        'consultation': 'Storyboarding agreed October 17; no speech, magic origin, attack tell or new lore.',
        'source': {'author': 'Kenney', 'license': 'CC0-1.0', 'page': 'https://kenney.nl/assets/impact-sounds',
                   'pack': str(PACK.relative_to(ROOT)), 'pack_sha256': digest(PACK),
                   'license_record': str((SOURCE / 'Kenney-License.txt').relative_to(ROOT)),
                   'members': [{'member': 'Audio/' + name, 'preserved': str((SOURCE / name).relative_to(ROOT)),
                                'sha256': digest(SOURCE / name)} for name in MEMBERS]},
        'procedure': 'Source decode: rate ratios .95/.86/.78; 44.1k mono; HP180/LP6500; initial silence below -45dB '
                     'removed; normalized source layers; hit rattle at65/110ms; death metal at0/120/265/430ms; '
                     'original seeded filtered noise from80ms with exponential pressure decay; final2ms/35ms edges '
                     'and peak normalization. Exact gains, filters and durations in generator.',
        'original_synthesis': {'pressure_noise_seed': SEED, 'third_party_voice_or_music': False},
        'generator': str(Path(__file__).relative_to(ROOT)), 'generator_sha256': digest(Path(__file__)),
        'validation': 'Mono PCM16 headers, exact frame counts, zero endpoints, peaks and hashes checked. No audition.',
        'limitations': 'Designed metal/pressure approximation; physical materials are sound direction, not new lore. '
                       'No subjective listening or in-game balance claim.',
    }
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(cues, indent=2))


if __name__ == '__main__':
    main()
