"""Check Windows packaging rejects unsuitable binaries and retains export parity."""

import configparser
import json
import struct
import tempfile
import unittest
from pathlib import Path

from tools.build_windows import validate_pe

ROOT = Path(__file__).resolve().parents[1]


class WindowsExportTests(unittest.TestCase):
    """Exercise binary validation and the shared runtime export contract."""

    def test_release_smoke_targets_are_current(self) -> None:
        registry = json.loads((ROOT / 'data/playtest-targets.json').read_text())
        levels = {item['id'] for item in registry['targets'] if item['kind'] == 'level'}
        targets = ('1', '2', '2.1', '2-01', '2-12', '2-13')
        self.assertTrue(set(targets).issubset(levels))
        for script in ('tools/build_windows.py', 'tools/test_windows.ps1'):
            content = (ROOT / script).read_text()
            self.assertNotIn("'2-landing'", content)
            for target in targets:
                self.assertIn(repr(target), content)

    def test_pe_architecture_and_truncation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'game.exe'
            header = bytearray(64)
            header[:2] = b'MZ'
            struct.pack_into('<I', header, 60, 64)
            for payload in (b'', b'LFS pointer', header, header + b'PE\0\0\x64\xaa'):
                path.write_bytes(payload)
                with self.assertRaises(ValueError):
                    validate_pe(path)
            path.write_bytes(header + b'PE\0\0\x64\x86')
            validate_pe(path)

    def test_platforms_export_identical_runtime_inputs(self) -> None:
        config = configparser.ConfigParser(interpolation=None)
        config.read(ROOT / 'export_presets.cfg')
        for field in ('export_filter', 'include_filter', 'exclude_filter'):
            self.assertEqual(config['preset.0'][field], config['preset.1'][field])
        self.assertEqual(config['preset.1.options']['binary_format/embed_pck'], 'false')
        self.assertEqual(config['preset.1.options']['binary_format/architecture'], '"x86_64"')
