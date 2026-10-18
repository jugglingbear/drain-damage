#!/usr/bin/env python3
"""Validate optional Make selectors and forward them without shell interpolation."""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = json.loads((ROOT / "data/playtest-targets.json").read_text())
SELECTORS = ("LEVEL", "MINIBOSS", "BOSS")


def launch_arguments(environment: dict[str, str]) -> list[str]:
    """Resolve one implemented target, keeping ordinary unselected launches unchanged."""
    selected = [key for key in SELECTORS if environment.get(key)]
    tuning = [key for key in ("HERO", "DIFFICULTY", "SEED") if environment.get(key)]
    if not selected and not tuning:
        return []
    if len(selected) != 1:
        raise ValueError("Choose exactly one LEVEL, MINIBOSS or BOSS selector.")
    kind = selected[0]
    target = environment[kind]
    if not any(item["kind"] == kind.lower() and item["id"] == target for item in REGISTRY["targets"]):
        raise ValueError(f"Unknown or unimplemented {kind}={target}. Run make run-targets.")
    hero = environment.get("HERO") or "tony"
    difficulty = environment.get("DIFFICULTY") or "normal"
    seed = environment.get("SEED") or "42"
    if hero not in REGISTRY["heroes"]:
        raise ValueError(f"Unknown HERO={hero}; choose tony or sean.")
    if difficulty not in REGISTRY["difficulties"]:
        raise ValueError(f"Unknown DIFFICULTY={difficulty}; choose easy, normal or hard.")
    if not seed.isascii() or not seed.isdecimal() or not 0 <= int(seed) <= 2147483647:
        raise ValueError("SEED must be an integer from 0 through 2147483647.")
    return [f"--{kind.lower()}={target}", f"--hero={hero}", f"--difficulty={difficulty}", f"--seed={seed}"]


def command(environment: dict[str, str], preview: bool = False, check: bool = False) -> list[str]:
    """Build argv for a source editor or an explicitly selected macOS app bundle."""
    arguments = launch_arguments(environment)
    if check and not arguments:
        raise ValueError("run-check needs a LEVEL, MINIBOSS or BOSS selector.")
    if environment.get("APP"):
        app = Path(environment["APP"]).expanduser().resolve()
        info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
        executable = str(app / "Contents/MacOS" / info["CFBundleExecutable"])
        result = [executable]
    else:
        result = [environment.get("GODOT") or str(ROOT / ".tools/Godot.app/Contents/MacOS/Godot"),
                  "--path", str(ROOT)]
    if check:
        result.append("--headless")
        arguments.append("--verify-playtest-launch")
    if preview:
        arguments.append("--agent-test")
    return result + (["--", *arguments] if arguments else [])


def main() -> int:
    """List implemented targets or launch with validated optional development selectors."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="List implemented targets without launching")
    parser.add_argument("--preview", action="store_true", help="Use the small agent-test window")
    parser.add_argument("--check", action="store_true", help="Headless initialization check; exits without playing")
    args = parser.parse_args()
    if args.list:
        for target in REGISTRY["targets"]:
            print(f"{target['kind'].upper()}={target['id']}  {target['name']}")
        print("No full BOSS target is implemented. HERO=tony|sean DIFFICULTY=easy|normal|hard SEED=0..2147483647")
        return 0
    try:
        return subprocess.run(command(dict(os.environ), args.preview, args.check), cwd=ROOT, check=False).returncode
    except (ValueError, OSError, KeyError, plistlib.InvalidFileException) as error:
        print(f"Launch failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
