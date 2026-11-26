"""Assemble Art's review pages with editable, separately typeset comic lettering."""

from __future__ import annotations

import json
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas
from reportlab.platypus import Paragraph

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
WIDTH, HEIGHT = 477.0, 738.0
INK = HexColor('#271d1b')
CREAM = HexColor('#fff4d9')
OUTPUT = ROOT / 'review-v1'


def paragraph(canvas: Canvas, text: str, x: float, y: float, width: float,
              size: float = 10, font: str = 'Comic', center: bool = False) -> float:
    """Draw text below a top-origin position and return its measured height."""
    style = ParagraphStyle('comic', fontName=font, fontSize=size, leading=size * 1.15,
                           textColor=INK, alignment=1 if center else 0)
    item = Paragraph(escape(text), style)
    _, height = item.wrap(width, HEIGHT)
    item.drawOn(canvas, x, HEIGHT - y - height)
    return height


def background(canvas: Canvas, path: Path) -> None:
    """Fit original artwork without stretching or cropping its composition."""
    canvas.setFillColor(CREAM)
    canvas.rect(0, 0, WIDTH, HEIGHT, stroke=0, fill=1)
    with Image.open(path) as source:
        scale = min(WIDTH / source.width, HEIGHT / source.height)
        width, height = source.width * scale, source.height * scale
    canvas.drawImage(str(path), (WIDTH - width) / 2, (HEIGHT - height) / 2, width, height)


def balloon(canvas: Canvas, item: dict) -> None:
    """Typeset a balloon, caption or sound effect from normalized placement data."""
    x, y, width, height = [float(item[key]) * unit for key, unit in
                          [('x', WIDTH), ('y', HEIGHT), ('w', WIDTH), ('h', HEIGHT)]]
    kind = item.get('kind', 'speech')
    size = item.get('size', 9.3)
    font = item.get('font', 'ComicBold')
    if kind == 'sfx':
        paragraph(canvas, item['text'], x, y, width, size, 'Display', center=True)
        return
    canvas.setStrokeColor(INK)
    canvas.setLineWidth(0.8)
    canvas.setFillColor(CREAM if kind == 'radio' else HexColor('#fffdf6'))
    tail = item.get('tail')
    if tail:
        target_x, target_y = tail[0] * WIDTH, HEIGHT - tail[1] * HEIGHT
        anchor_x = x + width * item.get('anchor', 0.5)
        anchor_y = HEIGHT - y - 3 if item.get('edge') == 'top' else HEIGHT - y - height + 3
        path = canvas.beginPath()
        path.moveTo(anchor_x - 4, anchor_y)
        bend = item.get('bend')
        if bend:
            bend_x, bend_y = bend[0] * WIDTH, HEIGHT - bend[1] * HEIGHT
            path.curveTo(bend_x - 3, bend_y, bend_x - 3, bend_y, target_x, target_y)
            path.curveTo(bend_x + 3, bend_y, bend_x + 3, bend_y, anchor_x + 4, anchor_y)
        else:
            path.lineTo(target_x, target_y)
            path.lineTo(anchor_x + 4, anchor_y)
        path.close()
        canvas.drawPath(path, stroke=1, fill=1)
    radius = 3 if kind == 'radio' else min(18, height / 2)
    canvas.roundRect(x, HEIGHT - y - height, width, height, radius, stroke=1, fill=1)
    inset = 8
    label_height = 0
    if kind == 'radio' and item.get('label', True):
        label_height = paragraph(canvas, 'BJ / RADIO', x + inset, y + 5, width - inset * 2, 6, 'ComicBold') + 3
    text_height = paragraph(canvas, item['text'], x + inset, y + 6 + label_height,
                            width - inset * 2, size, font, center=kind != 'radio')
    if text_height + label_height + 11 > height:
        raise ValueError(f"Balloon overflow: {item['text']} ({text_height + label_height + 11:.1f}>{height:.1f})")


def inside_cover(canvas: Canvas, script: dict) -> None:
    """Lay out the approved fictional memo and clearly identified license note."""
    background(canvas, ROOT / 'pages-v1/inside-front.png')
    canvas.drawImage(str(REPO / 'references/branding/jugglingbears-user-logo.png'), 44, HEIGHT - 122, 67, 67)
    paragraph(canvas, 'DRAIN DAMAGE', 126, 56, 307, 36, 'Display')
    paragraph(canvas, 'A JUGGLINGBEARS COMIC • ISSUE 01', 128, 99, 300, 9, 'ComicBold')
    paragraph(canvas, 'Something Borrowed, Something Spewed', 44, 143, 390, 14, 'ComicBold')
    copy = script['inside_front_cover']
    paragraph(canvas, copy['heading'], 44, 211, 390, 19, 'Display')
    y = 250.0
    for text in copy['memo']:
        y += paragraph(canvas, text, 44, y, 387, 12) + 17
    paragraph(canvas, copy['signature'], 44, y + 3, 387, 10, 'ComicItalic')
    canvas.setStrokeColor(INK)
    canvas.setLineWidth(0.5)
    canvas.line(44, 216, 433, 216)
    y = 538.0
    for index, text in enumerate(copy['publication_block']):
        y += paragraph(canvas, text, 44, y, 387, 8, 'ComicBold' if index == 0 else 'Comic') + 8
    if y > 691:
        raise ValueError('Publication block exceeds safe area')


def main() -> None:
    """Build available review pages; the final delivery requires all four story pages."""
    OUTPUT.mkdir(exist_ok=True)
    for label, file in [('Comic', 'ComicNeue-Regular'), ('ComicBold', 'ComicNeue-Bold'),
                        ('ComicItalic', 'ComicNeue-Italic')]:
        pdfmetrics.registerFont(TTFont(label, str(ROOT / f'fonts/comicneue/{file}.ttf')))
    pdfmetrics.registerFont(TTFont('Display', str(ROOT / 'fonts/bangers/Bangers-Regular.ttf')))
    script = json.loads((ROOT / 'opening-review.json').read_text())
    lettering = json.loads((ROOT / 'lettering-v1.json').read_text())
    canvas = Canvas(str(OUTPUT / 'drain-damage-opening-review.pdf'), pagesize=(WIDTH, HEIGHT), pageCompression=1)
    canvas.setTitle('Drain Damage • Issue 01 • Opening visual draft')
    canvas.setAuthor('JugglingBears')
    canvas.setSubject('Cover, inside cover and opening story pages. Visual review; dialogue revision pending.')
    canvas._doc.Catalog.PageLayout = '/TwoPageRight'
    background(canvas, REPO / script['cover_candidate'])
    canvas.showPage()
    inside_cover(canvas, script)
    canvas.showPage()
    for page in lettering['pages']:
        background(canvas, ROOT / page['art'])
        for item in page['lettering']:
            balloon(canvas, item)
        canvas.showPage()
    canvas.save()
    print(OUTPUT / 'drain-damage-opening-review.pdf')


if __name__ == '__main__':
    main()
