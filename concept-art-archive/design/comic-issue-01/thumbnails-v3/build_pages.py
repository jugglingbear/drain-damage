"""Integrate exact, editable dialogue into full-panel comic compositions."""

from __future__ import annotations

import json
import math
from functools import lru_cache
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 1000, 1550
SIZE, LEADING = 20.5, 24
INK = HexColor('#282521')
WHITE = HexColor('#fffef8')


def wrap(text: str, maximum: float) -> list[str]:
    """Find balanced lines within the requested width without changing the type size."""
    words = text.split()

    @lru_cache(None)
    def width(start: int, stop: int) -> float:
        return pdfmetrics.stringWidth(' '.join(words[start:stop]), 'Comic', SIZE)

    for count in range(max(1, math.ceil(width(0, len(words)) / maximum)), len(words) + 1):
        target = width(0, len(words)) / count

        @lru_cache(None)
        def partition(start: int, remaining: int) -> tuple[float, tuple[int, ...]]:
            if remaining == 0:
                return (0, ()) if start == len(words) else (math.inf, ())
            best: tuple[float, tuple[int, ...]] = (math.inf, ())
            for stop in range(start + 1, len(words) - remaining + 2):
                length = width(start, stop)
                if length > maximum:
                    break
                rest, breaks = partition(stop, remaining - 1)
                score = rest + (length - target) ** 2
                if score < best[0]:
                    best = (score, (stop, *breaks))
            return best

        cost, breaks = partition(0, count)
        if cost < math.inf:
            starts = (0, *breaks[:-1])
            return [' '.join(words[start:stop]) for start, stop in zip(starts, breaks)]
    raise ValueError(f'Cannot wrap text: {text}')


def speech(canvas: Canvas, text: str, item: dict, previous: list[float] | None) -> dict:
    """Draw a close-fitting balloon whose optional tail stops above the designated head."""
    lines = wrap(text, item['width'])
    w = max(pdfmetrics.stringWidth(line, 'Comic', SIZE) for line in lines) + 34
    h = len(lines) * LEADING + item.get('padding', 18)
    x, top = item['center'] - w / 2, item['top']
    y = HEIGHT - top - h
    fill = HexColor('#edf4e7') if item.get('radio') else WHITE
    if previous and item.get('link'):
        px, pt, pw, ph = previous
        line = canvas.beginPath()
        if top >= pt + ph - 8:
            join_x = max(x + 30, min(px + pw - 30, item['center']))
            line.moveTo(join_x, HEIGHT - pt - ph + 1)
            line.lineTo(join_x, y + h - 1)
        else:
            line.moveTo(px + pw - 1, HEIGHT - pt - ph / 2)
            line.lineTo(x + 1, y + h / 2)
        for color, weight in [(INK, 9), (WHITE, 5)]:
            canvas.setStrokeColor(color)
            canvas.setLineWidth(weight)
            canvas.drawPath(line)
    canvas.setFillColor(fill)
    canvas.setStrokeColor(INK)
    canvas.setLineWidth(1.7)
    if 'target' in item:
        tx, target_top = item['target']
        assert target_top < item['head_top'], item
        ty = HEIGHT - target_top
        side = item.get('edge', 'bottom')
        if side in ('left', 'right'):
            ax = x + 5 if side == 'left' else x + w - 5
            ay = y + h * item.get('anchor', .5)
            start, end = (ax, ay - 6), (ax, ay + 6)
        elif side == 'top':
            ax, ay = x + w * item.get('anchor', .5), y + h - 5
            start, end = (ax - 6, ay), (ax + 6, ay)
        else:
            ax = max(x + 22, min(tx, x + w - 22))
            ay = y + 5
            start, end = (ax - 6, ay), (ax + 6, ay)
        path = canvas.beginPath()
        path.moveTo(*start)
        path.lineTo(tx, ty)
        path.lineTo(*end)
        path.close()
        canvas.drawPath(path, fill=1, stroke=1)
    p = canvas.beginPath()
    p.moveTo(x + 24, y + h - 3)
    p.curveTo(x + w * .35, y + h + 3, x + w * .65, y + h + 3, x + w - 24, y + h - 3)
    p.curveTo(x + w + 8, y + h - 12, x + w + 8, y + 12, x + w - 24, y + 3)
    p.curveTo(x + w * .65, y - 3, x + w * .35, y - 3, x + 24, y + 3)
    p.curveTo(x - 8, y + 12, x - 8, y + h - 12, x + 24, y + h - 3)
    p.close()
    canvas.drawPath(p, fill=1, stroke=1)
    canvas.setFillColor(INK)
    canvas.setFont('Comic', SIZE)
    for index, line in enumerate(lines):
        canvas.drawCentredString(item['center'], HEIGHT - top - 23 - index * LEADING, line)
    return {'text': text, 'lines': lines, 'bounds': [x, top, w, h], 'target': item.get('target')}


def build() -> None:
    """Build the review PDF and measured lettering record from approved dialogue."""
    for name, path in [('Comic', 'comicneue/ComicNeue-Bold.ttf'), ('Display', 'bangers/Bangers-Regular.ttf')]:
        pdfmetrics.registerFont(TTFont(name, str(ROOT.parent / 'fonts' / path)))
    script = json.loads((ROOT.parent / 'opening-script-v2.json').read_text())
    layout = json.loads((ROOT / 'layout.json').read_text())
    canvas = Canvas(str(ROOT / 'opening-layouts-v3.pdf'), pagesize=(477, 738))
    measured: list[dict] = []
    for number, page in enumerate(layout, 1):
        canvas.saveState()
        canvas.scale(477 / WIDTH, 738 / HEIGHT)
        file = ROOT / page['art']
        with Image.open(file) as source:
            iw, ih = source.size
        scale = min(WIDTH / iw, HEIGHT / ih)
        canvas.setFillColor(HexColor('#f8efdf'))
        canvas.rect(0, 0, WIDTH, HEIGHT, fill=1, stroke=0)
        canvas.drawImage(str(file), (WIDTH - iw * scale) / 2, (HEIGHT - ih * scale) / 2,
                         iw * scale, ih * scale)
        for index, panel in enumerate(page['panels']):
            expected = script['pages'][number - 1]['panels'][index]
            rendered: list[str] = []
            previous = None
            for item in panel.get('balloons', []):
                text = item.get('text', expected['dialogue'][item['dialogue']][1])
                result = speech(canvas, text, item, previous)
                measured.append({'page': number, 'panel': index + 1, **result})
                previous = result['bounds']
                rendered.append(text)
            assert ' '.join(rendered) == ' '.join(line[1] for line in expected['dialogue'])
            if 'sfx' in expected:
                canvas.setFont('Display', panel.get('size', 36))
                canvas.setFillColor(INK)
                x, y = panel['sfx']
                canvas.drawString(x, HEIGHT - y, expected['sfx'])
        for caption in page.get('captions', []):
            canvas.setFillColor(INK)
            canvas.setFont(caption.get('font', 'Comic'), caption['size'])
            canvas.drawString(caption['x'], HEIGHT - caption['y'], caption['text'])
        canvas.restoreState()
        canvas.showPage()
    canvas.save()
    (ROOT / 'lettering-measured.json').write_text(json.dumps(measured, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    build()
