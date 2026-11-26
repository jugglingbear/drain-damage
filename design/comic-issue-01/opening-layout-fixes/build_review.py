"""Assemble independent candidate panels, retained art, and editable lettering."""

import importlib.util
import json
from pathlib import Path

from PIL import Image
from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent
HEIGHT = 1550
BOXES = {
    1: [(8, 20, 984, 380), (8, 408, 318, 480), (334, 408, 658, 480),
        (8, 896, 984, 440), (8, 1344, 984, 185)],
    2: [(8, 8, 984, 414), (8, 430, 984, 350), (8, 788, 298, 402),
        (314, 788, 678, 402), (314, 1198, 678, 344)],
    3: [(490, 302, 502, 188), (8, 500, 984, 485),
        (8, 995, 984, 300), (8, 1240, 984, 310)],
}


def panel(canvas: Canvas, file: Path, box: tuple, top_pad: float = 0) -> None:
    """Place an independent image inside an editable rectangular panel."""
    x, top, width, height = box
    canvas.saveState()
    path = canvas.beginPath()
    path.rect(x, HEIGHT - top - height, width, height)
    canvas.clipPath(path, stroke=0)
    canvas.setFillColor(HexColor('#efd0a6'))
    canvas.rect(x, HEIGHT - top - height, width, height, fill=1, stroke=0)
    with Image.open(file) as source:
        iw, ih = source.size
    scale = width / iw
    drawn_height = ih * scale
    # The quiet top band protects dialogue when a wide illustration lacks headroom.
    bottom = HEIGHT - top - top_pad - drawn_height if top_pad else HEIGHT - top - height
    canvas.drawImage(str(file), x + (width - iw * scale) / 2, bottom, iw * scale, drawn_height)
    canvas.restoreState()
    canvas.setStrokeColor(HexColor('#282521'))
    canvas.setLineWidth(2)
    canvas.rect(x, HEIGHT - top - height, width, height, fill=0, stroke=1)


def retained(canvas: Canvas, page: int, box: tuple) -> None:
    """Clip original art for unchanged insets without regenerating them."""
    file = ROOT.parent / 'continuity-pass-v1' / f'page-{page:02d}-art.png'
    x, top, width, height = box
    canvas.saveState()
    path = canvas.beginPath()
    path.rect(x, HEIGHT - top - height, width, height)
    canvas.clipPath(path, stroke=0)
    with Image.open(file) as source:
        iw, ih = source.size
    scale = min(1000 / iw, HEIGHT / ih)
    canvas.drawImage(str(file), (1000 - iw * scale) / 2, (HEIGHT - ih * scale) / 2,
                     iw * scale, ih * scale)
    canvas.restoreState()


def build() -> None:
    """Build three comparison pages and validate approved dialogue and sound effects."""
    spec = importlib.util.spec_from_file_location('lettering', ROOT.parent / 'thumbnails-v3/build_pages.py')
    lettering = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(lettering)
    for name, file in [('Comic', 'comicneue/ComicNeue-Bold.ttf'), ('Display', 'bangers/Bangers-Regular.ttf')]:
        pdfmetrics.registerFont(TTFont(name, str(ROOT.parent / 'fonts' / file)))
    layout = json.loads((ROOT / 'layout.json').read_text())
    script = json.loads((ROOT.parent / 'opening-script-v2.json').read_text())
    measured = []
    for number, page in enumerate(layout, 1):
        canvas = Canvas(str(ROOT / f'page-{number}.pdf'), pagesize=(477, 738))
        canvas.scale(477 / 1000, 738 / HEIGHT)
        retained(canvas, number, (0, 0, 1000, HEIGHT))
        ids = range(1, 6) if number < 3 else range(2, 6)
        for index, box in zip(ids, BOXES[number]):
            pad = {(2, 2): 50}.get((number, index), 0)
            source_dir = 'restroom-closure' if number == 3 and index in (4, 5) else 'pages-1-3-continuity-v1'
            panel(canvas, ROOT.parent / source_dir / f'p{number}p{index}.png', box, pad)
        if number == 1:
            retained(canvas, 1, (8, 20, 210, 180))
            retained(canvas, 1, (8, 1344, 208, 185))
        for index, item in enumerate(page['panels']):
            expected = script['pages'][number - 1]['panels'][index]
            previous = None
            rendered = []
            for balloon in item.get('balloons', []):
                text = balloon.get('text', expected['dialogue'][balloon['dialogue']][1])
                result = lettering.speech(canvas, text, balloon, previous)
                measured.append({'page': number, 'panel': index + 1, **result})
                previous = result['bounds']
                rendered.append(text)
            assert ' '.join(rendered) == ' '.join(line[1] for line in expected['dialogue'])
            if 'sfx' in expected:
                canvas.setFont('Display', item.get('size', 36))
                canvas.setFillColor(HexColor('#282521'))
                x, y = item['sfx']
                canvas.drawString(x, HEIGHT - y, expected['sfx'])
        for caption in page.get('captions', []):
            canvas.setFillColor(HexColor('#282521'))
            canvas.setFont(caption.get('font', 'Comic'), caption['size'])
            canvas.drawString(caption['x'], HEIGHT - caption['y'], caption['text'])
        canvas.save()
    writer = PdfWriter()
    for number in range(1, 4):
        writer.append(str(ROOT / f'page-{number}.pdf'))
    writer.write(str(ROOT / 'three-page-comparison.pdf'))
    assert len(PdfReader(ROOT / 'three-page-comparison.pdf').pages) == 3
    (ROOT / 'lettering-measured.json').write_text(json.dumps(measured, indent=2) + '\n')


if __name__ == '__main__':
    build()
