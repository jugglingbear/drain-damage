"""Build editable lettering proofs from independent pencil panels."""
import re
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
from build_pages import speech

BOXES = {
    7: [(10, 10, 980, 250), (10, 268, 980, 390), (10, 666, 486, 380),
        (504, 666, 486, 380), (10, 1054, 980, 486)],
    8: [(10, 10, 980, 350), (10, 368, 486, 275), (504, 368, 486, 275),
        (10, 651, 980, 420), (10, 1079, 486, 461), (504, 1079, 486, 461)],
}
# Local balloon centers, tops and widths reserve space in the pencil compositions.
BALLOONS = {
    (7, 1): [(735, 8, 440, 635, 140)],
    (7, 2): [(240, 0, 430, 660, 125), (270, 70, 460, 230, 180)],
    (7, 3): [(240, 6, 435, 350, 235)],
    (7, 4): [(125, 6, 210, 100, 220), (330, 55, 270, 380, 300), (170, 235, 260, 155, 290)],
    (7, 5): [(336, 8, 590, 100, 215)],
    (8, 1): [(220, 10, 380, 180, 150), (660, 10, 560, 510, 145)],
    (8, 4): [(260, 0, 440, 735, 90), (260, 65, 440, 280, 170), (750, 125, 400, 735, 230)],
    (8, 5): [(240, 10, 430, 400, 175)],
    (8, 6): [(150, 10, 250, 110, 235), (310, 90, 285, 340, 270)],
}


def build() -> None:
    """Render two draft pages with the approved text and room for review."""
    for name, file in (("Comic", "comicneue/ComicNeue-Bold.ttf"), ("Display", "bangers/Bangers-Regular.ttf")):
        pdfmetrics.registerFont(TTFont(name, str(ROOT.parent / "fonts" / file)))
    canvas = Canvas(str(ROOT / "lettered-roughs.pdf"), pagesize=(477, 738))
    for page, boxes in BOXES.items():
        sections = re.split(r"## Panel \d+\n", (ROOT.parent / f"page-0{page}-script.md").read_text())[1:]
        canvas.scale(477/1000, 738/1550)
        canvas.setFillColor(HexColor("#f8efdf"))
        canvas.rect(0, 0, 1000, 1550, fill=1, stroke=0)
        for index, ((x, top, width, height), section) in enumerate(zip(boxes, sections, strict=True), 1):
            with Image.open(ROOT / "roughs" / f"p{page}p{index}.png") as art:
                key = (page, index)
                if key == (7, 5):
                    # Separate reaction and reply beats avoid crossed speaker tails.
                    close = art.crop((art.width*.30, art.height*.24, art.width*.48, art.height*.66))
                    close = ImageOps.fit(close.convert("RGB"), (450, round((height-120)*1.5)),
                                        centering=(.5, 0))
                    data = BytesIO()
                    close.save(data, "JPEG", quality=94)
                    canvas.setFillColor(HexColor("#f5ebdc"))
                    canvas.rect(x, 1550-top-height, 300, height, fill=1, stroke=0)
                    canvas.drawImage(ImageReader(data), x, 1550-top-height, 300, height-120)
                    canvas.setStrokeColor(HexColor("#282521"))
                    canvas.setLineWidth(2)
                    canvas.rect(x, 1550-top-height, 300, height)
                    question = " ".join(re.findall("“(.*?)”", section, re.S)[0].split())
                    speech(canvas, question, dict(center=x+150, top=top+8, width=255,
                                                 target=[x+165, top+140], head_top=top+150), None)
                    x += 308
                    width -= 308
                    art = art.crop((art.width*.12, 0, art.width, art.height))
                    scaled = ImageOps.fit(art.convert("RGB"), (round(width*1.5), round((height-150)*1.5)),
                                          centering=(.5, 0))
                    crop = Image.new("RGB", (round(width*1.5), round(height*1.5)), "#f5ebdc")
                    crop.paste(scaled, (0, 225))
                elif key == (8, 4):
                    art = art.crop((0, round(art.height*.10), art.width, art.height))
                    scaled = ImageOps.fit(art.convert("RGB"), (round(width*1.5), round((height-120)*1.5)),
                                          centering=(.5, 0))
                    crop = Image.new("RGB", (round(width*1.5), round(height*1.5)), "#f5ebdc")
                    crop.paste(scaled, (0, 180))
                elif key in ((7, 1), (7, 2), (8, 1), (8, 4)):
                    cut = {(7, 1): .08, (7, 2): .02, (7, 5): 0, (8, 1): .08, (8, 4): .05}[key]
                    art = art.crop((0, round(art.height * cut), art.width, art.height))
                    crop = ImageOps.fit(art.convert("RGB"), (round(width*1.5), round(height*1.5)),
                                        centering=(.5, 0))
                else:
                    pad = 0 if key in ((8, 2), (8, 3)) else (230 if key == (7, 4) else 170)
                    art = art.crop((0, round(art.height * .23), art.width, art.height))
                    scaled = ImageOps.fit(art.convert("RGB"), (round(width*1.5), round((height-pad)*1.5)),
                                          centering=(.5, 0))
                    crop = Image.new("RGB", (round(width*1.5), round(height*1.5)), "#f5ebdc")
                    crop.paste(scaled, (0, round(pad*1.5)))
                data = BytesIO()
                crop.save(data, "JPEG", quality=94)
            canvas.drawImage(ImageReader(data), x, 1550-top-height, width, height)
            canvas.setStrokeColor(HexColor("#282521"))
            canvas.setLineWidth(2)
            canvas.rect(x, 1550-top-height, width, height)
            texts = [" ".join(s.split()) for s in re.findall("“(.*?)”", section, re.S)]
            if (page, index) == (7, 5):
                texts = [" ".join(texts[1:])]
            previous = None
            for text, (cx, by, bw, tx, ty) in zip(texts, BALLOONS.get((page,index), []), strict=True):
                linked = (page,index) == (7,5) and text.startswith("Once")
                result = speech(canvas, text, dict(center=x+cx, top=top+by, width=bw,
                                          **({"edge": "right"} if ((page,index)==(7,2) and text.startswith("When")) or ((page,index)==(8,4) and text.startswith("Tony,")) else {}),
                                          **({"anchor": .9} if (page,index)==(7,5) and text.startswith("I thought") else {}),
                                          **({"link": True} if linked else {"target": [x+tx,top+ty], "head_top":top+ty+8})), previous)
                previous = result["bounds"]
            if (page,index)==(8,5):
                canvas.setFont("Courier-Bold", 12)
                canvas.setFillColor(HexColor("#ffffff"))
                canvas.drawString(x+155,1550-top-300,"LAST RECEIVED 8:14 AM")
                canvas.drawString(x+155,1550-top-330,"CURRENT TIME  6:12 PM")
            if (page,index)==(8,2):
                canvas.setFont("Display",32)
                canvas.drawString(x+25,1550-top-45,"SHHHHH")
        canvas.showPage()
    canvas.save()


if __name__ == "__main__":
    build()
