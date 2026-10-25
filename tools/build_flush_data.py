#!/usr/bin/env python3
"""Validate the short Level 2 sources and package their runtime-only content."""

import hashlib
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> dict[str, Any]:
    """Read one canonical project JSON record."""
    return json.loads((ROOT / path).read_text())


def build() -> dict[str, Any]:
    """Reject incomplete audio or unsafe timing before producing exportable data."""
    layout = read("levels/level-two-flush.json")
    story = read("handoffs/level-two-flush-story.json")
    audio = read("handoffs/level-two-flush-audio.json")
    for cue in audio["cues"]:
        payload = (ROOT / cue["path"]).read_bytes()
        if hashlib.sha256(payload).hexdigest() != cue["sha256"]:
            raise ValueError(f"Audio hash mismatch: {cue['path']}")
    for mode in ("easy", "normal", "hard"):
        for hazard in layout["difficulty"][mode]["hazards"]:
            if hazard["at"] < 8 or hazard["at"] + hazard["warning_seconds"] + hazard["lifetime_seconds"] > 35:
                raise ValueError(f"Hazard outside safe timing contract: {hazard['id']}")
    for hero in ("tony", "sean"):
        for line in story["routes"][hero]:
            if line.get("gag") and line["at"] + line["duration"] > 8:
                raise ValueError("The center overlay must clear before hazards")
    art = read("assets/world/level-two-flush-v1/manifest.json")
    for frame in art["frames"].values():
        if not (ROOT / frame["path"]).is_file():
            raise ValueError(f"Missing artwork: {frame['path']}")
    return {"layout": layout, "story": story, "audio": audio, "art": art}


if __name__ == "__main__":
    output = ROOT / "data/level-two-flush.json"
    output.write_text(json.dumps(build(), indent=2) + "\n")
    print(f"Validated Level 2 flush content: {output.name}")
