"""Offline dependency bootstrap safety and platform regressions."""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
import stat
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import ModuleType
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load_bootstrap() -> ModuleType:
    """Load the installer without invoking setup."""
    spec = importlib.util.spec_from_file_location("bootstrap", ROOT / "tools/bootstrap.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BootstrapTests(unittest.TestCase):
    """Never use network access, global package managers or the real Git checkout."""

    def setUp(self) -> None:
        self.module = load_bootstrap()
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def test_platform_matrix_rejects_unsupported_hosts(self) -> None:
        for system, arch, expected in [
            ("Darwin", "arm64", ("macos", "universal")),
            ("Darwin", "x86_64", ("macos", "universal")),
            ("Linux", "aarch64", ("linux", "arm64")),
            ("Linux", "x86_64", ("linux", "x86_64")),
        ]:
            self.assertEqual(self.module.host_target(system, arch), expected)
        for system, arch in [("Windows", "AMD64"), ("Linux", "i686"), ("Darwin", "ppc")]:
            with self.assertRaises(ValueError):
                self.module.host_target(system, arch)

    def test_modified_lfs_asset_is_not_a_pointer(self) -> None:
        (self.root / "modified.pdf").write_bytes(b"%PDF-1.7 local user revision")
        (self.root / "pointer.png").write_bytes(b"version https://git-lfs.github.com/spec/v1\noid sha256:abc\n")
        listing = "abc - modified.pdf\nabc - pointer.png\nabc * ready.png"
        with patch.object(self.module, "ROOT", self.root), patch.object(self.module, "run", return_value=listing):
            self.assertEqual(self.module.missing_lfs(), ["pointer.png"])

    def test_deleted_lfs_asset_requires_explicit_restore(self) -> None:
        with patch.object(self.module, "ROOT", self.root), patch.object(
            self.module, "run", return_value="abc - absent.wav"
        ), self.assertRaisesRegex(ValueError, "possible user deletion"):
            self.module.missing_lfs()
        self.assertFalse((self.root / "absent.wav").exists())

    def test_archive_paths_and_links_cannot_escape(self) -> None:
        for name in ["../escape", "/absolute", "back\\slash", "symlink"]:
            archive = self.root / "bad.zip"
            with zipfile.ZipFile(archive, "w") as bundle:
                entry = zipfile.ZipInfo(name)
                if name == "symlink":
                    entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                bundle.writestr(entry, "outside")
            with self.assertRaises(ValueError):
                self.module.safe_extract(archive, self.root / "unpacked")
            self.assertFalse((self.root / "unpacked").exists())

    def test_bad_download_is_rejected_and_temporary_removed(self) -> None:
        lock = {"assets": {"editor.zip": {"url": "https://example.invalid/editor", "sha256": "0" * 64}}}
        with patch.object(self.module, "LOCK", lock), patch.object(
            self.module.urllib.request, "urlopen", return_value=io.BytesIO(b"corrupt")
        ), self.assertRaisesRegex(ValueError, "SHA-256"):
            self.module.download("editor.zip", self.root)
        self.assertEqual(list((self.root / "downloads").iterdir()), [])

    def test_verified_cache_avoids_network(self) -> None:
        (self.root / "downloads").mkdir()
        target = self.root / "downloads/editor.zip"
        target.write_bytes(b"verified")
        lock = {"assets": {"editor.zip": {"sha256": hashlib.sha256(b"verified").hexdigest()}}}
        with patch.object(self.module, "LOCK", lock), patch.object(self.module.urllib.request, "urlopen") as fetch:
            self.assertEqual(self.module.download("editor.zip", self.root), target)
            fetch.assert_not_called()

    def test_conflicting_editor_is_preserved(self) -> None:
        target = self.root / "godot"
        target.write_bytes(b"user tool")
        with patch.object(self.module, "download") as fetch, self.assertRaises(ValueError):
            self.module.install_editor(self.root, "linux", "x86_64")
        fetch.assert_not_called()
        self.assertEqual(target.read_bytes(), b"user tool")

    def test_conflicting_template_is_preserved(self) -> None:
        target = self.root / "macos.zip"
        target.write_bytes(b"custom template")
        with patch.object(self.module, "download") as fetch, self.assertRaises(ValueError):
            self.module.install_templates(self.root, {"macos.zip": target})
        fetch.assert_not_called()
        self.assertEqual(target.read_bytes(), b"custom template")

    def test_linux_editor_staged_then_installed(self) -> None:
        archive = self.root / "editor.zip"
        with zipfile.ZipFile(archive, "w") as bundle:
            entry = zipfile.ZipInfo("Godot_v4.7.2-stable_linux.x86_64")
            entry.external_attr = (stat.S_IFREG | 0o755) << 16
            bundle.writestr(entry, "verified editor")
        with patch.object(self.module, "download", return_value=archive), patch.object(
            self.module, "editor_ok", return_value=True
        ):
            self.module.install_editor(self.root, "linux", "x86_64")
        self.assertEqual((self.root / "godot").read_text(), "verified editor")
        self.assertTrue((self.root / "godot").stat().st_mode & stat.S_IXUSR)

    def test_configured_check_plan_and_install_are_read_only(self) -> None:
        (self.root / ".git").mkdir()
        (self.root / ".tools").mkdir()
        template = self.root / ".tools/macos.zip"
        template.write_bytes(b"template")
        lock = {"template_members": {"macos.zip": hashlib.sha256(b"template").hexdigest()}}
        before = template.stat().st_mtime_ns
        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.object(self.module, "ROOT", self.root))
            stack.enter_context(patch.object(self.module, "LOCK", lock))
            stack.enter_context(patch.object(self.module.platform, "system", return_value="Darwin"))
            stack.enter_context(patch.object(self.module.platform, "machine", return_value="arm64"))
            stack.enter_context(patch.object(self.module.shutil, "which", return_value="/mock/tool"))
            stack.enter_context(patch.object(self.module, "editor_ok", return_value=True))
            stack.enter_context(patch.object(self.module, "missing_lfs", return_value=[]))
            calls = stack.enter_context(patch.object(self.module, "run", return_value="/mock/CLT"))
            fetch = stack.enter_context(patch.object(self.module, "download"))
            stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
            for check, plan in [(True, False), (False, True), (False, False)]:
                self.assertEqual(self.module.bootstrap(check, plan), 0)
            fetch.assert_not_called()
            self.assertTrue(all(call.args[0] == ["xcode-select", "-p"] for call in calls.call_args_list))
        self.assertEqual(template.stat().st_mtime_ns, before)
        self.assertFalse((self.root / ".tools/.gdignore").exists())

    def test_shell_missing_packages_never_report_ready(self) -> None:
        binary = self.root / "bin"
        binary.mkdir()
        (binary / "dirname").symlink_to("/usr/bin/dirname")
        uname = binary / "uname"
        uname.write_text('#!/bin/sh\ncase "$1" in -s) echo Linux;; -m) echo x86_64;; esac\n')
        uname.chmod(0o755)
        manager = binary / "apt-get"
        manager.write_text('#!/bin/sh\nexit 99\n')
        manager.chmod(0o755)
        for option, code in [("--check", 1), ("--dry-run", 0), ("", 1)]:
            args = ["/bin/bash", str(ROOT / "tools/install.sh")]
            if option:
                args.append(option)
            result = subprocess.run(args, env={**os.environ, "PATH": str(binary)}, capture_output=True, text=True)
            self.assertEqual(result.returncode, code, result.stderr)
            self.assertIn("Missing prerequisites", result.stdout)
            self.assertNotIn("Already configured", result.stdout)

    def test_lock_uses_official_release_urls_and_complete_digests(self) -> None:
        lock = json.loads((ROOT / "tools/godot-lock.json").read_text())
        for asset in lock["assets"].values():
            self.assertTrue(asset["url"].startswith(
                "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/"
            ))
            self.assertEqual(len(bytes.fromhex(asset["sha256"])), 32)


if __name__ == "__main__":
    unittest.main()
