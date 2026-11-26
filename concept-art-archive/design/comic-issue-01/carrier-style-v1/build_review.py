"""Rebuild candidate pages with the accepted editable lettering and panel geometry."""

import importlib.util
import json
from pathlib import Path
from types import ModuleType

from pypdf import PdfReader, PdfWriter
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parent


def load_builder(name: str, path: Path) -> ModuleType:
    """Load an established builder without modifying its source or published outputs."""
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.ROOT = ROOT
    return module


def build() -> None:
    """Compose four candidate pages and verify canonical dialogue survives unchanged."""
    layout = json.loads((ROOT.parent / 'thumbnails-v3/layout.json').read_text())[:3]
    for number, page in enumerate(layout, 1):
        page['art'] = f'page-{number:02d}-art.png'
    (ROOT / 'layout.json').write_text(json.dumps(layout, indent=2) + '\n')
    load_builder('first_pages', ROOT.parent / 'thumbnails-v3/build_pages.py').build()
    (ROOT / 'lettering-measured.json').rename(ROOT / 'lettering-pages-1-3.json')
    load_builder('last_page', ROOT.parent / 'page4-continuity-v7/build_page.py').build()
    writer = PdfWriter()
    writer.append(str(ROOT / 'opening-layouts-v3.pdf'))
    writer.append(str(ROOT / 'page-4.pdf'))
    destination = ROOT / 'four-page-candidate.pdf'
    writer.write(str(destination))
    reader = PdfReader(destination)
    assert len(reader.pages) == 4
    script = json.loads((ROOT.parent / 'opening-script-v2.json').read_text())
    checks = []
    for number, page in enumerate(reader.pages):
        extracted = ' '.join(page.extract_text().split())
        expected = script['pages'][number]['panels']
        for panel in expected:
            for _, dialogue in panel['dialogue']:
                assert ' '.join(dialogue.split()) in extracted, dialogue
            if 'sfx' in panel:
                assert panel['sfx'] in extracted
        checks.append({'page': number + 1, 'canonical_dialogue_and_sfx': 'pass'})
    (ROOT / 'validation.json').write_text(json.dumps(checks, indent=2) + '\n')


def contact_sheet() -> None:
    """Lay out rendered pages together for independent palette and continuity review."""
    canvas = Canvas(str(ROOT / 'style-contact.pdf'), pagesize=(2000, 800))
    pdfmetrics.registerFont(TTFont('Contact', str(ROOT.parent / 'fonts/comicneue/ComicNeue-Bold.ttf')))
    canvas.setFont('Contact', 18)
    for number in range(1, 5):
        canvas.drawImage(str(ROOT / f'page-{number}.png'), (number - 1) * 500, 10, 477, 738)
        canvas.drawString((number - 1) * 500 + 10, 770, f'Candidate story page {number}')
    canvas.save()


if __name__ == '__main__':
    build()
