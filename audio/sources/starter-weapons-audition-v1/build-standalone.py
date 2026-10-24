#!/usr/bin/env python3
"""Package every weapon audition into one portable HTML file with embedded WAV audio."""

import base64
import hashlib
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / 'drain-damage-all-weapon-auditions.html'


def main() -> None:
    """Preserve exact audio bytes and mark the selected IDs in a self-contained document."""
    original = json.loads((ROOT / 'manifest.json').read_text())
    second = json.loads((ROOT / 'water-round-2/manifest.json').read_text())
    choices = original['choices'] + second['choices']
    selection = json.loads((ROOT.parents[2] / 'handoffs/starter-weapon-audio.json').read_text())
    selected = {selection[hero]['selected_id'] for hero in ['tony', 'sean']}
    style = (ROOT / 'index.html').read_text().split('<style>')[1].split('</style>')[0]
    parts = ['<!doctype html>\n<html lang="en"><head><meta charset="utf-8">',
             '<meta name="viewport" content="width=device-width, initial-scale=1">',
             '<title>Drain Damage — all weapon auditions</title><style>', style,
             '.selected { background: #253f36; } .badge { color: #a7f4c1; font-weight: 700; }',
             'button { padding: 10px 18px; cursor: pointer; }',
             '</style></head><body><header><div class="tag">Drain Damage · October 23, 2026</div>',
             '<h1>All weapon sound auditions</h1>',
             '<p>Sean selected <strong>T11 — Water gush</strong> for Tony and '
             '<strong>S1 — Suction pop</strong> for Sean. All 17 choices remain here for Tony to compare.</p>',
             '<p>This single file contains every sound, including all five-shot demos. '
             'Save or share the HTML file itself; no internet connection or companion folder is needed. '
             'Open it in a web browser and press any player. Nothing plays automatically.</p>',
             '<button id="stop" type="button">Stop all sounds</button></header>']
    for prefix, heading in [('T', 'Tony’s water gun'), ('S', 'Sean’s plunger gun')]:
        parts.extend([f'<section><h2>{heading}</h2>',
                      '<p>Each row offers one shot and a five-shot demo. '
                      + ('T1–T6 are round one; T7–T11 are the water-focused second round.' if prefix == 'T' else '')
                      + '</p><div class="table-wrap"><table>',
                      f'<caption hidden>{heading} auditions</caption>',
                      '<thead><tr><th scope="col">ID</th><th scope="col">Sound</th>'
                      '<th scope="col">Single shot</th><th scope="col">Five shots</th></tr></thead><tbody>'])
        group = sorted((c for c in choices if c['id'].startswith(prefix)), key=lambda c: int(c['id'][1:]))
        for choice in group:
            identity = choice['id']
            row_class = ' class="selected"' if identity in selected else ''
            badge = '<small class="badge">Selected by Sean</small>' if identity in selected else ''
            parts.append(f'<tr{row_class}><th scope="row">{identity}</th>'
                         f'<td><strong>{html.escape(choice["name"])}</strong>{badge}'
                         f'<small>{html.escape(choice["description"])}</small></td>')
            for kind, label in [('single', 'single shot'), ('repeated', 'five-shot demo')]:
                entry = choice[kind]
                payload = (ROOT / entry['path']).read_bytes()
                assert hashlib.sha256(payload).hexdigest() == entry['sha256']
                encoded = base64.b64encode(payload).decode('ascii')
                parts.append(f'<td><audio controls preload="none" aria-label="{identity} {label}" '
                             f'data-sha256="{entry["sha256"]}" src="data:audio/wav;base64,{encoded}">'
                             'Open this file in a browser that supports WAV audio.</audio></td>')
            parts.append('</tr>')
        parts.append('</tbody></table></div></section>')
    parts.extend(['<details><summary>About these sounds</summary>',
                  '<p>Original project-generated synthesis, not recordings of real water or rubber. '
                  'No third-party samples or attribution obligations. Audio is embedded without re-encoding: '
                  'mono, 44.1 kHz, 16-bit PCM WAV.</p>',
                  '<p>Single shots target −24 dBFS RMS, with a −9 dBFS peak ceiling. '
                  'This does not guarantee equal perceived loudness. Five-shot demos use 160 ms spacing '
                  'for Tony and 240 ms for Sean; these are audition timing examples.</p></details>',
                  '<script>\nconst players = [...document.querySelectorAll("audio")];\n'
                  'for (const player of players) {\n'
                  '  player.addEventListener("play", () => {\n'
                  '    for (const other of players) if (other !== player) other.pause();\n'
                  '  });\n}\n'
                  'document.querySelector("#stop").addEventListener("click", () => {\n'
                  '  for (const player of players) { player.pause(); player.currentTime = 0; }\n'
                  '});\n</script></body></html>'])
    OUTPUT.write_text('\n'.join(parts) + '\n')
    print(f'Created {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)')


if __name__ == '__main__':
    main()
