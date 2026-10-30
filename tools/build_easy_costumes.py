#!/usr/bin/env python3
"""Register Easy costumes against Art's measured source landmarks and existing gameplay anchors."""

import copy
import json
import math
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
EASY = ROOT / "assets/sprites/easy-mode"
HARD = ROOT / "assets/sprites/hard-mode"


def read(path: Path) -> dict[str, Any]:
    """Read a canonical registration or runtime manifest."""
    return json.loads(path.read_text())


def write(path: Path, data: dict[str, Any]) -> None:
    """Write deterministic runtime metadata without touching original artwork."""
    path.write_text(json.dumps(data, indent=2) + "\n")


def registered(sheet: str, frame_id: str) -> dict[str, Any]:
    """Find an explicit source pose; missing registrations are errors, never Normal fallbacks."""
    registration = read(EASY / "registration-v1.json")["sheets"][sheet]
    frame = copy.deepcopy(next(frame for frame in registration["frames"] if frame["id"] == frame_id))
    frame["path"] = registration["path"]
    return frame


def costume_metadata(data: dict[str, Any]) -> None:
    """Remove inherited costume claims while retaining shared machine and gameplay contracts."""
    for key in ("validation", "facial_hair_revision", "bloody_impact_revision",
                "source_validation_not_applicable_to_costume", "body_measurements", "arm_measurements",
                "inherited_standing_source"):
        data.pop(key, None)
    data["source_manifest"] = "assets/sprites/easy-mode/registration-v1.json"
    data["status"] = "Easy runtime integration; rendered acceptance in progress"
    data["date"] = "2026-10-29"


def body_layer(hero: str, airborne: bool) -> tuple[dict[str, Any], list[float], list[float]]:
    """Place the shoulder at the established aim anchor; ground soles remain at baseline104."""
    sheet = "airborne-bodies-v1.png" if airborne else f"{hero}-parts-v1.png"
    frame = registered(sheet, f"{hero}-airborne-body" if airborne else f"{hero}-standing-body-0")
    landmarks = frame["landmarks"]
    front = landmarks["front_shoulder"]
    back = landmarks["back_shoulder"]
    scale = 22 / (back[0] - front[0]) if airborne else 40 / (landmarks["feet_midpoint"][1] - front[1])
    rect = frame["source_rect"]
    near = [52.0, 64.0]
    far = [near[0] + (back[0] - front[0]) * scale, near[1] + (back[1] - front[1]) * scale]
    return {"role": "body", "path": frame["path"], "source_rect": rect,
            "destination": [near[0] + (rect[0] - front[0]) * scale,
                            near[1] + (rect[1] - front[1]) * scale, rect[2] * scale, rect[3] * scale],
            "pivot": [64, 104], "rotation_degrees": 0}, near, far


def arm_layer(frame: dict[str, Any], role: str, shoulder: list[float], grip: list[float]) -> dict[str, Any]:
    """Solve the source shoulder-to-grip transform against unchanged gameplay weapon landmarks."""
    marks = frame["landmarks"]
    source = [marks["grip"][i] - marks["shoulder"][i] for i in range(2)]
    target = [grip[i] - shoulder[i] for i in range(2)]
    scale = math.hypot(*target) / math.hypot(*source)
    angle = math.degrees(math.atan2(target[1], target[0]) - math.atan2(source[1], source[0]))
    rect = marks["hand_source_rect"] if role == "front_hand" else frame["source_rect"]
    return {"role": role, "path": frame["path"], "source_rect": rect,
            "destination": [shoulder[0] + (rect[0] - marks["shoulder"][0]) * scale,
                            shoulder[1] + (rect[1] - marks["shoulder"][1]) * scale,
                            rect[2] * scale, rect[3] * scale], "pivot": shoulder, "rotation_degrees": angle}


def aim_pose(original: dict[str, Any]) -> dict[str, Any]:
    """Retain gameplay grip/muzzle and weapon layers, registering only costume art anew."""
    pose = copy.deepcopy(original)
    hero, stance, direction = pose["id"].split("-")
    body, near, far = body_layer(hero, stance == "airborne")
    layers = []
    for old in pose["layers"]:
        role = old["role"]
        if role == "body":
            layers.append(body)
        elif role == "weapon":
            layers.append(old)
        else:
            back = role in ("back_arm", "front_hand")
            if direction.startswith("down") or (back and direction.startswith("up")):
                # The extended arm provides enough reach without enlarging the fist and shoulder.
                index = (0 if direction in ("down_right", "up_right") else 2) + int(back)
                frame = registered("downward-arms-v1.png", f"{hero}-down-arm-{index}")
            else:
                sheet = f"{hero}-parts-v1.png"
                if "left-support-hand" in old["path"]:
                    sheet = "sean-left-support-hand-v1.png"
                arm_direction = "up-right" if direction == "up" else direction.replace("_", "-")
                frame = registered(sheet, ("back-" if back else "front-") + arm_direction)
            grip = list(pose["support_hand"] if back else pose["grip"])
            if hero == "sean" and back and direction in ("right", "down_right"):
                grip[1] -= 2
            layers.append(arm_layer(frame, role, far if back else near, grip))
    pose["layers"] = layers
    return pose


def fit_frame(old: dict[str, Any], frame: dict[str, Any], height: float,
              anchor: tuple[float, float] = (64, 104)) -> dict[str, Any]:
    """Fit a full-body pose to its presentation anchor, preserving timing metadata."""
    result = copy.deepcopy(old)
    rect = frame["source_rect"]
    scale = height / rect[3]
    contact = frame["landmarks"].get("feet_midpoint", frame.get("geometric_bottom_center"))
    result.update(path=frame["path"], source_rect=rect,
                  destination=[anchor[0] + (rect[0] - contact[0]) * scale,
                               anchor[1] + (rect[1] - contact[1]) * scale, rect[2] * scale, rect[3] * scale])
    return result


def build_animation() -> None:
    """Preserve phase timing while measuring each new body and its arm attachment."""
    data = read(HARD / "animation-manifest-v1.json")
    costume_metadata(data)
    for hero, entry in data["heroes"].items():
        standing = registered(f"{hero}-parts-v1.png", f"{hero}-standing-body-0")
        entry["head_icon"].update(path=standing["path"], source_rect=standing["landmarks"]["head_source_rect"])
        motion_sheet = "tony-motion-v3.png" if hero == "tony" else "sean-motion-v1.png"
        reference = registered(motion_sheet, f"{hero}-run0")["landmarks"]
        # Revised sheets have different pixel sizes. Keep one anatomical scale across all phases
        # so jumps and run bob do not resize the costume or alter gameplay attachment offsets.
        scale = 40 / (reference["row_reference_ground_y"] - reference["front_shoulder"][1])
        for phase, animation in entry["phases"].items():
            for index, old in enumerate(animation["frames"]):
                semantic = f"run{index}" if phase == "run" else phase
                frame = registered(motion_sheet, f"{hero}-{semantic}")
                marks, rect = frame["landmarks"], frame["source_rect"]
                shoulder = [52 + old["attachment_offset"][0], 64 + old["attachment_offset"][1]]
                if marks["contact_state"] in ("grounded", "run-flight"):
                    clearance = marks["suggested_run_flight_clearance_canvas_px"]
                    shoulder[1] = 104 - clearance + (marks["front_shoulder"][1]
                                                    - marks["ground_plane_anchor"][1]) * scale
                old.update(path=frame["path"], source_rect=rect,
                           destination=[shoulder[0] + (rect[0] - marks["front_shoulder"][0]) * scale,
                                        shoulder[1] + (rect[1] - marks["front_shoulder"][1]) * scale,
                                        rect[2] * scale, rect[3] * scale],
                           attachment_offset=[shoulder[0] - 52, shoulder[1] - 64])
        for index, old in enumerate(entry["death"]):
            semantic = ["recoil", "airborne-fall", "ground-impact", "settled"][index]
            frame = registered("death-v1.png", f"{hero}-{semantic}")
            entry["death"][index] = fit_frame(old, frame, min(80, frame["source_rect"][3] * 0.2))
    data["additional_aim_poses"] = [aim_pose(pose) for pose in data["additional_aim_poses"]]
    data["status"] = "Easy registrations pending rendered acceptance"
    write(EASY / "animation-manifest-v1.json", data)


def build_dispenser() -> None:
    """Keep the shared machine while registering every employee state and sleeping clone."""
    data = read(HARD / "dispenser-manifest-v1.json")
    sleeping = read(HARD / "sleeping-manifest-v1.json")
    costume_metadata(data)
    costume_metadata(sleeping)
    sleeping["notes"] = ["Four authored Easy breathing poses per hero; runtime preserves the shared sleep cycle."]
    for hero, entry in data["heroes"].items():
        for index, name in enumerate(["grab", "compress", "ball", "emerge", "look_right", "look_left", "shrug"]):
            frame = registered(f"{hero}-dispenser-v1.png", f"{hero}-dispenser-source-{index}")
            entry["states"][name] = fit_frame(entry["states"][name], frame, 76 if name != "ball" else 95,
                                                   (64, 104) if name != "ball" else (64, 100))
        for name, semantic in [("impact", "impact"), ("slide", "sliding-impact"), ("blood_trail", "drips")]:
            frame = registered("bloody-impact-v1.png", f"{hero}-{semantic}")
            entry["states"][name] = fit_frame(entry["states"][name], frame, 110, (64, 120))
        for index, old in enumerate(sleeping["heroes"][hero]):
            sleeping["heroes"][hero][index] = fit_frame(old,
                registered("sleeping-heroes-v1.png", f"{hero}-sleep{index}"), 80)
    data["machine"]["sleeping_occupants"]["source_manifest"] = "assets/sprites/easy-mode/sleeping-manifest-v1.json"
    write(EASY / "sleeping-manifest-v1.json", sleeping)
    write(EASY / "dispenser-manifest-v1.json", data)
    path = ROOT / "assets/world/spare-employee-dispenser/inspection-contract-v1.json"
    inspection = read(path)
    inspection["hero_states"]["easy"] = {}
    for hero in ("tony", "sean"):
        inspection["hero_states"]["easy"][hero] = {"grab": fit_frame(
            inspection["hero_states"]["normal"][hero]["grab"],
            registered("held-heroes-v1.png", f"{hero}-held-inspection"), 90)}
    write(path, inspection)


def build_transitions() -> None:
    """Register swimming waterlines, board contacts and portal departure independently."""
    path = ROOT / "assets/world/first-call/portal-departure-manifest-v1.json"
    departure = read(path)
    departure["heroes"]["easy"] = {}
    for hero in ("tony", "sean"):
        departure["heroes"]["easy"][hero] = fit_frame(departure["heroes"]["normal"][hero],
            registered("portal-panic-v1.png", f"{hero}-portal-pull"), 76)
    write(path, departure)
    art = {"animations": {}, "landing": {}}
    normal = read(ROOT / "assets/world/level-two-flush-v2/manifest.json")
    landing = read(ROOT / "assets/world/level-two-flush-v3/manifest.json")
    for hero in ("tony", "sean"):
        animation = copy.deepcopy(normal["animations"][hero + "_normal"])
        for index, old in enumerate(animation["frames"]):
            frame = registered(f"{hero}-flush-v1.png", f"{hero}-swim{index}")
            rect, waterline = frame["source_rect"], frame["landmarks"]["waterline_center"]
            scale = 0.22
            old.update(path=frame["path"], source_rect=rect,
                       destination=[(rect[0] - waterline[0]) * scale, (rect[1] - waterline[1]) * scale,
                                    rect[2] * scale, rect[3] * scale])
            for key in ("alpha_cutoff", "force_opaque", "edge_feather", "runtime_texture_key"):
                old.pop(key, None)
        art["animations"][hero + "_easy"] = animation
        pose = copy.deepcopy(landing["landing"][hero]["normal"])
        frame = registered("landing-v2.png", f"{hero}-landing-front")
        rect, contact = frame["source_rect"], frame["landmarks"]["board_reference_center"]
        scale = 130 / rect[2]
        pose["front"] = [{"path": frame["path"], "source_rect": rect,
                          "destination": [(rect[0] - contact[0]) * scale, (rect[1] - contact[1]) * scale,
                                          rect[2] * scale, rect[3] * scale], "anchor": [0, 0]}]
        pose["contact_anchor"] = [0, 0]
        pose["visible_local_extents_y"] = [pose["front"][0]["destination"][1], 0]
        art["landing"][hero] = {"easy": pose}
    write(EASY / "flush-manifest-v1.json", art)
    for file, key in [("assets/world/level-two-camera-test-v1/manifest.json", "rider_support_contacts"),
                      ("assets/world/ride-showcase-v1/manifest.json", "rider_contacts")]:
        path = ROOT / file
        if not path.exists():
            continue
        data = read(path)
        for hero in ("tony", "sean"):
            data[key][hero]["easy"] = [0, 0]
        write(path, data)


def build() -> None:
    """Produce runtime metadata after source registration; visual acceptance is a separate gate."""
    aim = read(HARD / "aim-manifest-v1.json")
    costume_metadata(aim)
    aim["poses"] = [aim_pose(pose) for pose in aim["poses"]]
    aim["status"] = "Easy registered from source landmarks; runtime visual review pending"
    aim["source_manifest"] = "assets/sprites/easy-mode/registration-v1.json"
    for obsolete in ("validation", "body_measurements", "arm_measurements", "facial_hair_revision",
                     "source_validation_not_applicable_to_costume", "inherited_standing_source"):
        aim.pop(obsolete, None)
    write(EASY / "aim-manifest-v1.json", aim)
    build_animation()
    build_dispenser()
    build_transitions()


if __name__ == "__main__":
    build()
