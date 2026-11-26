"""Build a spatial audit of the current Normal course; never changes runtime geometry."""
import hashlib
import html
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
START = 300
CELL = 320
ROWS = [("Far", 230, 296.6666666667), ("Middle", 296.6666666667, 363.3333333333),
        ("Near", 363.3333333333, 430)]
SYMBOLS = {"support": "D", "low_barrier": "J", "gap": "H", "deck": "P"}
COLORS = {"D": "#e89468", "J": "#edcb66", "H": "#548cbd", "P": "#96d8b0"}
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
SOURCES = ["levels/level-two-ride-continuous.json", "levels/level-two-ride-showcase.json",
           "scripts/ride_continuous_course.gd", "scripts/ride_showcase_model.gd"]


def bounds(obstacle: dict) -> list[float]:
    """Return the authored rectangle before board-footprint collision rules."""
    return [obstacle["x"] - obstacle["width"] / 2, obstacle["x"] + obstacle["width"] / 2,
            obstacle["y"] - obstacle["depth"] / 2, obstacle["y"] + obstacle["depth"] / 2]


def main() -> None:
    """Write exact obstacle records, occupied cells, a readable page, and map previews."""
    source = json.loads((OUT / "composed.json").read_text())
    columns = math.ceil((source["variants"][0]["world_finish"] - START) / CELL)
    result = {"title": "Wave 1 — current Normal spatial audit", "date": "2026-11-24",
              "baseline": "Prototype 200 movement; current source geometry",
              "status": "Retrospective map, not generator input or a newly validated route",
              "cell_length": CELL, "origin_x": START, "columns": columns, "rows": ROWS,
              "source_sha256": {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in SOURCES},
              "movement": {k: source[k] for k in ["scroll_speed", "x_speed", "bank_speed", "steering", "jump"]},
              "variants": []}
    page = ['<!doctype html><html lang="en"><meta charset="utf-8"><title>Wave 1 grid audit</title>',
            '<style>body{background:#10212b;color:#e4ecee;font:17px system-ui;max-width:1500px;margin:40px auto;',
            'padding:24px}a{color:#8cdbc5}img{width:100%}table{border-collapse:collapse;width:100%;font-size:14px}',
            'td,th{padding:7px;border:1px solid #42606d;text-align:left}code{color:#edcb66}</style>',
            '<h1>Wave 1: the course we actually have</h1>',
            '<p>Normal · Prototype 200 movement · 3 banks × 44 columns · 320 world pixels per column.',
            'World x=300–14300; last column ends at 14300 rather than 14380. Travel is left to right.</p>',
            '<p><b>D</b> dodge solid · <b>J</b> low jump barrier · <b>H</b> hole · <b>P</b> landing platform.',
            'No ramps or elbow breach are present in this slice. A dot means no mapped footprint, '
            'not a safe route.</p>',
            '<p>Letters mark ANY positive-area overlap with a cell. H+P preserves the cap-over-hole layering.',
            'Two H cells may be one short hole crossing a column boundary. '
            'Object IDs and exact bounds are authoritative;',
            'Counting occupied cells does not determine jumpability. '
            'Blue holes show their eventual open footprint.</p>',
            '<p>Rows divide water y=230–430 into equal bands; steering is continuous (rider centers y=260–400).',
            'Partial-lane overlaps are retained. The exact rectangles shown under each grid are not collision masks:',
            'board footprint, 65% pit overlap, cap support and timed machinery still apply.</p>',
            '<h2>Working scale, not a committed tile system</h2>',
            '<p>Neutral flight covers 336 px in 0.6 s; maximum forward travel is 540 px before support tolerance.',
            'One 320 px cell leaves only 16 px of neutral-flight travel margin; this is not a generous or universally',
            'safe jump. Two full cells (640 px) match tested unjumpable long cuts. Keep exact footprints until',
            'Cell-aligned layouts need actual-model validation. '
            'A slow approach can make even one cell too long.</p>',
            '<h2>Actual pacing</h2><p>Opening slalom: x1410–4360 with three interleaved flanges.',
            'Standalone flange pair: 5188–5284. Staggered caps over a 970 px gap: 7241.25–8325.',
            'Machinery and mixed beats: 9518–13300. Exit baffle: 13670–13790. Finish: 14300.</p>',
            '<p>The largest footprint-free interval is x5284–7241.25: 1957.25 px, about 3.50 s at neutral scroll.',
            'Other intervals include 4360–5188 (1.48 s) and 8325–9518 (2.13 s). These measure geometry gaps,',
            'not guaranteed rest: board clearance, jump recovery, steering and overhead cues consume some time.',
            'No gaps have been shortened by this mapping task.</p>',
            '<h2>Timing and retries</h2><p>Each strainer warning begins at timeline_origin+1.25 s; impact opens',
            'the gap at +3.10 s; its jump volume clears at +3.25 s. Origins use upstream edge:',
            '(x − width/2 − 2540)/560 plus seeded ±0.12 s jitter. The overhead grate supplies the warning.',
            'The layouts below represent both mirrored arrangements; other seeds also vary timing.',
            'Retries retain the seed. No formal checkpoint is designed; legacy retry coordinates in course data',
            'are not player checkpoints. Campaign retries start at the bowl; '
            'direct course launches restart the slalom.</p>',
            '<p>Easy/Hard are not mapped here: their slalom spacing is 470/380 versus Normal 410, and subsequent',
            'geometry shifts by +420/−210 px. This is the whole current continuous slice, called Wave 1 here;',
            'its internal two groups of three strainers are not the proposed future Wave 2 and Wave 3.</p>']
    for variant in source["variants"]:
        obstacles = sorted(variant["obstacles"], key=lambda o: o["x"])
        cells = []
        for name, low, high in ROWS:
            row = []
            for col in range(columns):
                left, right = START + col * CELL, min(START + (col + 1) * CELL, variant["world_finish"])
                hits = [o for o in obstacles if bounds(o)[0] < right and bounds(o)[1] > left
                        and bounds(o)[2] < high - 1e-8 and bounds(o)[3] > low + 1e-8]
                row.append({"column": col + 1, "symbols": ''.join(sorted({SYMBOLS[o["kind"]] for o in hits})),
                            "obstacle_ids": [o["id"] for o in hits]})
            cells.append({"bank": name, "cells": row})
        assert {o["id"] for o in obstacles} == {i for r in cells for c in r["cells"] for i in c["obstacle_ids"]}
        assert len(obstacles) == 27
        result["variants"].append({"seed": variant["seed"], "cells": cells, "obstacles": obstacles})
        image = Image.new("RGB", (1800, 1730), "#10212b")
        draw = ImageDraw.Draw(image)
        fonts = {s: ImageFont.truetype(FONT, s) for s in [18, 22, 26, 34]}
        draw.text((40, 25), f'WAVE 1 / NORMAL / SEED {variant["seed"]}', font=fonts[34], fill="#e4ecee")
        draw.text((40, 78), "D dodge   J jump barrier   H hole   P platform   . no footprint   |   320 px per column",
                  font=fonts[22], fill="#96d8b0")
        draw.text((40, 112), "Top: occupied cells. Below: exact footprints. Travel →    Not a validated route.",
                  font=fonts[22], fill="#e4ecee")
        for panel, first in enumerate(range(0, columns, 11)):
            y = 175 + panel * 375
            count = min(11, columns - first)
            scale = 140 / CELL
            x_origin = START + first * CELL
            draw.text((40, y), f'Columns {first + 1}–{first + count} / x {x_origin}–'
                      f'{min(START + (first + count) * CELL, variant["world_finish"]):g}',
                      font=fonts[22], fill="#e4ecee")
            for row_index, row in enumerate(cells):
                draw.text((40, y + 55 + row_index * 42), row["bank"], font=fonts[22], fill="#e4ecee")
                for local in range(count):
                    x, top = 170 + local * 140, y + 45 + row_index * 42
                    draw.rectangle((x, top, x + 140, top + 42), outline="#42606d")
                    label = row["cells"][first + local]["symbols"] or "."
                    draw.text((x + 44, top + 7), label, font=fonts[26], fill=COLORS.get(label, "#e4ecee"))
            top = y + 210
            draw.rectangle((170, top, 170 + count * 140, top + 110), fill="#193c45", outline="#42606d")
            for o in sorted(obstacles, key=lambda item: item["kind"] == "deck"):
                left, right, low, high = bounds(o)
                left, right = max(left, x_origin), min(right, x_origin + count * CELL, variant["world_finish"])
                if right <= left:
                    continue
                x0, x1 = 170 + (left - x_origin) * scale, 170 + (right - x_origin) * scale
                yy0, yy1 = top + (low - 230) * .55, top + (high - 230) * .55
                draw.rectangle((x0, yy0, max(x1, x0 + 2), yy1), fill=COLORS[SYMBOLS[o["kind"]]])
            for local in range(count + 1):
                x = 170 + local * 140
                draw.line((x, top, x, top + 110), fill="#42606d")
                if local < count:
                    draw.text((x + 55, top + 115), str(first + local + 1), font=fonts[18], fill="#e4ecee")
            for line in [1, 2]:
                draw.line((170, top + line * 110 / 3, 170 + count * 140, top + line * 110 / 3), fill="#42606d")
        draw.text((40, 1690), "Exact widths and object IDs override letter counts. H+P is layered support over a gap.",
                  font=fonts[22], fill="#e4ecee")
        name = f'normal-seed-{variant["seed"]}.png'
        image.save(OUT / name)
        page.append(f'<h2>Seed {variant["seed"]}: mirrored strainer arrangement</h2>'
                    f'<img src="{name}" alt="Three-bank grid">')
        page.append('<details><summary>Exact obstacle register and timed events</summary><table><tr><th>ID</th>'
                    '<th>Letter</th><th>x bounds</th><th>y bounds</th><th>Warning / open / clear (s)</th></tr>')
        for o in obstacles:
            b = bounds(o)
            timing = (f'{o["warning_at"]:.3f} / {o["activates_at"]:.3f} / {o["timeline_origin"] + 3.25:.3f}'
                      if o.get("station") else "—")
            page.append(f'<tr><td>{html.escape(o["id"])}</td><td>{SYMBOLS[o["kind"]]}</td>'
                        f'<td>{b[0]:g}–{b[1]:g}</td><td>{b[2]:g}–{b[3]:g}</td><td>{timing}</td></tr>')
        page.append('</table></details>')
    page.append('<h2>Reproduction and limits</h2><p>Run export.gd using project Godot headless, then run build_map.py.',
                )
    page.append('map.json contains source hashes, all 27 objects per variant, exact timings and per-cell object IDs.',
                )
    page.append('Export completed with a macOS certificate warning; JSON and coverage checks passed.',
                )
    page.append('No runtime geometry, checkpoints or seeded behavior changed.</p>'
                '<a href="map.json">Machine-readable map</a></html>')
    (OUT / "map.json").write_text(json.dumps(result, indent=2) + "\n")
    (OUT / "index.html").write_text('\n'.join(page) + "\n")
    print(f'Validated {len(result["variants"])} variants, 27 objects each, {columns} columns × 3 banks.')


if __name__ == "__main__":
    main()
