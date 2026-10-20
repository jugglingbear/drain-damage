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

    def test_compound_phase_budgets_are_validated(self) -> None:
        builder = load_builder()
        original_read = builder.read
        for field, value in [("rat_phase_hp", 0), ("alligator_phase_hp", -1),
                             ("rat_phase_hp", 901), ("threshold_hp", 539)]:
            with self.subTest(field=field, value=value):
                def invalid_budget(path: str) -> dict[str, Any]:
                    data = copy.deepcopy(original_read(path))
                    if path == "bestiary/cockroach-swarm/monster.json":
                        data["health"][field] = value
                    return data

                with patch.object(builder, "read", side_effect=invalid_budget):
                    with self.assertRaises(ValueError):
                        builder.build()

    def test_bundle_matches_canonical_sources(self) -> None:
        builder = load_builder()
        self.assertEqual(builder.build(), json.loads((ROOT / "data/combat.json").read_text()))

    def test_unregistered_creature_profile_is_rejected(self) -> None:
        builder = load_builder()
        original_read = builder.read

        def missing_entry(path: str) -> dict[str, Any]:
            data = original_read(path)
            if path == "assets/bestiary/catalog.json":
                data["creatures"].pop()
            return data

        with (patch.object(builder, "read", missing_entry),
              self.assertRaisesRegex(ValueError, "every canonical profile")):
            builder.build()

    def test_every_creature_has_both_verified_audio_events(self) -> None:
        builder = load_builder()
        for entry in builder.read("assets/bestiary/catalog.json")["creatures"]:
            profile = builder.read(entry["metadata"])
            self.assertEqual(builder.validate_creature_audio(profile, entry["id"]), profile["audio"])

    def test_missing_or_unbounded_creature_audio_is_rejected(self) -> None:
        builder = load_builder()
        source = builder.read("bestiary/flushfiend/monster.json")
        for event in ("hit", "death"):
            for field, value in [("variants", []), ("loop", True), ("max_voices", 99),
                                 ("max_voices", True), ("cooldown_seconds", -1)]:
                with self.subTest(event=event, field=field):
                    profile = copy.deepcopy(source)
                    profile["audio"][event][field] = value
                    with self.assertRaises(ValueError):
                        builder.validate_creature_audio(profile, "toilet")
            profile = copy.deepcopy(source)
            del profile["audio"][event]
            with self.assertRaises(ValueError):
                builder.validate_creature_audio(profile, "toilet")

    def test_creature_audio_paths_hashes_and_gain_are_validated(self) -> None:
        builder = load_builder()
        source = builder.read("bestiary/clogfather/monster.json")
        for field, value in [("path", "../outside.wav"), ("path", "assets/audio/missing.wav"),
                             ("sha256", "wrong"), ("gain_db", 1), ("gain_db", True),
                             ("gain_db", float("nan"))]:
            with self.subTest(field=field, value=value):
                profile = copy.deepcopy(source)
                profile["audio"]["death"]["variants"][0][field] = value
                with self.assertRaises(ValueError):
                    builder.validate_creature_audio(profile, "clogfather")

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

    def test_disabled_compound_boss_frame_is_rejected(self) -> None:
        builder = load_builder()
        original_read = builder.read

        def invalid_animation(path: str) -> dict[str, Any]:
            data = original_read(path)
            if path == "assets/bestiary/cockroach-swarm/runtime-manifest-v1.json":
                data["animations"]["rat_idle"]["frames"] = [0]
            return data

        with patch.object(builder, "read", invalid_animation), self.assertRaises(ValueError):
            builder.validate_compound_boss()

    def test_missing_rooted_boss_attack_art_is_rejected(self) -> None:
        builder = load_builder()
        original_read = builder.read
        for key in ("acid_warning", "acid_drop", "sludge_projectile_a", "collapse_5"):
            with self.subTest(key=key):
                def missing_frame(path: str) -> dict[str, Any]:
                    data = original_read(path)
                    if path == "assets/bestiary/the-clogfather/runtime-manifest-v2.json":
                        data["frames"].pop(key)
                    return data

                with patch.object(builder, "read", missing_frame), self.assertRaises(ValueError):
                    builder.validate_rooted_boss()

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
