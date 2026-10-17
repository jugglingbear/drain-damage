"""Ensure packaging cannot silently use an older version than the game UI."""

from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase
from unittest.mock import patch

from tools import sync_project_version


class ProjectVersionTests(TestCase):
    """Exercise synchronization and drift detection against isolated project files."""

    def test_sync_and_detect_drift(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'project.godot').write_text('[application]\nconfig/version="1.2.3"\n')
            preset = root / 'export_presets.cfg'
            preset.write_text('application/version="0.1.0"\napplication/short_version="0.1.0"\n')
            with patch.object(sync_project_version, 'ROOT', root):
                with self.assertRaises(ValueError):
                    sync_project_version.sync_version(check=True)
                self.assertEqual(sync_project_version.sync_version(), '1.2.3')
                self.assertEqual(sync_project_version.sync_version(check=True), '1.2.3')
            self.assertEqual(preset.read_text().count('"1.2.3"'), 2)

    def test_invalid_version_leaves_export_unchanged(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'project.godot').write_text('config/version="latest"\n')
            preset = root / 'export_presets.cfg'
            preset.write_text('unchanged\n')
            with patch.object(sync_project_version, 'ROOT', root):
                with self.assertRaises(ValueError):
                    sync_project_version.sync_version()
            self.assertEqual(preset.read_text(), 'unchanged\n')
