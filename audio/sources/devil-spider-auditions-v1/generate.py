#!/usr/bin/env python3
"""Render recorded-source devil-spider draft families; refuse to replace existing auditions."""

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
LIBRARY = ROOT / 'audio/sources/recorded-creatures-cc0-v1'
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
BRIEF = (
    'New horrifying ceiling devil spider: readable aim, web launch and attachment, alternating strained silk hauls, '
    'cocoon struggle, strand tearing and escape. Four recorded-source directions, no chiptune oscillators. '
    'Draft audition only; demonstration timing is illustrative, not an approved gameplay contract.'
)
FAMILIES = [
    ('A — Chitin rattle', 'Dry, close clicking with a narrow rasp.', 'bug_01', 'eat_01', 'spit_01', 1.12, 650, 6500),
    ('B — Wet brood', 'Throaty burbling, sticky pulls and wet spit.', 'burble_02', 'eat_03', 'spit_03', .83, 140, 4400),
    ('C — Breath stalker', 'Airy hiss, small ticks and whispery friction.',
     'breath', 'bug_03', 'spit_02', .94, 1000, 8500),
    ('D — Black maw', 'Low rasping voice with heavier, slower-textured pulls.', 'monster_06', 'eat_04', 'spit_01', .65,
     90, 3300),
]
EVENTS = [
    ('sequence', 'Attack sequence — START HERE'),
    ('aim', 'Aim warning / voice'),
    ('crawl', 'Ceiling claw movement'),
    ('launch', 'Web launch'),
    ('attach', 'Web attachment'),
    ('haul', 'Alternating silk hauling'),
    ('struggle', 'Cocoon struggle'),
    ('tear', 'Strand tearing'),
    ('escape', 'Escape release'),
    ('rustle', 'Old cocoon twitch / quiet rustle'),
    ('hit', 'Creature hit'),
    ('death', 'Creature death'),
]
SOURCES: dict[str, dict] = {}
RECIPES: list[dict] = []


def source(name: str, speed: float, high: int, low: int) -> list[float]:
    """Decode a preserved recording with explicit pitch/rate and spectral shaping."""
    path = LIBRARY / 'rubberduck' / f'{name}.ogg'
    filters = f'aresample={RATE},asetrate={round(RATE * speed)},aresample={RATE},highpass=f={high},lowpass=f={low}'
    command = ['ffmpeg', '-v', 'error', '-i', str(path), '-af', filters, '-ac', '1', '-f', 'f32le', '-']
    raw = subprocess.run(command, check=True, capture_output=True).stdout
    values = list(array.array('f', raw))
    peak = max(abs(v) for v in values)
    # Remove only leading recording silence; preserve the vocal gesture after onset.
    start = next((i for i, value in enumerate(values) if abs(value) > peak * .025), 0)
    values = values[max(0, start - 220):]
    values = [v / peak for v in values]
    key = f'{name}/{speed}/{high}/{low}'
    SOURCES[key] = {'path': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                    'filters': filters, 'trim': 'Leading signal below 2.5% peak, retaining 220 samples pre-onset',
                    'license': 'CC0-1.0', 'author': 'rubberduck',
                    'source_url': 'https://opengameart.org/content/80-cc0-creature-sfx'}
    return values


def fragment(values: list[float], duration: float, offset: float = 0, reverse: bool = False) -> list[float]:
    """Cut a recording with short fades; short inputs are padded, never silently looped."""
    count = round(duration * RATE)
    start = min(round(offset * RATE), max(0, len(values) - count))
    result = values[start:start + count]
    if reverse:
        result = result[::-1]
    result += [0.0] * (count - len(result))
    fade = min(441, count // 4)
    for index in range(fade):
        result[index] *= index / fade
        result[-index - 1] *= index / fade
    return result


def mix(duration: float, layers: list[tuple[float, list[float], float]]) -> list[float]:
    """Mix finite layers, leaving intentional pauses between gestures."""
    result = [0.0] * round(duration * RATE)
    for time, clip, gain in layers:
        start = round(time * RATE)
        for index, value in enumerate(clip[:max(0, len(result) - start)]):
            result[start + index] += value * gain
    return result


def save(path: Path, values: list[float], peak_db: float) -> dict:
    """Write a new PCM asset and record technical evidence."""
    if path.exists():
        raise FileExistsError(f'Preserve original: {path}')
    peak = max(abs(v) for v in values)
    if peak < 1e-6:
        raise ValueError(f'Silent candidate: {path}')
    gain = 10 ** (peak_db / 20) / peak
    pcm = array.array('h', (round(v * gain * 32767) for v in values))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(values) / RATE, 'peak_dbfs': peak_db,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main() -> None:
    """Create four families and append proposed slots without touching runtime mappings."""
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    if any(r['key'].startswith('proposed-devil-spider/') for r in registry['sounds']):
        raise ValueError('This version is already registered; create a new version instead.')
    number = max(int(r['id'].split('S')[-1]) for r in registry['sounds']) + 1
    records = {}
    for index, (event, label) in enumerate(EVENTS):
        records[event] = {'key': f'proposed-devil-spider/{event}', 'id': f'DD-S{number + index:04d}',
                          'uuid': str(uuid.uuid4()), 'section': 'Level 1',
                          'group': 'Devil spider drafts — NOT IN GAME', 'name': label, 'paths': [],
                          'source': MANIFEST, 'status': 'proposed', 'alternatives': []}
    for family_index, family in enumerate(FAMILIES, 1):
        name, description, vocal_name, texture_name, spit_name, speed, high, low = family
        voice = source(vocal_name, speed, high, low)
        texture = source(texture_name, speed, high, low)
        spit = source(spit_name, speed, high, low)
        breath = source('breath', speed, max(250, high), low)
        tick = fragment(texture, .075)
        pull = fragment(texture, .32, .08, reverse=True)
        hiss = fragment(breath, .45)
        clips = {
            'aim': mix(1.05, [(0, fragment(voice, .72), .8), (.67, hiss, .25)]),
            'crawl': mix(1.15, [(t, fragment(texture, .065, i * .07), g)
                                 for i, (t, g) in enumerate([(0, .6), (.13, .35), (.4, .7), (.58, .4), (.88, .55)])]),
            'launch': mix(.52, [(0, fragment(breath, .18, reverse=True), .45), (.11, fragment(spit, .38), 1)]),
            'attach': mix(.38, [(0, fragment(spit, .15, .12), .8), (.07, fragment(texture, .27), .4)]),
            'haul': mix(2.2, [(t, pull, g) for t, g in [(0, .8), (.48, .6), (1.04, 1), (1.6, .7)]]
                         + [(t + .13, fragment(breath, .27, .1), .25) for t in [0, .48, 1.04, 1.6]]),
            'struggle': mix(1.3, [(0, fragment(texture, .37, .1), .7), (.35, hiss, .3),
                                   (.63, fragment(texture, .4, reverse=True), .8), (1.05, tick, .5)]),
            'tear': mix(.6, [(0, fragment(breath, .42, reverse=True), .4), (.12, fragment(texture, .25), 1),
                              (.39, tick, .7)]),
            'escape': mix(.85, [(0, fragment(texture, .22), .8), (.17, fragment(spit, .2), .55),
                                 (.32, fragment(breath, .45), .35)]),
            'rustle': mix(1.4, [(.1, fragment(breath, .3), .2), (.7, fragment(texture, .18), .15)]),
            'hit': fragment(voice, .24, .12),
            'death': mix(1.6, [(0, fragment(voice, 1.2), 1), (.7, fragment(texture, .5), .4),
                                (1.12, fragment(breath, .4), .2)]),
        }
        # Equal family preview peaks; rustles and footsteps remain subordinate to attack warnings.
        levels = {'crawl': -17, 'rustle': -25, 'haul': -14, 'struggle': -14}
        for event, clip in clips.items():
            peak = max(abs(v) for v in clip)
            clips[event] = [v / peak * 10 ** (levels.get(event, -9) / 20) for v in clip]
        timeline = [('crawl', 0), ('aim', 1.35), ('launch', 2.65), ('attach', 3.15),
                    ('haul', 3.7), ('struggle', 6.15), ('tear', 7.7), ('escape', 8.5)]
        clips['sequence'] = mix(9.6, [(time, clips[event], 1) for event, time in timeline])
        for event, _ in EVENTS:
            record = records[event]
            identity = f"{record['id']}.{family_index}"
            path = ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav'
            evidence = save(path, clips[event], levels.get(event, -9))
            alternative = {'id': identity, 'path': evidence['path'], 'name': f'{name} — {description}',
                           'source_manifest': MANIFEST, 'license': 'CC0-1.0', 'generation_prompt': BRIEF,
                           'provenance': 'Edited retained rubberduck CC0 mouth/creature recordings; designed silk/claw '
                                         'textures, not actual spider or silk recordings.'}
            record['alternatives'].append(alternative)
            RECIPES.append({'id': identity, 'event': event, 'family': name, **evidence})
    manifest = {'date': '2026-11-03', 'status': 'Draft auditions only; no gameplay integration or selection',
                'brief': BRIEF, 'license': 'CC0-1.0',
                'license_evidence': 'audio/sources/recorded-creatures-cc0-v1/manifest.json',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'sources': SOURCES,
                'families': [{'name': f[0], 'description': f[1], 'playback_rate': f[5],
                              'semitones': 12 * math.log2(f[5])} for f in FAMILIES],
                'sequence_timeline_seconds': timeline, 'outputs': RECIPES,
                'limitations': ['Timing is illustrative; no input counts or mechanics approved.',
                                'Mono sync-ready cues; runtime panning and mix not implemented.',
                                'Hauling is a finite four-pull demonstration, not a seamless loop.',
                                'Subjective listening acceptance remains with Sean.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry['sounds'].extend(records.values())
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(f'Created {len(RECIPES)} candidates; sequence slot {records["sequence"]["id"]}')


if __name__ == '__main__':
    main()
