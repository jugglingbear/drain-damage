"""Render the magazine's canonical JSON text and layouts into a PDF."""

from __future__ import annotations

import json
from math import cos, pi, sin
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name("magazine.json")
DOCUMENT = json.loads(SOURCE.read_text(encoding="utf-8"))
LAYOUT = DOCUMENT["layout"]
PUBLICATION = DOCUMENT["publication"]
OUT = ROOT / DOCUMENT["output"]
INK = "101B2D"
for font_name, filename in LAYOUT["fonts"].items():
    pdfmetrics.registerFont(TTFont(font_name, str(Path(LAYOUT["font_directory"]) / filename)))
pdfmetrics.registerFontFamily("Body", normal="Body", bold="Bold", italic="Italic", boldItalic="Bold")
C = canvas.Canvas(str(OUT), pagesize=(LAYOUT["page_width"], LAYOUT["page_height"]), pageCompression=1)
C.setTitle(PUBLICATION["pdf_title"])
C.setAuthor(PUBLICATION["author"])
C.setSubject(PUBLICATION["subtitle"])


def rect(x: float, y: float, w: float, h: float, color: str) -> None:
    C.setFillColor(colors.HexColor("#" + color))
    C.rect(x, y, w, h, fill=1, stroke=0)


def text(value: str, x: float, y: float, size: float = 12, font: str = "Body", color: str = INK,
         angle: float = 0, outline: str | None = None, stroke_width: float = 1) -> None:
    """Draw editable display type, optionally rotated and outlined."""
    C.saveState()
    C.translate(x, y)
    C.rotate(angle)
    C.setFillColor(colors.HexColor("#" + color))
    C.setFont(font, size)
    if outline:
        C.setStrokeColor(colors.HexColor("#" + outline))
        C.setLineWidth(stroke_width)
        lettering = C.beginText(0, 0)
        lettering.setFont(font, size)
        lettering.setTextRenderMode(2)
        lettering.textOut(value)
        C.drawText(lettering)
    else:
        C.drawString(0, 0, value)
    C.restoreState()


def para(value: str, x: float, top: float, width: float, size: float = 10.4,
         color: str = INK, leading: float | None = None, max_height: float = 300,
         font: str = "Body") -> float:
    style = ParagraphStyle(
        "body", fontName=font, fontSize=size, leading=leading or size * 1.32,
        textColor=colors.HexColor("#" + color), spaceAfter=0,
    )
    block = Paragraph(value, style)
    _, height = block.wrap(width, max_height)
    if height > max_height:
        raise ValueError(f"Text exceeds its box: {value[:60]} ({height} > {max_height})")
    block.drawOn(C, x, top - height)
    return height


def image(path: str, x: float, y: float, width: float, height: float,
          crop: tuple[float, float, float, float] | None = None) -> None:
    """Place original pixels; optional PDF clipping leaves the source capture intact."""
    reader = ImageReader(str(ROOT / path))
    iw, ih = reader.getSize()
    if crop:
        left, top, cw, ch = crop
        factor = min(width / cw, height / ch)
        x += (width - cw * factor) / 2
        y += (height - ch * factor) / 2
        width, height = cw * factor, ch * factor
        C.saveState()
        clip = C.beginPath()
        clip.rect(x, y, width, height)
        C.clipPath(clip, stroke=0)
        sx, sy = width / cw, height / ch
        C.drawImage(reader, x - left * sx, y - (ih - top - ch) * sy, iw * sx, ih * sy, mask="auto")
        C.restoreState()
    else:
        factor = min(width / iw, height / ih)
        C.drawImage(reader, x + (width - iw * factor) / 2, y + (height - ih * factor) / 2,
                    iw * factor, ih * factor, mask="auto")


def dots(x: int, y: int, width: int, height: int, color: str) -> None:
    C.setFillColor(colors.HexColor("#" + color))
    for dx in range(x, x + width, 9):
        for dy in range(y, y + height, 9):
            C.circle(dx, dy, 1, stroke=0, fill=1)


def burst(cx: float, cy: float, radius: float, color: str) -> None:
    path = C.beginPath()
    for i in range(32):
        angle = i * pi / 16
        r = radius if i % 2 == 0 else radius * 0.85
        x, y = cx + cos(angle) * r, cy + sin(angle) * r
        if i == 0:
            path.moveTo(x, y)
        else:
            path.lineTo(x, y)
    path.close()
    C.setFillColor(colors.HexColor("#" + color))
    C.drawPath(path, fill=1, stroke=0)


def draw_element(element: dict, number: int, section: str) -> None:
    """Draw one declarative element, expanding only page-furniture placeholders."""
    values = {key: value for key, value in element.items() if key not in {"id", "type"}}
    kind = element["type"]
    if kind in {"text", "para"}:
        values["value"] = values.pop("text").replace("{page_number}", f"{number:02d}")
        values["value"] = values["value"].replace("{section}", section.upper())
    functions = {"rect": rect, "text": text, "para": para, "image": image, "dots": dots, "burst": burst}
    if kind in functions:
        functions[kind](**values)
    elif kind in {"setStrokeColor", "setLineWidth", "circle", "line"}:
        args = values["args"]
        if kind == "setStrokeColor":
            args = [colors.HexColor("#" + args[0])]
        getattr(C, kind)(*args, **values["options"])
    else:
        raise ValueError(f"Unsupported layout element: {kind}")


for page_number, page_data in enumerate(DOCUMENT["pages"], 1):
    if page_data["number"] != page_number:
        raise ValueError(f"Out-of-order page: {page_data['id']}")
    template = LAYOUT["templates"].get(page_data["template"], [])
    for element_data in template + page_data["elements"]:
        try:
            draw_element(element_data, page_number, page_data["section"])
        except Exception as error:
            raise ValueError(f"Page {page_data['id']}, element {element_data.get('id')}: {error}") from error
    C.bookmarkPage(page_data["id"])
    C.addOutlineEntry(page_data["section"], page_data["id"], level=0)
    C.showPage()
C.save()
print(OUT)
