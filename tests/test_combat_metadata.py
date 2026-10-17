"""Canonical metadata validation and generated bundle freshness checks."""

import copy
import importlib.util
import json
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load_builder() -> ModuleType:
    """Load the dependency-free build validator without modifying import paths."""
    spec = importlib.util.spec_from_file_location("combat_builder", ROOT / "tools/build_combat_data.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class CombatMetadataTests(unittest.TestCase):
    """Invalid source metadata fails before export rather than becoming silent defaults."""

    def test_bundle_matches_canonical_sources(self) -> None:
        builder = load_builder()
        self.assertEqual(builder.build(), json.loads((ROOT / "data/combat.json").read_text()))

    def test_trial_overrides_preserve_campaign_values(self) -> None:
        bundle = load_builder().build()
        self.assertEqual(bundle["weapons"]["pressure-gun"]["damage"], 6)
        self.assertEqual(bundle["weapons"]["heavy-plunger-launcher"]["attack_interval_seconds"], 1.0)
        trial = bundle["opening_trial"]["balance"]["weapons"]
        self.assertEqual(trial["pressure-gun"]["damage"], 12)
        self.assertEqual(trial["heavy-plunger-launcher"]["attack_interval_seconds"], 0.24)

    def test_invalid_art_regions_are_rejected(self) -> None:
        builder = load_builder()
        asset = builder.read("assets/world/wastewater-cutaway/manifest-v1.json")["assets"][0]
        for crop in [[0, 0, 99999, 10], [-1, 0, 10, 10], [0, 0, 0, 10], [True, 0, 10, 10]]:
            with self.subTest(crop=crop), self.assertRaises(ValueError):
                builder.validate_art_regions({**asset, "source_rect": crop})

    def test_invalid_swarm_data_is_rejected(self) -> None:
        builder = load_builder()
        original_read = builder.read
        for field, value in [("speed_pixels_per_second", -1), ("heading_update_seconds", 0),
                             ("contact_radius_pixels", True)]:
            with self.subTest(field=field):
                def changed_read(path: str) -> dict[str, Any]:
                    data = original_read(path)
                    if path == "bestiary/sewer-flies/monster.json":
                        data["movement"][field] = value
                    return data

                with patch.object(builder, "read", changed_read), self.assertRaises(ValueError):
                    builder.build()

    def test_invalid_weapon_fields_are_rejected(self) -> None:
        builder = load_builder()
        original = builder.read("weapons/pressure-gun/weapon.json")
        for field, value in [("damage", True), ("damage", "6"), ("damage", -1),
                             ("attack_interval_seconds", 0), ("owner", "sean"),
                             ("exclusive", False), ("id", "missing"), ("projectile", None)]:
            with self.subTest(field=field, value=value):
                weapon = copy.deepcopy(original)
                weapon[field] = value
                with self.assertRaises(ValueError):
                    builder.validate_weapon(weapon, "pressure-gun", "tony")
        weapon = copy.deepcopy(original)
        del weapon["damage"]
        with self.assertRaises(ValueError):
            builder.validate_weapon(weapon, "pressure-gun", "tony")

    def test_invalid_aim_permissions_are_rejected(self) -> None:
        builder = load_builder()
        for permissions in [[], ["sideways"], None]:
            with self.subTest(permissions=permissions):
                weapon = builder.read("weapons/pressure-gun/weapon.json")
                weapon["aiming"]["airborne_directions"] = permissions
                with self.assertRaises(ValueError):
                    builder.validate_weapon(weapon, "pressure-gun", "tony")

    def test_invalid_projectile_ranges_are_rejected(self) -> None:
        builder = load_builder()
        for field in ["speed_pixels_per_second", "max_travel_distance_pixels"]:
            weapon = builder.read("weapons/pressure-gun/weapon.json")
            weapon["projectile"][field] = 0
            with self.assertRaises(ValueError):
                builder.validate_weapon(weapon, "pressure-gun", "tony")


if __name__ == "__main__":
    unittest.main()
