"""Validate Make selector forwarding without opening a game window."""

from __future__ import annotations

import importlib.util
import plistlib
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("run_game", ROOT / "tools/run_game.py")
assert SPEC is not None and SPEC.loader is not None
launch = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(launch)


class PlaytestLaunchTests(unittest.TestCase):
    """Keep launch selection explicit, registered and safely forwarded as argument arrays."""

    def test_ordinary_launch_is_unchanged(self) -> None:
        self.assertEqual(launch.launch_arguments({}), [])
        self.assertEqual(launch.command({"GODOT": "/path with spaces/Godot"}),
                         ["/path with spaces/Godot", "--path", str(ROOT)])

    def test_target_defaults_and_overrides(self) -> None:
        self.assertEqual(launch.launch_arguments({"LEVEL": "1"}),
                         ["--level=1", "--hero=tony", "--difficulty=normal", "--seed=42"])
        self.assertEqual(launch.launch_arguments({"MINIBOSS": "skitterling", "HERO": "sean",
                                                 "DIFFICULTY": "hard", "SEED": "913"}),
                         ["--miniboss=skitterling", "--hero=sean", "--difficulty=hard", "--seed=913"])

    def test_distinct_flush_and_landing_entries(self) -> None:
        for target in ("2", "2-landing"):
            self.assertEqual(launch.launch_arguments({"LEVEL": target, "HERO": "sean", "DIFFICULTY": "hard"}),
                             [f"--level={target}", "--hero=sean", "--difficulty=hard", "--seed=42"])

    def test_invalid_unimplemented_and_conflicting_selectors(self) -> None:
        for values in [{"LEVEL": "3"}, {"BOSS": "clogfather"}, {"MINIBOSS": "unknown"},
                       {"LEVEL": "1", "MINIBOSS": "skitterling"}, {"HERO": "sean"},
                       {"LEVEL": "1", "HERO": "someone"}, {"LEVEL": "1", "DIFFICULTY": "extreme"},
                       {"LEVEL": "1", "SEED": "-1"}, {"LEVEL": "1", "SEED": "2147483648"},
                       {"LEVEL": "1; echo unwanted"}, {"LEVEL": "1", "SEED": "12.5"}]:
            with self.subTest(values=values), self.assertRaises(ValueError):
                launch.launch_arguments(values)
        with self.assertRaises(ValueError):
            launch.command({}, check=True)

    def test_packaged_path_and_headless_arguments(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "Example Game.app"
            (app / "Contents").mkdir(parents=True)
            (app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": "Drain Damage"}))
            argv = launch.command({"APP": str(app), "MINIBOSS": "skitterling"}, preview=True, check=True)
            self.assertEqual(argv[0], str(app.resolve() / "Contents/MacOS/Drain Damage"))
            self.assertIn("--headless", argv)
            self.assertIn("--verify-playtest-launch", argv)
            self.assertIn("--agent-test", argv)
            self.assertNotIn("--path", argv)
            self.assertEqual(argv.count("--"), 1)


if __name__ == "__main__":
    unittest.main()
