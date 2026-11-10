#!/usr/bin/env python3
"""Render material-led creature auditions from retained CC0 recordings."""

import hashlib
import importlib.util
import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'audio_helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
HELPERS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPERS)
BRIEF = (
    'Material-led creature audio: dangerous, disturbing and physical, with distinct creature identities. '
    'Recorded foley and performed organic textures replace electronic beep-boop character. '
    'Short action-bound gestures leave space for music and crowds. Preserve all approved sounds and originals. '
    'These are designed fictional effects, not field recordings of the represented animals or materials.'
)


def main() -> None:
    """Render explicit layers, register auditions and keep runtime selections unchanged."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Use a new version; preserve this delivery.')
    plan = json.loads((HERE / 'plan.json').read_text())
    for name in ['burble_01', 'burble_02', 'eat_01', 'eat_02', 'eat_04', 'spit_01', 'spit_02',
                 'spit_03', 'bug_01', 'bug_02', 'bug_03', 'bug_04', 'breath', 'hurt_03', 'scream_02']:
        HELPERS.SOURCES[name] = (
            f'audio/sources/recorded-creatures-cc0-v1/rubberduck/{name}.ogg',
            'audio/sources/recorded-creatures-cc0-v1/manifest.json', 'rubberduck', 'CC0-1.0')
    for name, filename in [('glass', 'bfh1_glass_breaking_02'), ('stone', 'bfh1_rock_breaking_01')]:
        HELPERS.SOURCES[name] = (
            f'audio/sources/flushfiend-shatter-v1/{filename}.ogg',
            'audio/sources/flushfiend-shatter-v1/manifest.json', 'rubberduck', 'CC0-1.0')
    registry_path = ROOT / 'audio/sound-registry.json'
    registry = json.loads(registry_path.read_text())
    records = {record['key']: record for record in registry['sounds']}
    number = max(int(record['id'].split('S')[-1]) for record in registry['sounds']) + 1
    cache: dict[tuple, list[float]] = {}
    outputs: list[dict] = []
    previews: dict[str, list[tuple[str, list[float]]]] = {}

    def register(key: str, group: str, label: str, values: list[float], details: dict) -> None:
        """Append one permanent candidate without promoting it into the game."""
        nonlocal number
        if key not in records:
            records[key] = {
                'id': f'DD-S{number:04d}', 'uuid': str(uuid.uuid4()), 'key': key,
                'section': 'Level 1', 'group': group + ' material auditions — NOT IN GAME',
                'name': label, 'paths': [], 'source': MANIFEST, 'status': 'proposed', 'alternatives': []}
            registry['sounds'].append(records[key])
            number += 1
        record = records[key]
        suffix = max((int(a['id'].split('.')[-1]) for a in record['alternatives']), default=0) + 1
        identity = f"{record['id']}.{suffix}"
        evidence = HELPERS.write(ROOT / 'audio/alternatives' / record['id'] / f'{identity}.wav', values)
        record['alternatives'].append({
            'id': identity, 'path': evidence['path'],
            'name': f'MATERIALS v1 · {group} · {label} · {evidence["duration_seconds"]:.2f}s',
            'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
            'provenance': 'Layered CC0 recorded-source design; source hashes and recipe in manifest.'})
        outputs.append({'id': identity, 'key': key, 'creature': group, 'label': label, **evidence, **details})

    for cue in plan['cues']:
        layers = []
        for source, speed, high, low, at, length, offset, gain, reverse in cue['layers']:
            cache_key = (source, speed, high, low)
            if cache_key not in cache:
                cache[cache_key] = HELPERS.load(source, speed, high, low)
            values = HELPERS.cut(cache[cache_key], length, offset, reverse)
            layers.append((at, values, gain))
        values = HELPERS.mix(cue['duration'], layers)
        # End the whole gesture smoothly even when a layered recording runs beyond the event window.
        fade = min(round(.075 * HELPERS.RATE), len(values) // 3)
        for index in range(fade):
            values[-index - 1] *= index / fade
        values = HELPERS.normalize(values, cue['peak_dbfs'])
        register(cue['key'], cue['creature'], cue['label'], values, {
            'layers': cue['layers'], 'integration': cue['integration'], 'loop': False})
        previews.setdefault(cue['creature'], []).append((outputs[-1]['id'], values))
    for creature, clips in previews.items():
        at = .3
        layers = []
        timeline = []
        for identity, values in clips:
            layers.append((at, values, 1.0))
            timeline.append({'candidate': identity, 'at_seconds': round(at, 3)})
            at += len(values) / HELPERS.RATE + .65
        key = 'proposed-creature-materials/preview-' + creature.lower().replace(' ', '-')
        register(key, creature, 'START HERE — spaced cue reel', HELPERS.mix(at, layers), {
            'timeline': timeline, 'integration': 'Audition reel only; gaps are not gameplay timing.', 'loop': False})
    sources = {}
    for key in {item['source'] for item in HELPERS.PROCESSING}:
        path, evidence, author, license_name = HELPERS.SOURCES[key]
        sources[key] = {
            'path': path, 'sha256': hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
            'license_evidence': evidence, 'author': author, 'license': license_name}
    manifest = {
        'date': '2026-11-05', 'status': 'Auditions only; selection, runtime integration and listening pending',
        'brief': BRIEF, 'recipe': str(Path(__file__).relative_to(ROOT)),
        'plan': str((HERE / 'plan.json').relative_to(ROOT)), 'consultation': plan['consultation'],
        'sources': sources, 'processing': HELPERS.PROCESSING, 'outputs': outputs,
        'mix_contract': plan['mix_contract'], 'preserved': plan['preserved']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(f'Created {len(outputs)} auditions, including {len(previews)} creature reels.')


if __name__ == '__main__':
    main()
