"""Validate first-call preparation independently from runtime integration."""

import copy
import json
import unittest

from tools.prepare_first_call import SOURCE, clear_spawn, prepare


class FirstCallPlanTests(unittest.TestCase):
    """Exercise authored totals, solid clearance and invalid level rejection."""

    def test_all_homes_clear_solids_and_checkpoints(self) -> None:
        source = json.loads(SOURCE.read_text())
        plan = prepare(source)
        terrain = [rect for zone in source["zones"] for rect in zone["terrain"]]
        self.assertEqual(plan["enemy_total"], 30)
        for zone in plan["zones"]:
            for home in zone["clear_floor_homes"]:
                self.assertTrue(clear_spawn(home, terrain, plan["checkpoints"], 160))
                self.assertGreaterEqual(home, zone["bounds"][0])
                self.assertLess(home + 38, zone["bounds"][1])
        self.assertEqual(plan, prepare(source), "Relocation must be deterministic")

    def test_invalid_totals_and_floating_grounded_props_rejected(self) -> None:
        source = json.loads(SOURCE.read_text())
        changed = copy.deepcopy(source)
        changed["encounter_contract"]["total_authored_enemies"] += 1
        with self.assertRaises(ValueError):
            prepare(changed)
        changed = copy.deepcopy(source)
        changed["zones"][0]["terrain"][0][3] -= 1
        with self.assertRaises(ValueError):
            prepare(changed)
