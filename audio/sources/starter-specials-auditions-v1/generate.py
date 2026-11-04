#!/usr/bin/env python3
"""Create sync-ready special-weapon auditions from retained licensed sources."""

import array
import hashlib
import json
import math
import subprocess
import uuid
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    'Tony Hydrojet Overdrive: pressure start, thick steady water core and sputter stop. '
    'Sean Main Break: plant/seal, strained pull, pipe release, vertical eruption, bend/tip and pressure decay. '
    'Three distinct restrained treatments plus accepted/empty HUD feedback. No voices or continuous clatter. '
    'Durations illustrative; no damage, recoil, input binding or gameplay implementation implied.'
)
SOURCES = {
    'water': ('audio/sources/player-death-flush-v1/toilet_01.ogg',
              'audio/sources/player-death-flush-v1/manifest.json', 'rubberduck', 'CC0-1.0'),
    'splash': ('audio/sources/starter-specials-auditions-v1/originals/splash_01.ogg',
               'audio/sources/player-death-flush-v1/manifest.json', 'rubberduck', 'CC0-1.0'),
    'splash2': ('audio/sources/starter-specials-auditions-v1/originals/splash_02.ogg',
                'audio/sources/player-death-flush-v1/manifest.json', 'rubberduck', 'CC0-1.0'),
    'metal': ('audio/sources/sputtervalve-v1/impactMetal_light_001.ogg',
              'audio/sources/sputtervalve-v1/manifest.json', 'Kenney', 'CC0-1.0'),
    'heavy': ('audio/sources/sputtervalve-v1/impactMetal_heavy_002.ogg',
              'audio/sources/sputtervalve-v1/manifest.json', 'Kenney', 'CC0-1.0'),
    'seal': ('assets/audio/sfx/starter-weapons-v1/sean-suction-pop.wav',
             'audio/sources/starter-weapons-audition-v1/manifest.json', 'Drain Damage', 'Original synthesis'),
    'jet': ('assets/audio/sfx/starter-weapons-v1/tony-water-gush.wav',
            'audio/sources/starter-weapons-audition-v1/water-round-2/manifest.json',
            'Drain Damage', 'Original synthesis'),
}
FAMILIES = [
    ('A — Clean pressure', 1.12, 280, 7200, .75, .2),
    ('B — Wet plumbing', .88, 120, 4600, .35, .1),
    ('C — Heavy pump', .68, 80, 2900, .45, .4),
]
SLOTS = [
    ('tony-preview', 'Tony Hydrojet Overdrive', 'Illustrative sequence — START HERE'),
    ('tony-start', 'Tony Hydrojet Overdrive', 'Pressure startup'),
    ('tony-core', 'Tony Hydrojet Overdrive', 'Sustained core — loop-ready'),
    ('tony-stop', 'Tony Hydrojet Overdrive', 'Sputter / shutdown'),
    ('sean-preview', 'Sean Main Break', 'Illustrative sequence — START HERE'),
    ('sean-seal', 'Sean Main Break', 'Plant / seal'),
    ('sean-pull', 'Sean Main Break', 'Strained pull'),
    ('sean-break', 'Sean Main Break', 'Pipe break / release'),
    ('sean-erupt', 'Sean Main Break', 'Vertical water eruption'),
    ('sean-tip', 'Sean Main Break', 'Pipe bend / tip, jet follows'),
    ('sean-stop', 'Sean Main Break', 'Sputtering pressure decay'),
    ('hud-accepted', 'Special HUD feedback', 'Activation accepted'),
    ('hud-empty', 'Special HUD feedback', 'No special uses left'),
]
PROCESSING: list[dict] = []


def load(key: str, speed: float, high: int, low: int) -> list[float]:
    """Decode and shape one source, retaining source identity and the exact filter recipe."""
    filters = f'aresample={RATE},asetrate={round(RATE * speed)},aresample={RATE},highpass=f={high},lowpass=f={low}'
    path = ROOT / SOURCES[key][0]
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-af', filters,
                          '-ac', '1', '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    values = list(array.array('f', raw))
    peak = max(map(abs, values))
    onset = next((i for i, v in enumerate(values) if abs(v) > .03 * peak), 0)
    values = values[max(0, onset - 100):]
    PROCESSING.append({'source': key, 'filters': filters, 'leading_trim_samples': max(0, onset - 100)})
    return [v / peak for v in values]


def cut(values: list[float], seconds: float, offset: float = 0, reverse: bool = False) -> list[float]:
    """Extract a faded finite gesture without implicit repetition."""
    size = round(seconds * RATE)
    start = min(round(offset * RATE), max(0, len(values) - size))
    result = values[start:start + size]
    if reverse:
        result.reverse()
    result += [0.0] * (size - len(result))
    fade_in, fade_out = min(176, size), min(1102, size)
    for i in range(fade_in):
        result[i] *= i / fade_in
    for i in range(fade_out):
        result[-i - 1] *= i / fade_out
    return result


def mix(seconds: float, layers: list[tuple[float, list[float], float]]) -> list[float]:
    """Place synchronized gestures with bounded duration."""
    values = [0.0] * round(seconds * RATE)
    for at, source, gain in layers:
        start = round(at * RATE)
        for i, value in enumerate(source[:len(values) - start]):
            values[start + i] += value * gain
    return values


def normalize(values: list[float], db: float) -> list[float]:
    """Set a controlled audition peak without compressing the transient."""
    peak = max(map(abs, values))
    if peak < 1e-8:
        raise ValueError('Silent source')
    gain = 10 ** (db / 20) / peak
    return [v * gain for v in values]


def loop_core(values: list[float]) -> list[float]:
    """Overlap a tail with the head, then rotate the splice into the middle of the loop."""
    length, overlap = round(1.2 * RATE), round(.12 * RATE)
    # The retained water recording is longer than this window; fail rather than pad the sustain.
    start = round(.25 * RATE)
    assert len(values) >= start + length + overlap
    raw = values[start:start + length + overlap]
    result = raw[:length]
    for i in range(overlap):
        blend = i / overlap
        result[i] = raw[length + i] * (1 - blend) + raw[i] * blend
    # Put the playback boundary in contiguous audio, away from the overlap transition.
    pivot = length // 2
    result = result[pivot:] + result[:pivot]
    # Suppress the one-sample wrap step without introducing a fade or silent gap.
    result[-1] = result[0]
    return result


def write(path: Path, values: list[float]) -> dict:
    """Write new PCM bytes only and return verifiable duration/headroom/hash metadata."""
    if path.exists():
        raise FileExistsError(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = array.array('h', (round(v * 32767) for v in values))
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    peak = max(map(abs, pcm)) / 32767
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(values) / RATE,
            'peak_dbfs': round(20 * math.log10(peak), 3),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main() -> None:
    """Append proposed slots, preserving all runtime mappings and previous candidates."""
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    if any(r['key'].startswith('proposed-starter-specials/') for r in registry['sounds']):
        raise ValueError('Already generated; use versioned candidates for revisions.')
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    records = {}
    for index, (key, group, label) in enumerate(SLOTS):
        records[key] = {'id': f'DD-S{number + index:04d}', 'key': f'proposed-starter-specials/{key}',
                        'uuid': str(uuid.uuid4()), 'section': 'Weapon sounds',
                        'group': group + ' drafts — NOT IN GAME', 'name': label,
                        'paths': [], 'source': MANIFEST, 'status': 'proposed', 'alternatives': []}
    outputs = []
    for family, (name, speed, high, low, jet_gain, metal_gain) in enumerate(FAMILIES, 1):
        water = load('water', speed, high, low)
        splash = load('splash' if family != 2 else 'splash2', speed, high, low)
        metal = load('metal', speed, 100, low)
        heavy = load('heavy', speed, 80, low)
        seal = load('seal', speed, high, low)
        jet = load('jet', speed, high, low)
        core = normalize(loop_core(water), -18)
        clips = {
            'tony-start': mix(.24, [(0, cut(jet, .24), jet_gain), (.03, cut(water, .21), .7),
                                    (0, cut(metal, .07), metal_gain)]),
            'tony-core': core,
            'tony-stop': mix(.34, [(0, cut(splash, .16), .5), (.17, cut(jet, .09), .25),
                                   (.27, cut(splash, .07, .15), .12)]),
            'sean-seal': mix(.18, [(0, cut(seal, .18), 1), (.01, cut(metal, .08), .12)]),
            'sean-pull': mix(.32, [(0, cut(seal, .3, reverse=True), .7),
                                   (.09, cut(heavy, .18, reverse=True), metal_gain)]),
            'sean-break': mix(.24, [(0, cut(heavy, .24), .8), (.04, cut(splash, .16), .5)]),
            'sean-erupt': mix(.65, [(0, cut(splash, .4), 1), (.1, cut(water, .55), .65),
                                    (.04, cut(jet, .27), jet_gain)]),
            'sean-tip': mix(.3, [(0, cut(heavy, .2, reverse=True), .3),
                                 (.09, cut(water, .21, reverse=True), .8)]),
            'sean-stop': mix(.48, [(0, cut(water, .2), .4), (.23, cut(splash, .12), .25),
                                   (.39, cut(jet, .09), .1)]),
            'hud-accepted': mix(.11, [(0, cut(seal, .07), .6), (.05, cut(metal, .06), .15)]),
            'hud-empty': mix(.14, [(0, cut(metal, .045), .25), (.08, cut(metal, .06), .15)]),
        }
        for event in clips:
            if event != 'tony-core':
                level = -20 if event.startswith('hud') else -16 if event.endswith(('pull', 'tip', 'stop')) else -11
                clips[event] = normalize(clips[event], level)
        tony_timeline = [('tony-start', 0), ('tony-core', .16), ('tony-core', 1.36), ('tony-stop', 2.56)]
        sean_timeline = [('sean-seal', 0), ('sean-pull', .3), ('sean-break', .72),
                         ('sean-erupt', .82), ('sean-tip', 1.5), ('sean-stop', 1.85)]
        clips['tony-preview'] = mix(3.0, [(t, clips[e], 1) for e, t in tony_timeline])
        clips['sean-preview'] = mix(2.5, [(t, clips[e], 1) for e, t in sean_timeline])
        # Demonstration player fades the sustain on entry/exit; the actual core stays seamless and unfaded.
        preview = clips['tony-preview']
        for i in range(round(.04 * RATE)):
            at = round(.16 * RATE) + i
            preview[at] = clips['tony-start'][at] + core[i] * i / round(.04 * RATE)
        for i in range(round(.04 * RATE)):
            at = round(2.56 * RATE) - i - 1
            preview[at] *= i / round(.04 * RATE)
        for event, values in clips.items():
            record = records[event]
            identity = f"{record['id']}.{family}"
            evidence = write(ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav', values)
            alternative = {'id': identity, 'path': evidence['path'],
                           'name': f'{name} · {evidence["duration_seconds"]:.2f}s',
                           'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                           'provenance': 'Retained CC0 rubberduck water/splash and Kenney metal recordings, '
                                         'layered with original Drain Damage starter-weapon synthesis.'}
            record['alternatives'].append(alternative)
            outputs.append({'id': identity, 'event': event, 'family': name,
                            'loop': event == 'tony-core', **evidence})
    source_records = {}
    for key, (path, evidence, author, license_name) in SOURCES.items():
        source_records[key] = {'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                               'license_evidence': evidence, 'author': author, 'license': license_name}
    manifest = {'date': '2026-11-03', 'status': 'Pending Sean approval; audition only', 'brief': BRIEF,
                'recipe': str(Path(__file__).relative_to(ROOT)), 'sources': source_records,
                'extracted_originals': {'archive': 'audio/sources/player-death-flush-v1/original-pack.zip',
                                       'members': ['splash_01.ogg', 'splash_02.ogg']},
                'processing': PROCESSING, 'outputs': outputs,
                'illustrative_timelines': {'tony': tony_timeline, 'sean': sean_timeline},
                'integration_proposal': [
                    'Tony: one sustain voice plus one bounded transient voice; fade core 40 ms on entry/exit.',
                    'Do not retrigger startup for aim changes; spatial placement follows the muzzle.',
                    'Sean: seal/pull/break/erupt/tip/decay follow separate animation events; tip follows facing side.',
                    'Duck or omit accepted HUD cue when the special start itself gives sufficient feedback.',
                    'Empty cue only on a fresh rejected press, never every held frame.',
                    'Two uses per hero per level and no refills are design context, not implemented here.',
                    'No weapon-switch cue or runtime hookup; future square weapon-icon HUD does not imply switching.',
                    'Musical/monster balance, audible loop acceptance and final timing need in-game listening.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry['sounds'].extend(records.values())
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(f'Created {len(outputs)} candidates: {records["tony-preview"]["id"]} through '
          f'{records["hud-empty"]["id"]}')


if __name__ == '__main__':
    main()
