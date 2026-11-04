#!/usr/bin/env python3
"""Build powerful, water-heavy special cues and adjustable 7.5-second audition timelines."""

import array
import hashlib
import json
import math
import random
import subprocess
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    "Sean requests Tony's jetter to sound like a loud fire hose or broken hydrant: "
    "tons of water, violent and powerful. "
    "Sean's plunger and water spout should last longer. Starting target is 7–8 seconds for each whole special. "
    'Create a dense water roar with recorded liquid texture and original filtered turbulence, preserving headroom. '
    'Keep separate startup, sustain and shutdown assets; no gameplay implementation.'
)
SOURCES = {
    'water': 'audio/sources/player-death-flush-v1/toilet_01.ogg',
    'splash': 'audio/sources/starter-specials-auditions-v1/originals/splash_01.ogg',
    'splash2': 'audio/sources/starter-specials-auditions-v1/originals/splash_02.ogg',
}
SOURCE_FILTERS = {
    'water': 'aresample=44100,asetrate=35280,aresample=44100,highpass=f=80,lowpass=f=6500',
    'splash': 'aresample=44100,asetrate=39690,aresample=44100,highpass=f=100,lowpass=f=8000',
    'splash2': 'aresample=44100,asetrate=30870,aresample=44100,highpass=f=70,lowpass=f=5000',
}


def decode(key: str) -> list[float]:
    """Decode a retained CC0 water source with deterministic spectral/pitch shaping."""
    result = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(ROOT / SOURCES[key]),
                             '-af', SOURCE_FILTERS[key], '-ac', '1', '-f', 'f32le', '-'],
                            check=True, capture_output=True)
    values = list(array.array('f', result.stdout))
    peak = max(map(abs, values))
    return [v / peak for v in values]


def pcm(path: str) -> list[float]:
    """Read earlier mono sync cues without changing their source files."""
    with wave.open(str(ROOT / path)) as stream:
        return [v / 32767 for v in array.array('h', stream.readframes(stream.getnframes()))]


def shaped(values: list[float], seconds: float, offset: float = 0) -> list[float]:
    """Cut and smoothly gate an isolated gesture."""
    count = round(seconds * RATE)
    start = min(round(offset * RATE), max(0, len(values) - count))
    clip = values[start:start + count]
    clip += [0.0] * (count - len(clip))
    for i in range(len(clip)):
        clip[i] *= min(1, i / 220, (len(clip) - 1 - i) / 1764)
    return clip


def layer(seconds: float, parts: list[tuple[float, list[float], float]]) -> list[float]:
    """Mix event layers on an explicit audition timeline."""
    result = [0.0] * round(seconds * RATE)
    for time, clip, gain in parts:
        at = round(time * RATE)
        for i, v in enumerate(clip[:len(result) - at]):
            result[at + i] += v * gain
    return result


def peak(values: list[float], db: float) -> list[float]:
    """Normalize without exceeding the chosen peak headroom."""
    gain = 10 ** (db / 20) / max(map(abs, values))
    return [v * gain for v in values]


def circular(values: list[float], length: int, overlap: int) -> list[float]:
    """Blend an extra tail over the head for a sustained wrap without silence."""
    assert len(values) >= length + overlap
    result = values[:length]
    for i in range(overlap):
        weight = i / overlap
        result[i] = values[length + i] * (1 - weight) + values[i] * weight
    pivot = length // 2
    result = result[pivot:] + result[:pivot]
    result[-1] = result[0]
    return result


def torrent(water: list[float], splash: list[float], seed: int, bass_weight: float) -> list[float]:
    """Combine recorded liquid with broad filtered turbulence, never tonal oscillators."""
    rng = random.Random(seed)
    count, overlap = 3 * RATE, round(.2 * RATE)
    low = mid = 0.0
    result = []
    for i in range(count + overlap):
        noise = rng.uniform(-1, 1)
        low += .025 * (noise - low)
        mid += .28 * (noise - mid)
        turbulence = bass_weight * low + .85 * mid + .13 * (noise - mid)
        liquid = water[(i + RATE // 3) % len(water)] * .38
        droplets = splash[(i * 7 // 6 + RATE // 2) % len(splash)] * .17
        # Broad liquid roar remains dense; gentle saturation restrains random spikes, not the overall energy.
        result.append(math.tanh(2.1 * (turbulence + liquid + droplets)))
    return peak(circular(result, count, overlap), -5)


def sustain(core: list[float], seconds: float, fade_in: float, fade_out: float) -> list[float]:
    """Repeat the unfaded loop with lifecycle fades for a finite demonstration."""
    count = round(seconds * RATE)
    return [core[i % len(core)] * min(1, i / max(1, fade_in * RATE),
                                    (count - 1 - i) / max(1, fade_out * RATE)) for i in range(count)]


def write(path: Path, values: list[float]) -> dict:
    """Save new PCM assets, with measured peak/RMS and immutable-source evidence."""
    if path.exists():
        raise FileExistsError(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    data = array.array('h', (round(v * 32767) for v in values))
    assert max(map(abs, data)) < 32767
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(data.tobytes())
    rms = math.sqrt(sum(v * v for v in values) / len(values))
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(values) / RATE,
            'peak_dbfs': round(20 * math.log10(max(map(abs, values))), 2),
            'rms_dbfs': round(20 * math.log10(rms), 2),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main() -> None:
    """Append one stronger treatment to existing special slots; retain earlier families."""
    timing = json.loads((HERE / 'timing.json').read_text())
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    records = {r['key'].split('/')[-1]: r for r in registry['sounds']
               if r['key'].startswith('proposed-starter-specials/')}
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Create a new version; do not overwrite this delivery.')
    water, splash, splash2 = (decode(k) for k in ('water', 'splash', 'splash2'))
    tony_core = torrent(water, splash, 71031, 2.5)
    sean_core = torrent(water, splash2, 71032, 3.8)
    def old(event: str) -> list[float]:
        return pcm(records[event]['alternatives'][2]['path'])
    tony_start = peak(layer(.35, [(0, shaped(splash, .35), .7),
                                 (.025, sustain(tony_core, .325, .08, .05), 1)]), -5)
    tony_stop = peak(layer(.7, [(0, sustain(tony_core, .45, .005, .4), .8),
                               (.36, shaped(splash2, .19, .1), .45),
                               (.58, shaped(splash, .12, .3), .18)]), -9)
    sean_erupt = peak(layer(.65, [(0, shaped(splash2, .5), 1),
                                 (.06, sustain(sean_core, .59, .04, .2), 1)]), -5)
    sean_stop = peak(layer(1.5, [(0, sustain(sean_core, 1.1, .005, 1.05), 1),
                                (.65, shaped(splash, .24), .55), (.96, shaped(splash2, .2), .35),
                                (1.24, shaped(splash, .15, .2), .2),
                                (1.4, shaped(splash2, .1, .3), .1)]), -10)
    # Longer strained pull is composed from seal friction rather than stretching a tiny pop into a drone.
    pull_base = old('sean-pull')
    pull = peak(layer(timing['sean_pull_duration'], [(0, pull_base, .75), (.23, pull_base, 1)]), -17)
    t = timing['tony']
    s = timing['sean']
    clips = {'tony-start': tony_start, 'tony-core': tony_core, 'tony-stop': tony_stop,
             'sean-pull': pull, 'sean-erupt': sean_erupt, 'sean-core': sean_core, 'sean-stop': sean_stop}
    clips['tony-preview'] = peak(layer(7.5, [(0, tony_start, 1),
        (t['core_start'], sustain(tony_core, t['core_duration'], .12, .15), 1),
        (t['stop_start'], tony_stop, 1)]), -4)
    clips['sean-preview'] = peak(layer(7.5, [(s['seal'], old('sean-seal'), 1), (s['pull'], pull, 1),
        (s['break'], old('sean-break'), 1.25), (s['erupt'], sean_erupt, 1),
        (s['core_start'], sustain(sean_core, s['core_duration'], .16, .18), 1),
        (s['tip'], old('sean-hinge'), 1), (s['tip'], old('sean-tip'), .7),
        (s['stop_start'], sean_stop, 1)]), -4)
    outputs = []
    for event, values in clips.items():
        record = records[event]
        suffix = max(int(a['id'].split('.')[-1]) for a in record['alternatives']) + 1
        identity = f"{record['id']}.{suffix}"
        evidence = write(ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav', values)
        record['alternatives'].append({'id': identity, 'path': evidence['path'],
            'name': f'TORRENT v2 — broken hydrant · {evidence["duration_seconds"]:.2f}s',
            'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
            'provenance': 'CC0 rubberduck water/splash recordings plus original deterministic filtered turbulence; '
                          'earlier CC0 metal/original suction cues in Sean preview. Not a literal hydrant recording.'})
        outputs.append({'id': identity, 'event': event, 'loop': event.endswith('core'), **evidence})
    source_records = {key: {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                            'filters': SOURCE_FILTERS[key], 'author': 'rubberduck', 'license': 'CC0-1.0'}
                      for key, path in SOURCES.items()}
    manifest = {'date': '2026-11-03', 'status': 'Revised audition; pending listening approval, not implemented',
                'brief': BRIEF, 'sources': source_records,
                'license_evidence': 'audio/sources/player-death-flush-v1/manifest.json',
                'parent_sources_and_licenses': 'audio/sources/starter-specials-auditions-v1/manifest.json',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'timing': timing, 'outputs': outputs,
                'mix': 'Higher density and low water roar, peaks capped at -4dBFS in previews. Sustain is unfaded '
                       'for loop playback; demonstrate lifecycle fades separately. Final mix under music unverified.',
                'limitations': ['Total 7.5s previews are starting points, not finalized gameplay timing.',
                                'No runtime, damage, recoil or input changes.',
                                'Audible character and loop/mix acceptance require listening.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['event'], o['rms_dbfs']) for o in outputs])


if __name__ == '__main__':
    main()
