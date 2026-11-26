"""Typeset editable dialogue over separately framed thumbnail artwork."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
PAGE_W, PAGE_H = 1000, 1550
FONT_SIZE, LEADING = 20.5, 24
INK = HexColor('#282521')
PAPER = HexColor('#faf4e7')
SCRIPT = json.loads((ROOT.parent / 'opening-script-v2.json').read_text())


def wrap(text: str, maximum: float) -> list[str]:
    """Balance lines instead of leaving a very short final line."""
    words = text.split()
    count = max(1, math.ceil(pdfmetrics.stringWidth(text, 'Comic', FONT_SIZE) / maximum))
    while True:
        target = pdfmetrics.stringWidth(text, 'Comic', FONT_SIZE) / count
        lines: list[str] = []
        current = ''
        for word in words:
            candidate = (current + ' ' + word).strip()
            if current and pdfmetrics.stringWidth(candidate, 'Comic', FONT_SIZE) > target + 14:
                lines.append(current)
                current = word
            else:
                current = candidate
        if current:
            lines.append(current)
        if max(pdfmetrics.stringWidth(line, 'Comic', FONT_SIZE) for line in lines) <= maximum:
            return lines
        count += 1


def clipped_art(canvas: Canvas, file: Path, crop: list[float], area: list[float]) -> dict[str, float]:
    """Place an original image through a PDF panel clipping window, without raster edits."""
    sx, sy, sw, sh = crop
    x, y, width, height = area
    with Image.open(file) as source:
        iw, ih = source.size
    scale = min(width / sw, height / sh)
    left = x + (width - sw * scale) / 2
    top = y + (height - sh * scale) / 2
    canvas.saveState()
    clip = canvas.beginPath()
    clip.rect(left, PAGE_H - top - sh * scale, sw * scale, sh * scale)
    canvas.clipPath(clip, stroke=0)
    canvas.drawImage(str(file), left - sx * scale,
                     PAGE_H - top - (ih - sy) * scale, iw * scale, ih * scale, mask='auto')
    canvas.restoreState()
    return {'left': left, 'top': top, 'scale': scale, 'sx': sx, 'sy': sy}


def point(transform: dict[str, float], source: list[float]) -> tuple[float, float]:
    """Map a source-art mouth position into the page."""
    return (transform['left'] + (source[0] - transform['sx']) * transform['scale'],
            transform['top'] + (source[1] - transform['sy']) * transform['scale'])


def balloon(canvas: Canvas, text: str, center: float, top: float, maximum: float,
            target: tuple[float, float] | None, radio: bool = False,
            previous: list[float] | None = None) -> dict[str, object]:
    """Fit a curved contour to a balanced text block and add a short mouth-directed tail."""
    lines = wrap(text, maximum)
    width = max(pdfmetrics.stringWidth(line, 'Comic', FONT_SIZE) for line in lines) + 36
    height = len(lines) * LEADING + 24
    x, y = center - width / 2, PAGE_H - top - height
    if previous:
        px, py, pw, ph = previous
        join = canvas.beginPath()
        join.moveTo(px + pw - 1, PAGE_H - py - ph / 2)
        join.lineTo(x + 1, y + height / 2)
        canvas.setStrokeColor(INK)
        canvas.setLineWidth(10)
        canvas.drawPath(join)
        canvas.setStrokeColor(HexColor('#fffef8'))
        canvas.setLineWidth(6)
        canvas.drawPath(join)
    canvas.setStrokeColor(INK)
    canvas.setLineWidth(1.8)
    canvas.setFillColor(HexColor('#ecf5e8') if radio else HexColor('#fffef8'))
    if target:
        tx, ty = target[0], PAGE_H - target[1]
        anchor = min(x + width - 22, max(x + 22, tx))
        tail = canvas.beginPath()
        tail.moveTo(anchor - 7, y + 8)
        tail.curveTo(anchor - 5, y - 5, tx - 6, ty + 8, tx, ty)
        tail.curveTo(tx + 3, ty + 13, anchor + 9, y - 2, anchor + 7, y + 8)
        tail.close()
        canvas.drawPath(tail, stroke=1, fill=1)
    # A shallow bowed top/bottom and full curved sides keep the contour organic.
    p = canvas.beginPath()
    p.moveTo(x + 25, y + height - 3)
    p.curveTo(x + width * .35, y + height + 3, x + width * .65, y + height + 3,
              x + width - 25, y + height - 3)
    p.curveTo(x + width + 9, y + height - 12, x + width + 9, y + 12, x + width - 25, y + 3)
    p.curveTo(x + width * .65, y - 3, x + width * .35, y - 3, x + 25, y + 3)
    p.curveTo(x - 9, y + 12, x - 9, y + height - 12, x + 25, y + height - 3)
    p.close()
    canvas.drawPath(p, stroke=1, fill=1)
    canvas.setFillColor(INK)
    canvas.setFont('Comic', FONT_SIZE)
    for index, line in enumerate(lines):
        canvas.drawCentredString(center, PAGE_H - top - 24 - index * LEADING, line)
    return {'text': text, 'lines': lines, 'bounds': [x, top, width, height], 'target': target}


def build() -> None:
    """Render four review pages and retain measured lettering for editorial inspection."""
    pdfmetrics.registerFont(TTFont('Comic', str(ROOT.parent / 'fonts/comicneue/ComicNeue-Bold.ttf')))
    pdfmetrics.registerFont(TTFont('Display', str(ROOT.parent / 'fonts/bangers/Bangers-Regular.ttf')))
    layouts = json.loads((ROOT / 'layout.json').read_text())
    canvas = Canvas(str(ROOT / 'opening-thumbnails-v2.pdf'), pagesize=(477, 738))
    measured: list[dict[str, object]] = []
    for page_index, page in enumerate(layouts):
        canvas.saveState()
        canvas.scale(477 / PAGE_W, 738 / PAGE_H)
        canvas.setFillColor(PAPER)
        canvas.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
        canvas.setFillColor(INK)
        canvas.setFont('Comic', 13)
        canvas.drawString(22, PAGE_H - 20, f'LAYOUT THUMBNAIL / {page_index + 1} / SCRIPT V2')
        for index, panel in enumerate(page['panels']):
            x, y, w, h = panel['rect']
            canvas.setStrokeColor(INK)
            canvas.setLineWidth(2)
            canvas.setFillColor(PAPER)
            canvas.rect(x, PAGE_H - y - h, w, h, stroke=1, fill=1)
            reserve = panel.get('reserve', 0)
            art_map = clipped_art(canvas, ROOT / f'page-{page_index + 1:02d}-art.png', panel['crop'],
                                  [x + 3, y + reserve + 3, w - 6, h - reserve - 6])
            if panel.get('bj'):
                bj = clipped_art(canvas, REPO / 'assets/portraits/bj-expressions-v2.png',
                                 [0, 0, 393, 382], [x + 10, y + 5, 92, 92])
                canvas.setFillColor(INK)
                canvas.setFont('Comic', 11)
                canvas.drawString(x + 12, PAGE_H - y - 105, 'BJ / RADIO')
            script_panel = SCRIPT['pages'][page_index]['panels'][index]
            rendered: list[str] = []
            previous_bounds = None
            previous_speaker = None
            for item in panel.get('balloons', []):
                original = script_panel['dialogue'][item['dialogue']][1]
                speaker = script_panel['dialogue'][item['dialogue']][0].split(' (')[0]
                text = item.get('text', original)
                rendered.append(text)
                target = point(art_map, item['mouth']) if 'mouth' in item else None
                if item.get('radio'):
                    target = point(bj, [260, 140])
                result = balloon(canvas, text, x + item['center'], y + item.get('top', 8),
                                 item['width'], target, item.get('radio', False),
                                 previous_bounds if previous_speaker == speaker else None)
                measured.append({'page': page_index + 1, 'panel': index + 1, **result})
                previous_bounds = result['bounds']
                previous_speaker = speaker
            expected = ' '.join(line[1] for line in script_panel['dialogue'])
            assert ' '.join(rendered) == expected, (page_index + 1, index + 1)
            if 'sfx' in script_panel:
                dx, dy = panel.get('sfx_at', [w * .70, 34])
                canvas.setFillColor(INK)
                canvas.setFont('Display', panel.get('sfx_size', 38))
                canvas.drawString(x + dx, PAGE_H - y - dy, script_panel['sfx'])
            for note in panel.get('notes', []):
                nx, ny = note['at']
                canvas.setFillColor(HexColor('#fff0c6'))
                canvas.setStrokeColor(HexColor('#a34b20'))
                canvas.setLineWidth(1)
                canvas.rect(x + nx, PAGE_H - y - ny - len(note['lines']) * 17 - 10,
                            note['width'], len(note['lines']) * 17 + 10, stroke=1, fill=1)
                canvas.setFillColor(HexColor('#843511'))
                canvas.setFont('Comic', 13)
                for line_index, line in enumerate(note['lines']):
                    canvas.drawString(x + nx + 6, PAGE_H - y - ny - 17 - line_index * 17, line)
        if page_index == 0:
            canvas.setFont('Display', 28)
            canvas.setFillColor(INK)
            canvas.drawString(130, PAGE_H - 152, SCRIPT['title'])
        canvas.restoreState()
        canvas.showPage()
    canvas.save()
    (ROOT / 'lettering-measured.json').write_text(json.dumps(measured, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    build()
