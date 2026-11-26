#!/usr/bin/env python3
"""Bring continuous panicked vocal energy forward in the preferred underwater special."""

import array
import hashlib
import importlib.util
import json
import math
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location('helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
BASE = 'audio/alternatives/DD-S0206/DD-S0206.8.wav'
BRIEF = ('Keep DD-S0206.8 underwater texture; make screaming louder, more panicked and present throughout. '
         'DD-S0205.7 is preferred for normal. No runtime integration until final selection. '
         'Layer retained human cries with overlapping phrases and water-driven amplitude variation, no cough montage.')


def main() -> None:
    """Write two versioned vocal-forward choices and preserve all original sources."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve delivery')
    with wave.open(str(ROOT / BASE)) as source:
        water = [v / 32767 for v in array.array('h', source.readframes(source.getnframes()))]
    sources = [{'path': BASE, 'sha256': hashlib.sha256((ROOT / BASE).read_bytes()).hexdigest(),
                'source_manifest': 'audio/sources/flush-button-v3/manifest.json'}]
    for key in ['scream_01', 'scream_02']:
        path = f'audio/sources/recorded-creatures-cc0-v1/rubberduck/{key}.ogg'
        H.SOURCES[key] = (path, 'audio/sources/recorded-creatures-cc0-v1/manifest.json', 'rubberduck', 'CC0-1.0')
        sources.append({'path': path, 'author': 'rubberduck', 'license': 'CC0-1.0',
                        'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
                        'source_manifest': H.SOURCES[key][1]})
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    normal = next(r for r in registry['sounds'] if r['id'] == 'DD-S0205')
    next(a for a in normal['alternatives'] if a['id'] == 'DD-S0205.7')['review_status'] = (
        'Preferred normal-attack candidate: Sean says pretty good. No runtime integration requested in this turn.')
    special = next(r for r in registry['sounds'] if r['id'] == 'DD-S0206')
    next(a for a in special['alternatives'] if a['id'] == 'DD-S0206.8')['review_status'] = (
        'Promising direction; revise with louder panicked screaming throughout, not just murmur at end.')
    outputs = []
    for label, gain, pitch in [('I — Continuous panicked voice through water', .95, 1.02),
                               ('J — More urgent, voice-forward gurgle scream', 1.35, 1.10)]:
        vocal = [0.0] * len(water)
        events = []
        for index, at in enumerate([0, .52, 1.04, 1.56, 2.08, 2.60, 3.12]):
            key = ['scream_01', 'scream_02'][index % 2]
            speed = pitch + [0, .035, -.015, .05][index % 4]
            gesture = H.cut(H.load(key, speed, 160, 3400), .77)
            # Broad crossfades avoid a sequence of separate yelps; water texture modulates the voice too.
            for i in range(min(round(.13 * H.RATE), len(gesture))):
                gesture[i] *= i / (.13 * H.RATE)
                gesture[-i - 1] *= i / (.13 * H.RATE)
            start = round(at * H.RATE)
            for i, value in enumerate(gesture[:len(vocal) - start]):
                vocal[start + i] += value
            events.append({'source': key, 'at': at, 'speed': speed, 'duration': .77})
        # Smooth rectified water amplitude retains irregular liquid interruptions without digital tremolo.
        envelope = 0.0
        result = []
        for liquid, voice in zip(water, vocal):
            envelope += .012 * (abs(liquid) - envelope)
            wet_voice = voice * (.42 + .58 * min(1, envelope * 18))
            result.append(liquid * 1.1 + math.tanh(wet_voice * 1.4) * gain)
        fade = round(.08 * H.RATE)
        for i in range(fade):
            result[i] *= i / fade
            result[-i - 1] *= i / fade
        candidate = 'DD-S0206.' + str(max(int(a['id'].split('.')[-1]) for a in special['alternatives']) + 1)
        evidence = H.write(ROOT / 'audio/alternatives/DD-S0206' / f'{candidate}.wav', H.normalize(result, -6))
        special['alternatives'].append({'id': candidate, 'path': evidence['path'], 'name': label,
                                        'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                                        'provenance': 'Preferred ftpalad underwater gargle plus rubberduck CC0 human cries.'})
        outputs.append({'id': candidate, 'description': label, 'vocal_gain': gain, 'events': events, **evidence})
    (HERE / 'manifest.json').write_text(json.dumps({
        'date': '2026-11-25', 'status': 'Special revisions awaiting listening; normal .7 preferred; no runtime changes',
        'brief': BRIEF, 'sources': sources, 'outputs': outputs, 'processing': H.PROCESSING,
        'recipe': str(Path(__file__).relative_to(ROOT)),
        'listening': 'Designed layered approximations. Technical validation is not subjective acceptance.'
    }, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['description']) for o in outputs])


if __name__ == '__main__':
    main()
