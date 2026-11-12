#!/usr/bin/env python3
"""Build a gap-free ambient swarm from Sean-approved indoor fly excerpts."""

import array
import hashlib
import json
import math
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100
DURATION = 2.4


def excerpt(candidate: str, start: float, duration: float) -> list[float]:
    """Cut a strong buzzing passage, normalize locally and fade its layering edges."""
    path = ROOT / 'audio/alternatives/DD-S0200' / f'{candidate}.wav'
    with wave.open(str(path)) as source:
        source.setpos(round(start * RATE))
        pcm = array.array('h', source.readframes(round(duration * RATE)))
    values = [float(value) for value in pcm]
    gain = 10 ** (-18 / 20) / max(map(abs, values))
    fade = round(.12 * RATE)
    for index in range(len(values)):
        edge = min(1.0, index / fade, (len(values) - 1 - index) / fade)
        values[index] *= gain * max(0, edge)
    return values


def main() -> None:
    """Append an approved-source production loop without changing the runtime mapping."""
    manifest_path = HERE / 'manifest.json'
    if manifest_path.exists():
        raise FileExistsError('Preserve this delivery')
    size = round(DURATION * RATE)
    values = [0.0] * size
    recipes = [('DD-S0200.7', 1.76, .70, .4, 1.0), ('DD-S0200.6', 4.35, .60, .8, .45)]
    for candidate, start, duration, spacing, gain in recipes:
        clip = excerpt(candidate, start, duration)
        for entry in range(round(DURATION / spacing)):
            at = round((entry * spacing + (.17 if candidate.endswith('.6') else 0)) * RATE)
            for index, value in enumerate(clip):
                values[(at + index) % size] += value * gain
    gain = 10 ** (-14 / 20) / max(map(abs, values))
    pcm = array.array('h', (round(value * gain * 32767) for value in values))
    pcm[-1] = pcm[0]
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    slot = next(s for s in registry['sounds'] if s['key'] == 'swarm_audio.gd/0')
    suffix = max((int(a['id'].split('.')[-1]) for a in slot['alternatives']), default=0) + 1
    identity = f"{slot['id']}.{suffix}"
    runtime = ROOT / 'assets/audio/sfx/gnatastrophe-recorded-v5/swarm-loop.wav'
    alternative = ROOT / 'audio/alternatives' / slot['id'] / f'{identity}.wav'
    for path in [runtime, alternative]:
        if path.exists():
            raise FileExistsError(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(pcm.tobytes())
    manifest_relative = str(manifest_path.relative_to(ROOT))
    slot['alternatives'].append({'id': identity, 'path': str(alternative.relative_to(ROOT)),
        'name': 'ACCEPTED SOURCES · dense indoor swarm · gap-free 2.4s loop',
        'source_manifest': manifest_relative, 'source_candidates': ['DD-S0200.7', 'DD-S0200.6'],
        'provenance': 'CC0 BeeProductive indoor fly recording; approved excerpts, periodic overlap edits.',
        'review_status': 'Sean approved .6/.7; Audio chose .7 as main body with .6 support. In-game review pending.'})
    slot['selected_candidate'] = identity
    for s in registry['sounds']:
        for candidate in s['alternatives']:
            if candidate['id'] in ['DD-S0200.6', 'DD-S0200.7']:
                candidate['review_status'] = 'Accepted by Sean; trim quiet passages; Audio may choose either/both.'
    rms_windows = []
    for start in range(0, size, RATE // 20):
        window = pcm[start:start + RATE // 20]
        rms = math.sqrt(sum(v * v for v in window) / len(window)) / 32767
        rms_windows.append(20 * math.log10(max(rms, 1e-9)))
    manifest = {'date': '2026-11-11', 'status': 'Ready for Engineering mapping; in-game listening pending',
        'selected_candidate': identity, 'runtime': str(runtime.relative_to(ROOT)), 'gain_db': -8, 'loop': True,
        'duration_seconds': DURATION, 'sha256': hashlib.sha256(runtime.read_bytes()).hexdigest(),
        'recipe': str(Path(__file__).relative_to(ROOT)), 'layers_candidate_start_duration_spacing_gain': recipes,
        'source_manifest': 'audio/sources/gnatastrophe-clean-flies-v4/manifest.json',
        'quietest_50ms_rms_dbfs': min(rms_windows), 'loudest_50ms_rms_dbfs': max(rms_windows),
        'loop_boundary_step_pcm': abs(pcm[-1] - pcm[0]),
        'integration': ['Replace only scripts/swarm_audio.gd LOOP; preserve one shared proximity voice and -8dB cap.',
                        'No new attack/death cues selected: leave those mappings unchanged.',
                        'Preserve pause/mute/death/retry cleanup. Do not restart the loop on swarm phase changes.']}
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(identity, min(rms_windows), max(rms_windows))


if __name__ == '__main__':
    main()
