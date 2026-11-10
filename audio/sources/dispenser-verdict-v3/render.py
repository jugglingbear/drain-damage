#!/usr/bin/env python3
"""Create distinct positive ding and negative verdict alarm for the checkpoint inspector."""

import array
import hashlib
import json
import math
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RATE = 44100
BRIEF = (
    'Full-health checkpoint inspection displays green check with a short happy positive ding and safe set-down. '
    'Injured hero displays red X with a distinct error/klaxon before progressive crushing. '
    'Brief readable verdicts, no speech, no continuous alarm, no changes to existing throw/splat.'
)


def main() -> None:
    """Render original sample-free cues, preserving all older dispenser sounds."""
    outputs = []
    for event, duration in [('inspection-pass', .42), ('inspection-fail', .5)]:
        path = ROOT / 'assets/audio/sfx/dispenser-verdict-v3' / f'{event}.wav'
        if path.exists():
            raise FileExistsError(path)
        samples = []
        for i in range(round(duration * RATE)):
            t = i / RATE
            if event == 'inspection-pass':
                value = (math.sin(math.tau * 1046.5 * t) + .35 * math.sin(math.tau * 2093 * t)) * math.exp(-t * 9)
                if t >= .07:
                    x = t - .07
                    value += .55 * math.sin(math.tau * 1568 * x) * math.exp(-x * 10) * min(1, x / .005)
            else:
                local = t if t < .23 else t - .27
                gate = min(1, max(0, local) / .008, max(0, .2 - local) / .025)
                frequency = 330 if t < .23 else 277
                value = gate * (math.sin(math.tau * frequency * t)
                                + .45 * math.sin(math.tau * frequency * 1.07 * t)
                                + .22 * math.sin(math.tau * frequency * 3 * t))
            value *= min(1, t / .006, (duration - 1 / RATE - t) / .035)
            samples.append(value)
        gain = 10 ** (-14 / 20) / max(map(abs, samples))
        pcm = array.array('h', (round(v * gain * 32767) for v in samples))
        path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(path), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(pcm.tobytes())
        outputs.append({'cue_id': event, 'path': str(path.relative_to(ROOT)), 'duration_seconds': duration,
                        'gain_db': -3, 'peak_dbfs': -14, 'loop': False,
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'date': '2026-11-05', 'brief': BRIEF,
                'status': 'Verdict cues rendered; event mapping pending coordination',
                'recipe': str(Path(__file__).relative_to(ROOT)), 'cues': outputs,
                'provenance': 'Original sample-free sine/inharmonic synthesis; no third-party samples or voice models.',
                'mix': 'Pass is a bright consonant bell; fail is a low descending dissonant double buzzer.',
                'trigger': 'Once with visible verdict; never layer pass/fail or repeat with HP display.',
                'validation_limit': 'Technical validation only; in-game balance remains unverified.'}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print([(c['cue_id'], c['duration_seconds']) for c in outputs])


if __name__ == '__main__':
    main()
