"""Synchronize macOS export versions with the canonical Godot project version."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sync_version(check: bool = False) -> str:
    """Validate the project version, then synchronize or check export metadata."""
    project = (ROOT / 'project.godot').read_text()
    match = re.search(r'^config/version="(\d+\.\d+\.\d+)"$', project, re.MULTILINE)
    if not match:
        raise ValueError('project.godot must define a numeric config/version="X.Y.Z".')
    version = match.group(1)
    preset = ROOT / 'export_presets.cfg'
    original = preset.read_text()
    updated, count = re.subn(r'^(application/(?:short_version|version))="[^"]*"$',
                            lambda item: f'{item.group(1)}="{version}"', original, flags=re.MULTILINE)
    if count != 2:
        raise ValueError('Expected both macOS export version fields.')
    if check and updated != original:
        raise ValueError('Export version differs from project.godot; run tools/sync_project_version.py.')
    if not check and updated != original:
        preset.write_text(updated)
    return version


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    print(sync_version(parser.parse_args().check))
