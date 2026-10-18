"""Publish the approved PDF as a layout-preserving, static magazine reader."""

from __future__ import annotations

import argparse
import html
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / 'marketing/magazine/current.pdf'


def build_site(destination: Path) -> None:
    """Render every PDF page and write a standalone, portable HTML reader."""
    if not PDF.read_bytes().startswith(b'%PDF-'):
        raise ValueError('current.pdf is not a PDF. Fetch Git LFS assets first.')
    destination.mkdir(parents=True, exist_ok=True)
    info = subprocess.check_output(['pdfinfo', str(PDF)], text=True)
    match = re.search(r'^Pages:\s+(\d+)', info, re.MULTILINE)
    if not match:
        raise ValueError('Cannot determine PDF page count.')
    count = int(match.group(1))
    # A fresh temporary rendering directory prevents stale pages after an issue shrinks.
    with tempfile.TemporaryDirectory() as temporary:
        prefix = Path(temporary) / 'page'
        subprocess.run(['pdftoppm', '-jpeg', '-jpegopt', 'quality=92', '-r', '150', str(PDF), str(prefix)],
                       check=True)
        pages = sorted(Path(temporary).glob('page-*.jpg'), key=lambda p: int(p.stem.split('-')[-1]))
        if len(pages) != count:
            raise ValueError('Rendered page count does not match PDF.')
        for number, page in enumerate(pages, 1):
            shutil.copyfile(page, destination / f'page-{number}.jpg')
    shutil.copyfile(PDF, destination / 'magazine.pdf')
    shutil.copytree(ROOT / 'storybook', destination / 'storybook', dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('.gdignore', '.DS_Store'))
    figures = '\n'.join(
        f'<figure id="page-{n}"><img src="page-{n}.jpg" alt="Magazine page {n}" '
        f'loading="{"eager" if n == 1 else "lazy"}"><figcaption>Page {n} of {count}</figcaption></figure>'
        for n in range(1, count + 1)
    )
    links = ' '.join(f'<a href="#page-{n}" aria-label="Go to page {n}">{n}</a>' for n in range(1, count + 1))
    title = html.escape('Discharge Quarterly')
    document = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>__TITLE__ — Drain Damage</title>
<style>
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:2rem}
body{margin:0;background:#10141c;color:#f5eddc;font:17px/1.5 system-ui,sans-serif}
header,main,footer{max-width:960px;margin:auto;padding:24px}
header{border-bottom:1px solid #424750}h1{font-size:clamp(28px,5vw,48px);margin:8px 0}
a{color:#9bf0cf;text-underline-offset:4px}a:focus-visible{outline:3px solid #ffd36b;outline-offset:4px}
.masthead{display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap}
.masthead p{margin:0}.header-actions{display:flex;align-items:center;gap:12px;margin-left:auto}.repo-link{padding:10px 12px;border:1px solid #64716b;border-radius:4px}
nav{display:flex;gap:12px;flex-wrap:wrap;margin-top:20px}nav a{padding:6px 12px;border:1px solid #64716b}
figure{margin:0 0 32px}img{display:block;width:100%;height:auto;box-shadow:0 6px 30px #0008}
figcaption{text-align:center;color:#bac3c9;font-size:14px;margin-top:10px}
footer{color:#bac3c9} @media(max-width:600px){main{padding:16px 0}header,footer{padding:20px}}
@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style></head><body>
<header><div class="masthead"><p>DRAIN DAMAGE</p>
<div class="header-actions">
<a class="repo-link" href="storybook/storybook.html">Storybook →</a>
<a class="repo-link" href="https://github.com/jugglingbear/drain-damage"
aria-label="Drain Damage repository on GitHub">GitHub ↗</a></div></div><h1>__TITLE__</h1>
<p>The magazine for plumbing's least ordinary working day.</p>
<p><a href="magazine.pdf">Open the original PDF</a> · <a href="magazine.pdf" download>Download magazine</a></p>
<nav aria-label="Magazine pages">__LINKS__</nav></header><main aria-label="Magazine">__FIGURES__</main>
<footer>Pages reproduce the original PDF layout. Open the PDF for selectable text and full-resolution zoom.</footer>
</body></html>
'''
    (destination / 'index.html').write_text(document.replace('__TITLE__', title).replace('__LINKS__', links)
                                          .replace('__FIGURES__', figures), encoding='utf-8')
    (destination / '.nojekyll').touch()
    print(f'Published {count} pages to {destination}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'builds/magazine-site')
    build_site(parser.parse_args().output)
