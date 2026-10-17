#!/usr/bin/env python3
"""Validate the authored first-call brief and prepare an integration plan without changing runtime."""

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "levels/first-call/level-design.json"
OUTPUT = ROOT / "handoffs/first-call-runtime-plan.json"
ENEMY_WIDTH = 38
SPAWN_MARGIN = 32


def clear_spawn(x: int, terrain: list[list[int]], checkpoints: list[int], radius: int) -> bool:
    """Check a floor spawn against solid scenery and checkpoint recovery footprints."""
    if any(x < left + width + SPAWN_MARGIN and x + ENEMY_WIDTH > left - SPAWN_MARGIN
           for left, _, width, _ in terrain):
        return False
    return not any(x < point + radius and x + ENEMY_WIDTH > point - radius for point in checkpoints)


def prepare(source: dict[str, Any]) -> dict[str, Any]:
    """Resolve legal floor homes and report constraints requiring explicit design decisions."""
    world = source["world"]
    checkpoints = source["recovery"]["checkpoint_x"]
    radius = source["recovery"]["clear_radius_pixels"]
    terrain = [rect for zone in source["zones"] for rect in zone["terrain"]]
    for x, y, width, height in terrain:
        if width < 120 or height <= 0 or y + height != world["floor_y"]:
            raise ValueError(f"Invalid grounded terrain: {(x, y, width, height)}")
        if x < 0 or x + width > world["width"]:
            raise ValueError("Terrain outside world")
    zones = []
    total = 0
    previous_end = 0
    for zone in source["zones"]:
        start, end = zone["x"]
        if start != previous_end or end <= start:
            raise ValueError("Zone bounds must form a contiguous ordered route")
        previous_end = end
        homes: list[int] = []
        for requested in zone["enemy_x"]:
            candidates = sorted(range(start + SPAWN_MARGIN, end - ENEMY_WIDTH - SPAWN_MARGIN),
                                key=lambda value: (abs(value - requested), value))
            home = next((x for x in candidates if clear_spawn(x, terrain, checkpoints, radius)
                         and all(abs(x - prior) >= ENEMY_WIDTH + SPAWN_MARGIN for prior in homes)), None)
            if home is None:
                raise ValueError(f"No legal spawn pocket for {zone['id']} at {requested}")
            homes.append(home)
        total += len(homes)
        zones.append({"id": zone["id"], "bounds": [start, end], "authored_homes": zone["enemy_x"],
                      "clear_floor_homes": homes, "terrain": zone["terrain"]})
    if total != source["encounter_contract"]["total_authored_enemies"] or previous_end != world["width"]:
        raise ValueError("Enemy total or final zone extent mismatch")
    return {
        "status": "Initial geometry audit only; homes are NOT approved final encounter placement",
        "source": str(SOURCE.relative_to(ROOT)), "world": world, "zones": zones, "enemy_total": total,
        "checkpoints": checkpoints, "active_cap": source["encounter_contract"]["maximum_active_attackers"],
        "spawn_note": "Homes are clear of solids and recovery footprints. Actual activation must also check live player, camera, landing zones and active-enemy overlap.",
        "blocking_decisions": [
            "Prop textures and art-aligned collision metadata are requested from Bestiary / Art; no substitute scenery permitted.",
            "Gates and warned rear reinforcements are now approved by Level Design; runtime must use revised encounter_contract, not these nearest-clear homes.",
            "Reserve >=640px clear arena lanes, forward preferred, >=220px visible spawn separation and >=1.25s harmless warning. Reuse staged homes; nearest-clear homes are audit output only.",
            "120/180px grounded props require staircase-aware enemy jumps, not vertical snapping or walking through them. Test approaches from both sides and every gap."
        ],
        "unchanged": "Prototype 26 remains the runnable/exported game until the complete integration is validated."
    }


if __name__ == "__main__":
    result = prepare(json.loads(SOURCE.read_text()))
    OUTPUT.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Prepared {len(result['zones'])} zones and {result['enemy_total']} clear floor homes: {OUTPUT.name}")
