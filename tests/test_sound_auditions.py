"""Regression checks for permanent audio identities and audition validation."""

import copy
import importlib.util
import json
import unittest
from html.parser import HTMLParser
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "sound_auditions", Path(__file__).resolve().parents[1] / "tools/build_sound_auditions.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class SoundAuditionsTests(unittest.TestCase):
    """Protect identities when the catalog changes."""

    def setUp(self) -> None:
        self.slots = {"hero/jump": dict(section=MODULE.SECTIONS[0], name="Jump", paths=[], source="test")}
        self.registry = {"sounds": []}
        MODULE.refresh(self.registry, self.slots)

    def test_replacement_insertion_and_retirement_preserve_identity(self) -> None:
        original = copy.deepcopy(self.registry["sounds"][0])
        self.slots["hero/jump"]["name"] = "New jump"
        self.slots["hero/hurt"] = dict(self.slots["hero/jump"])
        MODULE.refresh(self.registry, self.slots)
        self.assertEqual(self.registry["sounds"][0]["id"], original["id"])
        self.assertEqual(self.registry["sounds"][0]["uuid"], original["uuid"])
        del self.slots["hero/jump"]
        MODULE.refresh(self.registry, self.slots)
        self.assertEqual(self.registry["sounds"][0]["status"], "retired")
        MODULE.validate(self.registry, self.slots)

    def test_duplicate_ids_and_stale_mapping_rejected(self) -> None:
        self.registry["sounds"].append(copy.deepcopy(self.registry["sounds"][0]))
        with self.assertRaises(ValueError):
            MODULE.validate(self.registry, self.slots)
        self.registry["sounds"].pop()
        self.registry["sounds"][0]["name"] = "Stale"
        with self.assertRaises(ValueError):
            MODULE.validate(self.registry, self.slots)

    def test_missing_alternative_and_invalid_suffix_rejected(self) -> None:
        record = self.registry["sounds"][0]
        for identity in (record["id"] + ".1", record["id"] + ".0", "another.1"):
            record["alternatives"] = [dict(id=identity, path="audio/missing.wav")]
            with self.assertRaises(ValueError):
                MODULE.validate(self.registry, self.slots)

    def test_live_catalog_and_tone_preview(self) -> None:
        registry = json.loads(MODULE.REGISTRY.read_text())
        MODULE.validate(registry, MODULE.discover())
        self.assertTrue(MODULE.tone_bytes(360, 0.08).startswith(b"RIFF"))

    def test_groups_start_collapsed_and_preserve_weapon_candidates(self) -> None:
        class PageAudit(HTMLParser):
            def __init__(self) -> None:
                super().__init__()
                self.groups = 0
                self.slots = 0
                self.players = 0
                self.expanded = 0

            def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
                values = dict(attrs)
                if tag == "details":
                    self.groups += values.get("class") == "sound-group"
                    self.slots += values.get("class") == "sound-slot"
                    self.expanded += "open" in values
                self.players += tag == "audio"

        registry = json.loads(MODULE.REGISTRY.read_text())
        page = MODULE.render(registry)
        audit = PageAudit()
        audit.feed(page)
        self.assertEqual(audit.expanded, 0)
        self.assertEqual(audit.slots, len(MODULE.discover()))
        self.assertGreater(audit.groups, 5)
        self.assertIn("Gnatastrophe", page)
        weapons = [r for r in registry["sounds"] if r["key"].startswith("weapon/")]
        self.assertEqual(sum(len(r["alternatives"]) for r in weapons), 17)
        self.assertGreaterEqual(audit.players, 124)


if __name__ == "__main__":
    unittest.main()
