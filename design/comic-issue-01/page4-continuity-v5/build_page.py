"""Assemble independent continuity panels with editable canonical lettering."""

import importlib.util
import json
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent


def build() -> None:
    """Compose one review page without changing accepted preview files."""
    spec = importlib.util.spec_from_file_location('lettering', ROOT.parent / 'thumbnails-v3/build_pages.py')
    lettering = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(lettering)
    for name, path in [('Comic', 'comicneue/ComicNeue-Bold.ttf'), ('Display', 'bangers/Bangers-Regular.ttf')]:
        pdfmetrics.registerFont(TTFont(name, str(ROOT.parent / 'fonts' / path)))
    panels = json.loads((ROOT.parent / 'opening-script-v2.json').read_text())['pages'][3]['panels']
    canvas = Canvas(str(ROOT / 'page-4.pdf'), pagesize=(477, 738))
    canvas.scale(477 / 1000, 738 / 1550)
    canvas.setFillColor(HexColor('#f8efdf'))
    canvas.rect(0, 0, 1000, 1550, fill=1, stroke=0)
    boxes = [(10, 10, 980, 610), (10, 628, 980, 310), (10, 946, 486, 295),
             (504, 946, 486, 295), (10, 1249, 486, 291), (504, 1249, 486, 291)]
    for number, (x, top, width, height) in enumerate(boxes, 1):
        source = ROOT / f'panel-{number}.png'
        with Image.open(source) as image:
            iw, ih = image.size
        scale = max(width / iw, height / ih)
        canvas.saveState()
        clip = canvas.beginPath()
        clip.rect(x, 1550 - top - height, width, height)
        canvas.clipPath(clip, stroke=0)
        canvas.drawImage(str(source), x + (width - iw * scale) / 2, 1550 - top - height,
                         iw * scale, ih * scale)
        canvas.restoreState()
        canvas.setStrokeColor(HexColor('#282521'))
        canvas.setLineWidth(2)
        canvas.rect(x, 1550 - top - height, width, height, fill=0, stroke=1)
    balloons = [
        (panels[1]['dialogue'][0][1], {'center': 160, 'top': 633, 'width': 245,
                                     'target': [65, 690], 'head_top': 696, 'edge': 'left'}),
        (panels[1]['dialogue'][1][1], {'center': 450, 'top': 633, 'width': 310,
                                     'target': [290, 680], 'head_top': 688, 'edge': 'left'}),
        (panels[3]['dialogue'][0][1], {'center': 735, 'top': 954, 'width': 310,
                                     'target': [792, 1018], 'head_top': 1023}),
    ]
    measured = [lettering.speech(canvas, text, item, None) for text, item in balloons]
    for text, x, y, size in [(panels[0]['sfx'], 650, 95, 57), (panels[5]['sfx'], 715, 1280, 36)]:
        canvas.setFont('Display', size)
        canvas.setFillColor(HexColor('#282521'))
        canvas.drawString(x, 1550 - y, text)
    canvas.save()
    (ROOT / 'lettering-measured.json').write_text(json.dumps(measured, indent=2) + '\n')


if __name__ == '__main__':
    build()
