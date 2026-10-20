#!/usr/bin/env python3
"""Validate canonical combat metadata and generate the exportable runtime bundle."""

import hashlib
import json
import math
import struct
import wave
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "data/combat.json"


def require(condition: bool, message: str) -> None:
    """Reject invalid source data with its field context."""
    if not condition:
        raise ValueError(message)


def read(path: str) -> dict[str, Any]:
    """Read one project-relative JSON object."""
    source = (ROOT / path).resolve()
    require(source.is_relative_to(ROOT), f"Path escapes project: {path}")
    data = json.loads(source.read_text())
    require(isinstance(data, dict), f"{path}: expected object")
    require(data.get("schema_version", 1) == 1, f"{path}: unsupported schema")
    return data


def number(data: dict[str, Any], key: str, context: str, minimum: float = 0, strict: bool = True) -> float:
    """Read a finite numeric value, rejecting booleans and invalid ranges."""
    value = data.get(key)
    require(type(value) in (int, float) and math.isfinite(value), f"{context}.{key}: expected finite number")
    require(value > minimum if strict else value >= minimum, f"{context}.{key}: invalid range")
    return value


def validate_weapon(data: dict[str, Any], weapon_id: str, owner: str) -> None:
    """Validate identity, exclusivity, timing, targeting, and trajectory data."""
    require(data.get("id") == weapon_id, f"{weapon_id}: mismatched ID")
    require(owner in ("tony", "sean") and data.get("owner") == owner, f"{weapon_id}: invalid owner")
    require(data.get("exclusive") is True, f"{weapon_id}: exclusive must be true")
    require(isinstance(data.get("name"), str) and bool(data["name"]), f"{weapon_id}: missing name")
    number(data, "damage", weapon_id)
    interval = number(data, "attack_interval_seconds", weapon_id)
    require(number(data, "windup_seconds", weapon_id, strict=False) < interval, f"{weapon_id}: windup >= interval")
    require(data.get("type") in ("melee", "ranged"), f"{weapon_id}: unknown weapon type")
    if weapon_id in ("pressure-gun", "heavy-plunger-launcher"):
        aiming = data.get("aiming")
        require(isinstance(aiming, dict), f"{weapon_id}: missing aiming permissions")
        directions = {"left", "right", "up", "down", "up_left", "up_right", "down_left", "down_right"}
        for state in ("grounded_directions", "airborne_directions"):
            allowed = aiming.get(state)
            require(isinstance(allowed, list) and bool(allowed), f"{weapon_id}: missing {state}")
            require(all(direction in directions for direction in allowed), f"{weapon_id}: invalid direction")
    targeting = data.get("targeting")
    require(isinstance(targeting, dict), f"{weapon_id}: missing targeting")
    limit = targeting.get("max_targets_per_attack")
    require(limit is None or type(limit) is int and limit > 0, f"{weapon_id}: invalid target limit")
    if data["type"] == "melee":
        number(data, "melee_reach_pixels", weapon_id)
        require(data.get("projectile") is None, f"{weapon_id}: melee cannot have projectile")
    else:
        projectile = data.get("projectile")
        require(isinstance(projectile, dict), f"{weapon_id}: missing projectile")
        number(projectile, "speed_pixels_per_second", weapon_id)
        number(projectile, "max_travel_distance_pixels", weapon_id)
        number(projectile, "gravity_pixels_per_second_squared", weapon_id, strict=False)
        angle = number(projectile, "launch_angle_degrees_above_horizontal", weapon_id, strict=False)
        require(angle <= 90, f"{weapon_id}: invalid launch angle")
        require(projectile.get("trajectory") in ("straight", "ballistic"), f"{weapon_id}: unknown trajectory")
        if projectile["trajectory"] == "straight":
            require(projectile["gravity_pixels_per_second_squared"] == 0 and angle == 0,
                    f"{weapon_id}: straight projectile must have zero gravity and angle")
        else:
            require(isinstance(data.get("explosion"), dict), f"{weapon_id}: missing explosion")
            number(data["explosion"], "radius_pixels", weapon_id)


def dispenser_data() -> dict[str, Any]:
    """Validate versioned checkpoint art and audio before packaging their runtime contract."""
    art = read("assets/world/spare-employee-dispenser/manifest-v6.json")
    art["sleeping_heroes"] = read(art["machine"]["sleeping_occupants"]["source_manifest"])
    audio = read("handoffs/spare-employee-dispenser-audio.json")

    def validate_frames(value: Any) -> None:
        if isinstance(value, dict):
            if "source_rect" in value and "path" in value:
                path = ROOT / value["path"]
                require(path.is_file(), f"Missing dispenser art: {path}")
                header = path.read_bytes()[:24]
                require(header[:8] == b"\x89PNG\r\n\x1a\n", "Dispenser artwork must be PNG")
                width, height = struct.unpack(">II", header[16:24])
                x, y, w, h = value["source_rect"]
                require(x >= 0 and y >= 0 and w > 0 and h > 0 and x + w <= width and y + h <= height,
                        f"Dispenser source crop outside {path}")
                require(len(value["destination"]) == 4, "Missing dispenser destination")
            for child in value.values():
                validate_frames(child)
        elif isinstance(value, list):
            for child in value:
                validate_frames(child)

    validate_frames(art)
    inspection = read("assets/world/spare-employee-dispenser/inspection-contract-v1.json")
    validate_art_regions(inspection)
    require(0 < inspection["release_seconds"] < inspection["watchdog_seconds"] <= 7,
            "Inspection must release before its watchdog")
    for cue in audio["cues"]:
        path = ROOT / cue["path"]
        require(path.is_file(), f"Missing dispenser audio: {path}")
        require(hashlib.sha256(path.read_bytes()).hexdigest() == cue["sha256"], "Dispenser cue hash mismatch")
        require(cue["loop"] is False, "Dispenser cues cannot loop")
    for timeline, limit in [(art["timeline"], 7), (art["short_paths"]["full_health"], 0.5),
                            (art["short_paths"]["respawn"], 2)]:
        times = [event["time"] for event in timeline]
        require(times == sorted(times) and 0 <= times[0] and times[-1] <= limit, "Dispenser timing invalid")
        require(timeline[-1]["event"] == "release", "Dispenser must release control")
    return {"art": art, "audio": {"cues": audio["cues"], "event_mapping": audio["event_mapping"]}}


def validate_art_regions(value: Any) -> None:
    """Reject missing textures and out-of-bounds atlas crops before export."""
    if isinstance(value, dict):
        if "path" in value and "source_rect" in value:
            path = (ROOT / value["path"]).resolve()
            require(path.is_relative_to(ROOT) and path.is_file(), f"Missing art: {path}")
            header = path.read_bytes()[:24]
            require(header[:8] == b"\x89PNG\r\n\x1a\n", f"Expected PNG: {path}")
            width, height = struct.unpack(">II", header[16:24])
            x, y, w, h = value["source_rect"]
            require(all(type(n) in (int, float) and math.isfinite(n) for n in (x, y, w, h)),
                    f"Invalid crop: {path}")
            require(x >= 0 and y >= 0 and w > 0 and h > 0 and x + w <= width and y + h <= height,
                    f"Art crop outside texture: {path}")
        for child in value.values():
            validate_art_regions(child)
    elif isinstance(value, list):
        for child in value:
            validate_art_regions(child)


def validate_rooted_boss() -> None:
    """Reject incomplete boss attack, damage, collapse, and HUD artwork before export."""
    manifest = read("assets/bestiary/the-clogfather/runtime-manifest-v3.json")
    required = {"body", "sludge_relaxed", "sludge_swell", "weak_closed", "weak_open", "drool",
                "sludge_projectile_a", "sludge_projectile_b", "acid_warning", "acid_ceiling_warning",
                "acid_drop", "acid_puddle", "weak_hit", "deflect", "weak_high_closed", "weak_high_open"}
    required.update(f"damage_body_{stage}" for stage in ("healthy", "mild", "moderate", "severe", "near_death"))
    required.update(f"collapse_{index}" for index in range(6))
    require(required <= manifest.get("frames", {}).keys(), "Missing rooted boss attack or animation artwork")
    require({"frame", "track", "fill_green", "fill_yellow", "fill_red", "aperture"}
            <= manifest.get("hud", {}).keys(), "Missing rooted boss health bar artwork")
    validate_art_regions(manifest)


def validate_compound_boss() -> None:
    """Validate enabled compound-boss frames and authored room crops before export."""
    manifest = read("assets/bestiary/cockroach-swarm/runtime-manifest-v1.json")
    require(manifest["canvas"] == [384, 256] and manifest["anchor"] == [192, 224], "Boss anchor mismatch")
    require(manifest["alpha_cutoff"] == 240, "Boss alpha policy mismatch")
    sheets = {sheet["id"]: sheet for sheet in manifest["sheets"]}
    for sheet in sheets.values():
        path = ROOT / sheet["path"]
        require(hashlib.sha256(path.read_bytes()).hexdigest() == sheet["sha256"], "Boss sheet hash mismatch")
        for frame in sheet["frames"]:
            validate_art_regions({"path": sheet["path"], "source_rect": frame["source_rect"]})
    for animation in manifest["animations"].values():
        require(animation["sheet"] in sheets and bool(animation["frames"]), "Missing boss animation")
        frames = {frame["id"]: frame for frame in sheets[animation["sheet"]]["frames"]}
        for frame_id in animation["frames"]:
            require(frame_id in frames and frames[frame_id]["enabled"], "Disabled boss frame in animation")
            require(frames[frame_id]["edge_pixels"] == 0, "Boss frame touches crop edge")
    room = read("assets/world/skitterling-room/manifest-v1.json")
    for frame in room["background"]["strips"]:
        validate_art_regions({"path": room["background"]["path"], "source_rect": frame["source_rect"]})
    for prop in room["pipes"]["props"].values():
        validate_art_regions({"path": room["pipes"]["path"], "source_rect": prop["source_rect"]})
    for frame in room["effects"]["frames"]:
        validate_art_regions({"path": room["effects"]["path"], "source_rect": frame["source_rect"]})
    portals = room["portals"]
    require(portals["alpha_cutoff"] == 240, "Portal alpha policy mismatch")
    require({item["id"]: item["local_x"] for item in portals["instances"]}
            == {"entry": -120, "exit": 840}, "Portal/world collision registration mismatch")
    for layer in portals["layers"].values():
        validate_art_regions({"path": portals["path"], "source_rect": layer["source_rect"]})


def wastewater_data() -> dict[str, Any]:
    """Package approved scenery and its world-position progression independently of combat."""
    art = read("assets/world/wastewater-cutaway/manifest-v1.json")
    progression = read("handoffs/wastewater-cutaway-level-design.json")["progression"]
    require(art["profile"] == progression, "Pipe art and layout profiles differ")
    validate_art_regions(art)
    return {"art": art, "progression": progression}


def opening_trial_data(weapons: dict[str, Any]) -> dict[str, Any]:
    """Validate the explicitly selected trial without altering normal weapon records."""
    balance = read("design/first-call-action/opening-trial-balance.json")
    layout = read("handoffs/opening-trial-level-layout.json")
    for weapon_id, override in balance["weapons"].items():
        require(override["owner"] == weapons[weapon_id]["owner"], "Trial weapon owner mismatch")
        number(override, "damage", weapon_id)
        number(override, "attack_interval_seconds", weapon_id)
    require(len(layout["timeline"]) == 12, "Opening trial requires twelve finite event IDs")
    require(len({event["id"] for event in layout["timeline"]}) == 12, "Duplicate trial event")
    for role, value in balance["roles"].items():
        require(number(value, "spawn_hp", role) <= number(value, "max_hp", role), "Invalid trial HP")
    result = {"balance": balance, "layout": layout,
              "environment": read("assets/world/opening-trial/manifest-v1.json"),
              "role_art": read("assets/bestiary/opening-trial/manifest-v1.json")}
    replacements = {part["id"]: part for part in
                    read("assets/world/platform-readability-v3/manifest-v3.json")["parts"]}
    result["environment"]["parts"] = [replacements.get(part["id"], part)
                                       for part in result["environment"]["parts"]]
    validate_art_regions(result)
    validate_art_regions(read("assets/bestiary/gratecrawler/muck-ball-manifest-v1.json"))
    validate_art_regions(read("assets/world/first-call/portal-manifest-v1.json"))
    validate_art_regions(read("assets/world/first-call/portal-departure-manifest-v1.json"))
    return result


def validate_creature_audio(monster: dict[str, Any], creature_id: str) -> dict[str, Any]:
    """Require complete, verifiable hit/death assets for playable and planned creatures alike."""
    audio = monster.get("audio")
    require(isinstance(audio, dict), f"{creature_id}: missing hit/death audio")
    require(audio.get("schema_version") == 1, f"{creature_id}: unsupported audio schema")
    require(audio.get("status") in ("profile_ready", "runtime_integrated"), f"{creature_id}: invalid audio status")
    manifest = audio.get("manifest")
    require(isinstance(manifest, str) and bool(manifest), f"{creature_id}: missing audio provenance")
    read(manifest)
    for event in ("hit", "death"):
        context = f"{creature_id}.audio.{event}"
        cue = audio.get(event)
        require(isinstance(cue, dict), f"{context}: missing cue")
        require(cue.get("loop") is False, f"{context}: damage audio cannot loop")
        cooldown = number(cue, "cooldown_seconds", context, strict=False)
        require(cooldown <= 1 and (event != "death" or cooldown == 0), f"{context}: invalid cooldown")
        voices = cue.get("max_voices")
        require(type(voices) is int and 1 <= voices <= 4, f"{context}: expected bounded voice count")
        variants = cue.get("variants")
        require(isinstance(variants, list) and 1 <= len(variants) <= 4, f"{context}: missing/invalid variants")
        for variant in variants:
            require(isinstance(variant, dict), f"{context}: invalid variant")
            path = variant.get("path")
            require(isinstance(path, str) and path.startswith("assets/audio/"), f"{context}: invalid audio path")
            source = (ROOT / path).resolve()
            require(source.is_relative_to(ROOT / "assets/audio") and source.is_file(), f"{context}: missing asset")
            require(hashlib.sha256(source.read_bytes()).hexdigest() == variant.get("sha256"),
                    f"{context}: audio hash mismatch")
            gain = variant.get("gain_db")
            require(type(gain) in (int, float) and math.isfinite(gain) and -60 <= gain <= 0,
                    f"{context}: invalid playback gain")
            try:
                with wave.open(str(source)) as stream:
                    require(stream.getcomptype() == "NONE" and stream.getsampwidth() == 2
                            and stream.getnchannels() == 1 and 22050 <= stream.getframerate() <= 96000
                            and stream.getnframes() > 0, f"{context}: expected nonempty mono PCM16 WAV")
            except (wave.Error, EOFError) as error:
                raise ValueError(f"{context}: invalid WAV") from error
    return audio


def build() -> dict[str, Any]:
    """Compile catalogs by following canonical metadata links, never summary stats."""
    weapons: dict[str, Any] = {}
    for entry in read("weapons/catalog.json")["weapons"]:
        weapon_id = entry["id"]
        require(isinstance(weapon_id, str) and weapon_id not in weapons, f"Duplicate/invalid weapon ID: {weapon_id}")
        weapon = read(entry["metadata"])
        validate_weapon(weapon, weapon_id, entry["owner"])
        weapons[weapon_id] = weapon
    policy = read("assets/bestiary/damage/health-visuals.json")
    states = policy["states"]
    require(len(states) == 6 and states[-1].get("equals") == 0, "Invalid damage stages")
    ceiling = 1.0
    for state in states[:-1]:
        require(state["max_inclusive"] == ceiling, "Damage stages must cover [0,1] without gaps")
        floor = number(state, "min_exclusive", state["id"], strict=False)
        require(floor < ceiling, "Invalid damage stage range")
        ceiling = floor
    require(ceiling == 0 and len({s["id"] for s in states}) == 6, "Invalid damage stage IDs/coverage")
    require(type(policy["ordinary_enemy_bars_default"]) is bool, "Bar default must be boolean")
    number(policy["hit_feedback"], "suggested_flash_seconds", "hit_feedback")
    hud = policy["boss_hud"]
    require(number(hud, "width_fraction", "boss_hud") <= 1, "Boss bar width exceeds viewport")
    for field in ("reference_bar_height_pixels", "reserved_band_pixels", "death_hold_seconds", "death_fade_seconds"):
        number(hud, field, "boss_hud")
    for field in ("trail_delay_seconds", "trail_catchup_seconds"):
        number(hud["damage_feedback"], field, "boss_hud.damage_feedback")
    monsters: dict[str, Any] = {}
    creature_entries = read("assets/bestiary/catalog.json")["creatures"]
    registered_profiles = [(ROOT / entry["metadata"]).resolve() for entry in creature_entries]
    canonical_profiles = {path.resolve() for path in (ROOT / "bestiary").glob("*/monster.json")}
    require(len(registered_profiles) == len(set(registered_profiles)), "Duplicate canonical creature profile")
    require(set(registered_profiles) == canonical_profiles, "Creature catalog must cover every canonical profile")
    for entry in creature_entries:
        monster_id = entry["id"]
        require(monster_id not in monsters, f"Duplicate creature: {monster_id}")
        monster = read(entry["metadata"])
        require(monster.get("id") == monster_id, f"{monster_id}: mismatched canonical ID")
        audio = validate_creature_audio(monster, monster_id)
        pursuit = monster.get("pursuit")
        if pursuit is not None:
            require(isinstance(pursuit, dict), f"{monster_id}: invalid pursuit")
            for field in ("notice_range_pixels", "patrol_range_pixels", "patrol_speed_pixels_per_second",
                          "chase_speed_pixels_per_second", "stop_distance_pixels"):
                number(pursuit, field, monster_id)
            require(pursuit.get("persistent_after_detection") is True, f"{monster_id}: pursuit must persist")
            require(pursuit.get("disengage_distance_pixels") is None
                    and pursuit.get("chase_leash_pixels") is None, f"{monster_id}: unsupported chase leash")
            turn = pursuit.get("turnaround")
            if turn is not None:
                require(isinstance(turn, dict), f"{monster_id}: invalid turnaround")
                brake = number(turn, "brake_seconds", monster_id)
                stopped = number(turn, "stopped_turn_seconds", monster_id)
                number(turn, "accelerate_seconds", monster_id)
                total = number(turn, "total_before_reverse_pursuit_seconds", monster_id)
                require(math.isclose(brake + stopped, total), f"{monster_id}: inconsistent turnaround timing")
        health = monster["health"]
        maximum = number(health, "max_hp", monster_id)
        require(number(health, "spawn_hp", monster_id) <= maximum, f"{monster_id}: spawn exceeds maximum HP")
        for flag in ("enabled", "visible_by_default"):
            require(type(health["bar"][flag]) is bool, f"{monster_id}: {flag} must be boolean")
        for weapon_id, hits in health["hits_to_defeat"].items():
            require(weapon_id in weapons, f"{monster_id}: unknown weapon {weapon_id}")
            require(hits == math.ceil(maximum / weapons[weapon_id]["damage"]),
                    f"{monster_id}: stale hit comparison for {weapon_id}")
        if monster_id == "sewer-fly-swarm":
            movement = monster["movement"]
            require(movement["model"] == "bounded_correlated_wander", "Unsupported swarm movement")
            for field in ("speed_pixels_per_second", "acceleration_pixels_per_second_squared",
                          "heading_update_seconds", "max_random_heading_delta_degrees",
                          "max_turn_rate_degrees_per_second", "contact_radius_pixels",
                          "boundary_steering_margin_pixels", "obstacle_lookahead_seconds"):
                number(movement, field, monster_id)
            require(0 <= movement["hover_pause_probability"] <= 1, "Invalid hover probability")
            for field in ("hover_decision_interval_seconds", "hover_pause_seconds"):
                values = movement[field]
                require(len(values) == 2 and 0 < values[0] <= values[1], "Invalid hover interval")
            for field in ("hero_damage", "monster_damage", "per_target_cooldown_seconds"):
                number(monster["contact"], field, monster_id)
            spec = read(monster["game_art"]["animation"])
            require(spec["image"] == monster["game_art"]["image"], "Swarm atlas mismatch")
            require((ROOT / spec["image"]).is_file(), "Missing swarm atlas")
            require(spec["logical_canvas"] == [64, 64] and spec["anchor"] == [32, 32], "Swarm anchor mismatch")
            require(set(spec["animations"]) == {"hover", "move_up", "move_down", "move_left",
                                                "move_right", "death"}, "Missing swarm animation")
            for name, animation in spec["animations"].items():
                require(animation["loop"] == (name != "death"), "Invalid swarm loop")
                require(len(animation["frames"]) == 4, "Missing swarm frames")
                for frame in animation["frames"]:
                    x, y, width, height = frame["source_rect"]
                    require(width == height == 256 and x >= 0 and y >= 0
                            and x + width <= spec["dimensions"][0]
                            and y + height <= spec["dimensions"][1], "Swarm frame outside atlas")
                    number(frame, "duration_seconds", monster_id)
            monsters[monster_id] = {"audio": audio, "health": health, "name": monster["name"], "damage_art": None,
                                    "movement": movement, "contact": monster["contact"], "animation": spec,
                                    "runtime_support": "optional_swarm"}
            continue
        if monster.get("runtime_support") == "compound_boss":
            require(monster_id == "cockroach-swarm", "Unsupported compound boss")
            rat_hp = number(health, "rat_phase_hp", monster_id)
            alligator_hp = number(health, "alligator_phase_hp", monster_id)
            require(maximum == rat_hp + alligator_hp and health["spawn_hp"] == maximum
                    and health["threshold_hp"] == alligator_hp, "Boss phase budget mismatch")
            validate_compound_boss()
            monsters[monster_id] = {"audio": audio, "health": health, "name": monster["name"], "damage_art": None,
                                    "runtime_support": "compound_boss"}
            continue
        if monster.get("runtime_support") in ("hud_preview_only", "rooted_boss"):
            if monster["runtime_support"] == "rooted_boss":
                require(monster_id == "clogfather", "Unsupported rooted boss")
                validate_rooted_boss()
            monsters[monster_id] = {"audio": audio, "health": health, "name": monster["name"], "damage_art": None,
                                    "runtime_support": monster["runtime_support"]}
            continue
        spec = read(monster["assets"]["damage_animation_spec"])
        require(spec["creature_id"] == monster_id, f"{monster_id}: mismatched damage spec")
        require(spec["image"] == monster["assets"]["damage_sprite_sheet"], f"{monster_id}: art path mismatch")
        require((ROOT / spec["image"]).is_file(), f"{monster_id}: missing atlas")
        layout = spec["layout"]
        for field in ("columns", "rows", "nominal_cell_width", "nominal_cell_height"):
            require(type(layout[field]) is int and layout[field] > 0, f"{monster_id}: invalid {field}")
        count = layout["columns"] * layout["rows"]
        require(len(spec["states"]) == len(states), f"{monster_id}: missing state")
        for state, expected in zip(spec["states"], states):
            require(all(state.get(k) == v for k, v in expected.items()), f"{monster_id}: stage mismatch")
            require(all(type(f) is int and 0 <= f < count for f in state["frames"]),
                    f"{monster_id}: invalid frame")
        require(spec["death"]["loop"] is False, f"{monster_id}: death cannot loop")
        number(spec["death"], "suggested_fps", monster_id)
        number(spec["living_loop"], "suggested_fps", monster_id)
        prepared = spec["runtime_preparation"]
        cutoff = number(prepared, "alpha_cutoff", monster_id)
        require(cutoff <= 1, f"{monster_id}: alpha cutoff exceeds one")
        number(prepared, "reference_body_height_pixels", monster_id)
        require(len(prepared["frames"]) == count, f"{monster_id}: incomplete prepared atlas")
        for frame in prepared["frames"]:
            region, anchor = frame["region"], frame["anchor"]
            require(len(region) == 4 and len(anchor) == 2, f"{monster_id}: invalid region/anchor")
            require(all(type(v) in (int, float) and math.isfinite(v) for v in region + anchor),
                    f"{monster_id}: invalid frame coordinates")
            x, y, width, height = region
            require(x >= 0 and y >= 0 and width > 0 and height > 0
                    and x + width <= spec["dimensions"]["width"]
                    and y + height <= spec["dimensions"]["height"], f"{monster_id}: frame outside atlas")
            require(0 <= anchor[0] <= width and 0 <= anchor[1] <= height,
                    f"{monster_id}: anchor outside frame")
        monsters[monster_id] = {"audio": audio, "health": health, "name": monster["name"], "damage_art": spec,
                                "pursuit": pursuit,
                                "entrance": monster.get("entrance")}
    return {"schema_version": 1, "generated_by": "tools/build_combat_data.py; edit canonical sources",
            "weapons": weapons, "monsters": monsters, "visual_policy": policy, "dispenser": dispenser_data(),
            "opening_trial": opening_trial_data(weapons), "wastewater": wastewater_data()}


if __name__ == "__main__":
    try:
        bundle = build()
        OUTPUT.parent.mkdir(exist_ok=True)
        OUTPUT.write_text(json.dumps(bundle, indent=2) + "\n")
        print(f"Validated {len(bundle['weapons'])} weapons and {len(bundle['monsters'])} monsters: {OUTPUT.name}")
    except (ValueError, KeyError, TypeError, OSError) as error:
        raise SystemExit(f"Combat metadata validation failed: {error}") from error
