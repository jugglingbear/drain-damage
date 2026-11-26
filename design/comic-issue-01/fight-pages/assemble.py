"""Assemble the two fight pages from independently drawn panels and approved dialogue."""

import json
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / "thumbnails-v3"))
from build_pages import speech  # noqa: E402

HEIGHT = 1550
ROWS = {5: (230, 470, 335, 471), 6: (156, 303, 552, 495)}
FOCUS = {(6, 1): (0.5, 0.64)}
SOUND_POSITIONS = {(5, 1): (60, 80), (5, 3): (820, 76), (5, 4): (80, 75),
                   (6, 1): (68, 65), (6, 3): (75, 95)}


def build() -> None:
    """Build the review PDF at the issue trim size with vector lettering."""
    script = json.loads((ROOT / "script.json").read_text())
    for name, file in (("Comic", "comicneue/ComicNeue-Bold.ttf"), ("Display", "bangers/Bangers-Regular.ttf")):
        pdfmetrics.registerFont(TTFont(name, str(ROOT.parent / "fonts" / file)))
    canvas = Canvas(str(ROOT / "fight-proof.pdf"), pagesize=(477, 738))
    canvas.setTitle("Drain Damage — Issue 01, pages 5–6")
    for page, rows in ROWS.items():
        canvas.scale(477 / 1000, 738 / HEIGHT)
        canvas.setFillColor(HexColor("#f8efdf"))
        canvas.rect(0, 0, 1000, HEIGHT, fill=1, stroke=0)
        top = 10
        for index, height in enumerate(rows, 1):
            with Image.open(ROOT / f"p{page}p{index}.png") as original:
                crop = ImageOps.fit(original.convert("RGB"), (1470, round(height * 1.5)),
                                    centering=FOCUS.get((page, index), (0.5, 0.5)))
                data = BytesIO()
                crop.save(data, "JPEG", quality=93)
            bottom = HEIGHT - top - height
            canvas.drawImage(ImageReader(data), 10, bottom, 980, height)
            canvas.setStrokeColor(HexColor("#282521"))
            canvas.setLineWidth(2)
            canvas.rect(10, bottom, 980, height)
            sound = script["pages"][str(page)][index - 1][1]
            if sound:
                x, offset = SOUND_POSITIONS[page, index]
                canvas.setFillColor(HexColor("#282521"))
                canvas.setFont("Display", 48)
                canvas.drawString(x, HEIGHT - top - offset, sound)
            if (page, index) == (6, 4):
                for entry, center, tip in zip(script["dialogue"]["P6P4"], (250, 738), (185, 750), strict=True):
                    speech(canvas, entry[1], dict(center=center, top=top+8, width=430,
                                                  target=[tip, top+77], head_top=top+85), None)
            top += height + 8
        canvas.showPage()
    canvas.save()


if __name__ == "__main__":
    build()
