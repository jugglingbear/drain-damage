"""Build the finished reception proof using the same lettering and layout as the pencil proof."""

from pathlib import Path
from runpy import run_path

ROOT = Path(__file__).resolve().parent

if __name__ == "__main__":
    corridor = run_path(str(ROOT.parent / "continuity-pass-v1/build_page.py"))
    corridor["build"](ROOT, ROOT / "p4p2.png")
    reception = run_path(str(ROOT.parent / "reception-rough/assemble.py"))
    reception["build"](ROOT, ROOT / "page-4.pdf")
