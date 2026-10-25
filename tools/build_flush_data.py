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
    layout = read("levels/level-two-flush-v2.json")
    story = read("handoffs/level-two-flush-story.json")
    audio = read("handoffs/level-two-flush-audio.json")
    audio["cues"] = [cue for cue in audio["cues"] if cue["event"] != "debris_break"]
    audio["cues"].append(read("handoffs/level-two-flush-audio-v2.json")["cue"])
    for cue in audio["cues"]:
        payload = (ROOT / cue["path"]).read_bytes()
        if hashlib.sha256(payload).hexdigest() != cue["sha256"]:
            raise ValueError(f"Audio hash mismatch: {cue['path']}")
    for mode in ("easy", "normal", "hard"):
        boundary = 8.0
        for wave in layout["difficulty"][mode]["waves"]:
            if abs(wave["at"] - boundary) > 1e-6 or not 1 <= wave["count"] <= 5 or wave["duration"] < 1.8:
                raise ValueError(f"Unsafe or discontinuous falling cohort: {wave['id']}")
            boundary += wave["duration"]
        if abs(boundary - 35.0) > 1e-6:
            raise ValueError(f"Rain must end at 35 seconds: {mode}")
    for hero in ("tony", "sean"):
        for line in story["routes"][hero]:
            if line.get("gag") and line["at"] + line["duration"] > 8:
                raise ValueError("The center overlay must clear before hazards")
    art = read("assets/world/level-two-flush-v1/manifest.json")
    revision = read("assets/world/level-two-flush-v2/manifest.json")
    art["frames"].update(revision["frames"])
    art["animations"] = revision["animations"]
    art["revision"] = revision
    frames = list(art["frames"].values())
    for key in ("water", "tony_normal", "tony_hard", "sean_normal", "sean_hard"):
        animation = art["animations"][key]
        if len(animation["frames"]) < 8 or animation["fps"] <= 0:
            raise ValueError(f"Missing authored animation phases: {key}")
        frames.extend(animation["frames"])
    for frame in frames:
        if not (ROOT / frame["path"]).is_file():
            raise ValueError(f"Missing artwork: {frame['path']}")
        if any(value <= 0 for value in frame["source_rect"][2:] + frame["destination"][2:]):
            raise ValueError(f"Empty artwork rectangle: {frame['path']}")
    return {"layout": layout, "story": story, "audio": audio, "art": art}


if __name__ == "__main__":
    output = ROOT / "data/level-two-flush.json"
    output.write_text(json.dumps(build(), indent=2) + "\n")
    print(f"Validated Level 2 flush content: {output.name}")
