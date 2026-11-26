"""Assemble the reception timing proof from current page art and three pencil inserts."""

import json
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps
from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent
ISSUE = ROOT.parent
FIGHT = ISSUE / "fight-pages"
sys.path.insert(0, str(ISSUE / "thumbnails-v3"))
from build_pages import speech

# Coordinates use the same 1000 x 1550 design grid as the approved opening.
LAYOUT = (
    (("baton", 10, 10, 586, 260), ("p5p1", 604, 10, 386, 260),
     ("p5p2", 10, 278, 980, 450), ("p5p3", 10, 736, 980, 333), ("p5p4", 10, 1077, 980, 463)),
    (("cymbals", 10, 10, 288, 177), ("p6p1", 306, 10, 684, 177), ("p6p2", 10, 195, 980, 255),
     ("p6p3", 10, 458, 980, 371), ("bow", 10, 837, 635, 272), ("glance", 653, 837, 337, 272), ("p6p4", 10, 1117, 980, 423)),
)
FOCUS = {"p6p1": (0.5, 0.64), "p6p4": (0.5, 0.19)}
SOUNDS = {"p5p1": (14, 47), "p5p4": (75, 75), "p6p1": (15, 47), "p6p3": (75, 75)}


def build(output: Path = ROOT, corridor_page: Path = ISSUE / "continuity-pass-v1/page-4.pdf") -> None:
    """Build both fight pages and join them to the newly lettered opening."""
    script = json.loads((FIGHT / "script.json").read_text())
    for name, file in (("Comic", "comicneue/ComicNeue-Bold.ttf"), ("Display", "bangers/Bangers-Regular.ttf")):
        pdfmetrics.registerFont(TTFont(name, str(ISSUE / "fonts" / file)))
    fight = output / "reception-fight.pdf"
    canvas = Canvas(str(fight), pagesize=(477, 738))
    for panels in LAYOUT:
        canvas.scale(477 / 1000, 738 / 1550)
        canvas.setFillColor(HexColor("#f8efdf"))
        canvas.rect(0, 0, 1000, 1550, fill=1, stroke=0)
        for name, x, top, w, h in panels:
            path = FIGHT if name.startswith("p") else output
            file = "bow" if name == "glance" else name
            with Image.open(path / f"{file}.png") as art:
                if name == "glance":
                    art = art.crop((art.width * .055, art.height * .10, art.width * .24, art.height * .38))
                if name == "p6p4":
                    art = art.crop((0, 0, round(art.width * .885), art.height))
                crop = ImageOps.fit(art.convert("RGB"), (round(w * 1.5), round(h * 1.5)),
                                    centering=FOCUS.get(name, (0.5, 0.5)))
                data = BytesIO()
                crop.save(data, "JPEG", quality=94)
            y = 1550 - top - h
            canvas.drawImage(ImageReader(data), x, y, w, h)
            canvas.setStrokeColor(HexColor("#282521"))
            canvas.setLineWidth(2)
            canvas.rect(x, y, w, h)
            if name in SOUNDS:
                dx, dy = SOUNDS[name]
                canvas.setFillColor(HexColor("#282521"))
                canvas.setFont("Display", 42)
                canvas.drawString(x + dx, 1550 - top - dy, script["pages"][name[1]][int(name[3])-1][1])
            if name == "p6p4":
                for entry, cx, target in zip(script["dialogue"]["P6P4"], (245, 725), (207, 855), strict=True):
                    speech(canvas, entry[1], dict(center=cx, top=top+2, width=430,
                                                  anchor=.32 if cx < 500 else .68, target=[target, top+(88 if cx < 500 else 68)], head_top=top+(98 if cx < 500 else 78)), None)
        canvas.showPage()
    canvas.save()
    writer = PdfWriter()
    public = ISSUE.parents[1] / "marketing/landing-page/comic/issue-01/drain-damage-issue-01-preview.pdf"
    writer.append(PdfReader(public), pages=(0, 2))
    writer.append(ISSUE / "opening-layout-fixes/three-page-comparison.pdf")
    writer.append(corridor_page)
    writer.append(fight)
    writer.write(output / "reception-proof.pdf")


if __name__ == "__main__":
    build()
