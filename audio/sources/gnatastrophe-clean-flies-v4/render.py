#!/usr/bin/env python3
"""Compare indoor fly-cloud recordings with a filtered edit of the outdoor candidate."""

import hashlib
import importlib.util
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MANIFEST = str((HERE / 'manifest.json').relative_to(ROOT))
SPEC = importlib.util.spec_from_file_location(
    'helpers', ROOT / 'audio/sources/starter-specials-auditions-v1/generate.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
BRIEF = (
    'Sean likes actual fly buzz but hears birds at the beginning of DD-S0200.3 and water-like ambience in .4/.5. '
    'Compare a new indoor fly recording with a cropped, band-limited cleanup of .3. '
    'Preserve original recordings and candidates; audition only. Background isolation is not guaranteed.'
)


def main() -> None:
    """Append three six-second candidates with processing and CC0 source provenance."""
    if (HERE / 'manifest.json').exists():
        raise FileExistsError('Preserve this version')
    source = HERE / 'indoor-fly-hq.mp3'
    clean = HERE / 'indoor-fly-denoised.wav'
    filters = 'highpass=f=220,lowpass=f=6500,afftdn=nr=10:nf=-35:tn=1'
    subprocess.run(['ffmpeg', '-v', 'error', '-n', '-i', str(source), '-af', filters,
                    '-ar', '44100', '-ac', '1', str(clean)], check=True)
    H.SOURCES['indoor'] = (str(clean.relative_to(ROOT)), MANIFEST, 'BeeProductive', 'CC0-1.0')
    H.SOURCES['outdoor'] = ('audio/alternatives/DD-S0200/DD-S0200.3.wav',
                            'audio/sources/gnatastrophe-real-flies-v3/manifest.json', 'PuzzleAudio', 'CC0-1.0')
    choices = [
        ('A — Indoor flies, natural buzz', 'indoor',
         [(1.0, 250, 6000, 4, .9), (1.03, 300, 6000, 16, .6)]),
        ('B — Indoor flies, dense cloud', 'indoor',
         [(.96, 230, 5500, 2, .7), (1.0, 250, 6000, 9, .8),
          (1.04, 300, 6000, 17, .6), (1.08, 400, 6500, 21, .4)]),
        ('C — Earlier close flies, cropped and filtered', 'outdoor',
         [(1.0, 250, 1700, 1.5, 1.0)]),
    ]
    rp = ROOT / 'audio/sound-registry.json'
    registry = json.loads(rp.read_text())
    slot = next(s for s in registry['sounds'] if s['id'] == 'DD-S0200')
    suffix = max(int(c['id'].split('.')[-1]) for c in slot['alternatives']) + 1
    outputs = []
    for index, (name, key, recipe) in enumerate(choices):
        duration = 4.4 if key == 'outdoor' else 6.0
        layers = [(0, H.cut(H.load(key, speed, high, low), duration, offset), gain)
                  for speed, high, low, offset, gain in recipe]
        values = H.mix(duration, layers)
        for sample in range(round(.12 * H.RATE)):
            values[sample] *= sample / round(.12 * H.RATE)
        for sample in range(round(.3 * H.RATE)):
            values[-sample - 1] *= sample / round(.3 * H.RATE)
        identity = f'DD-S0200.{suffix + index}'
        evidence = H.write(ROOT / 'audio/alternatives/DD-S0200' / f'{identity}.wav', H.normalize(values, -12))
        candidate = {'id': identity, 'path': evidence['path'], 'name': f'CLEAN FLIES v4 · {name}',
                     'source_manifest': MANIFEST, 'generation_prompt': BRIEF,
                     'provenance': 'CC0 BeeProductive indoor flies, or processed PuzzleAudio outdoor recording.'}
        slot['alternatives'].append(candidate)
        outputs.append({**candidate, **evidence, 'source_key': key, 'layers': recipe})
    manifest = {
        'date': '2026-11-11', 'status': 'Audition only; subjective residual-noise review pending', 'brief': BRIEF,
        'recipe': str(Path(__file__).relative_to(ROOT)), 'outputs': outputs, 'processing': H.PROCESSING,
        'indoor_source': {'author': 'BeeProductive', 'title': 'Fly.wav', 'license': 'CC0-1.0',
                          'page': 'https://freesound.org/people/BeeProductive/sounds/395593/',
                          'description': 'Author describes a fly buzzing around a room.',
                          'download': (HERE / 'source-url.txt').read_text().strip(),
                          'path': str(source.relative_to(ROOT)),
                          'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                          'license_evidence': str((HERE / 'source-page.html').relative_to(ROOT)),
                          'format_note': 'Public HQ MP3 preview, not original lossless WAV.',
                          'preprocess': filters},
        'outdoor_source': 'audio/sources/gnatastrophe-real-flies-v3/manifest.json',
        'notes': ['A/B use indoor source only, with mild spectral denoising before layering.',
                  'C removes first 1.5s of prior A and attenuates high-frequency bird/noise energy.',
                  'C also loses upper buzz detail; filtering cannot perfectly separate overlapping sources.',
                  'No channel isolation claim: source is mixed to mono. All previous candidates retained.']}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    rp.write_text(json.dumps(registry, indent=2) + '\n')
    print([(o['id'], o['duration_seconds']) for o in outputs])


if __name__ == '__main__':
    main()
