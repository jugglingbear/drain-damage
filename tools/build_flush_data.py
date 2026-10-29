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


def validate_radio_gag(story: dict[str, Any]) -> None:
    """Keep the relocation attached to the responding partner within the safe opening."""
    safe_until = float(story["timing"]["calm_prelude_seconds"]) + 8.0
    for hero, partner in (("tony", "sean"), ("sean", "tony")):
        route = story["routes"][hero]
        openers = [line for line in route if line.get("gag_action") == "hold_center"]
        requests = [line for line in route if line.get("retain_partner", False)]
        replies = [line for line in route if line.get("gag_action") == "slide_bottom"]
        if len(openers) != 1 or len(requests) != 1 or len(replies) != 1:
            raise ValueError(f"Expected one window request and response: {hero}")
        opener, request, reply = openers[0], requests[0], replies[0]
        if (opener["who"] != partner or not opener["radio"] or not opener["gag"]
                or opener["at"] + opener["duration"] != request["at"] or request["gag"]):
            raise ValueError(f"Partner must obstruct before the bottom-positioned complaint: {hero}")
        if request["who"] != hero or request["radio"] or "chat window" not in request["text"].lower():
            raise ValueError(f"Playable hero must request the chat window move: {hero}")
        if reply["who"] != partner or not reply["radio"]:
            raise ValueError(f"Partner must own the moving reply and portrait: {hero}")
        start, end = reply["slide_line_seconds"]
        if (request["at"] + request["duration"] != reply["at"] or not 0 <= start < end < reply["duration"]
                or reply["at"] + reply["duration"] > safe_until):
            raise ValueError(f"Window response must finish moving during the safe opening: {hero}")


def artwork_frames(value: Any) -> list[dict[str, Any]]:
    """Collect leaf frames, including layered surfaces and composed landing poses."""
    if isinstance(value, list):
        return [frame for child in value for frame in artwork_frames(child)]
    if isinstance(value, dict):
        if all(key in value for key in ("path", "source_rect", "destination")):
            return [value]
        return [frame for child in value.values() for frame in artwork_frames(child)]
    return []


def build() -> dict[str, Any]:
    """Reject incomplete audio or unsafe timing before producing exportable data."""
    layout = read("levels/level-two-flush-v3.json")
    story = read("handoffs/level-two-flush-story.json")
    validate_radio_gag(story)
    audio = read("handoffs/level-two-flush-audio.json")
    audio["cues"] = [cue for cue in audio["cues"] if cue["event"] != "debris_break"]
    audio["cues"].append(read("handoffs/level-two-flush-audio-v2.json")["cue"])
    score = read("handoffs/flush-countdown-music.json")
    if hashlib.sha256((ROOT / score["asset"]).read_bytes()).hexdigest() != score["sha256"]:
        raise ValueError("Flush score hash mismatch")
    music = {"path": score["asset"], "gain_db": score["gain_db"], "duration_seconds": 45, "loop": False}
    for cue in audio["cues"]:
        payload = (ROOT / cue["path"]).read_bytes()
        if hashlib.sha256(payload).hexdigest() != cue["sha256"]:
            raise ValueError(f"Audio hash mismatch: {cue['path']}")
    for mode in ("easy", "normal", "hard"):
        boundary = 8.0
        for wave in layout["difficulty"][mode]["waves"]:
            if abs(wave["at"] - boundary) > 1e-6 or not 1 <= wave["count"] <= 7 or wave["duration"] < 1.8:
                raise ValueError(f"Unsafe or discontinuous falling cohort: {wave['id']}")
            boundary += wave["duration"]
        if abs(boundary - 35.0) > 1e-6:
            raise ValueError(f"Rain must end at 35 seconds: {mode}")
    safe_until = float(story["timing"]["calm_prelude_seconds"]) + 8.0
    for hero in ("tony", "sean"):
        previous_end = 0.0
        for line in story["routes"][hero]:
            if line["at"] < previous_end or line["duration"] <= 0:
                raise ValueError(f"Overlapping or empty radio line: {hero}")
            previous_end = line["at"] + line["duration"]
            if line.get("event") in ("arrival", "flush") and previous_end > safe_until:
                raise ValueError("Opening dialogue must finish before hazards")
            if line.get("event") == "drain" and previous_end > story["timing"]["landing_start"]:
                raise ValueError("Drain dialogue must finish before landing")
    art = read("assets/world/level-two-flush-v1/manifest.json")
    revision = read("assets/world/level-two-flush-v2/manifest.json")
    art["frames"].update(revision["frames"])
    art["animations"] = revision["animations"]
    art["revision"] = revision
    revision = read("assets/world/level-two-flush-v3/manifest.json")
    art["frames"].update(revision["frames"])
    art["animations"].update(revision["animations"])
    for key in ("surface_depth_pixels", "drain_center", "landing", "landing_rules"):
        art[key] = revision[key]
    art["revision"] = revision
    for key in ("water", "tony_normal", "tony_hard", "sean_normal", "sean_hard"):
        animation = art["animations"][key]
        if len(animation["frames"]) < 8 or animation["fps"] <= 0:
            raise ValueError(f"Missing authored animation phases: {key}")
    for frame in artwork_frames(art):
        if not (ROOT / frame["path"]).is_file():
            raise ValueError(f"Missing artwork: {frame['path']}")
        if any(value <= 0 for value in frame["source_rect"][2:] + frame["destination"][2:]):
            raise ValueError(f"Empty artwork rectangle: {frame['path']}")
    return {"layout": layout, "story": story, "audio": audio, "art": art, "music": music}


if __name__ == "__main__":
    output = ROOT / "data/level-two-flush.json"
    output.write_text(json.dumps(build(), indent=2) + "\n")
    print(f"Validated Level 2 flush content: {output.name}")
