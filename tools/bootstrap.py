#!/usr/bin/env python3
"""Install pinned project-local Godot tools without replacing existing user files."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import shutil
import stat
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / "tools/godot-lock.json").read_text())
VERSION = LOCK["version"]


def host_target(system: str, machine: str) -> tuple[str, str]:
    """Return supported host family and archive architecture, failing before mutation."""
    arch = {"amd64": "x86_64", "x86_64": "x86_64", "aarch64": "arm64", "arm64": "arm64"}.get(machine.lower())
    if system not in {"Darwin", "Linux"}:
        raise ValueError("Native Windows/MSYS is not supported. Use WSL2 Linux and run bash tools/install.sh there.")
    if arch is None:
        raise ValueError(f"Unsupported architecture: {system}/{machine}; supported: x86_64 and arm64.")
    return ("macos", "universal") if system == "Darwin" else ("linux", arch)


def sha256(path: Path) -> str:
    """Hash a file in bounded memory."""
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(arguments: list[str], cwd: Path = ROOT) -> str:
    """Run one explicit command, retaining errors without shell interpolation."""
    result = subprocess.run(arguments, cwd=cwd, text=True, capture_output=True, check=False)
    if result.returncode:
        raise ValueError(f"{' '.join(arguments)} failed: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout.strip()


def download(name: str, tools: Path) -> Path:
    """Reuse only verified archives; download atomically using the committed release digest."""
    spec = LOCK["assets"][name]
    cache = tools / "downloads" / name
    legacy = tools / ("templates.tpz" if name.endswith(".tpz") else "godot.zip")
    for candidate in (cache, legacy):
        if candidate.is_file() and sha256(candidate) == spec["sha256"]:
            return candidate
    if cache.exists():
        raise ValueError(f"Checksum mismatch; preserve and inspect existing archive: {cache}")
    cache.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=cache.parent, delete=False) as output:
            temporary = Path(output.name)
            with urllib.request.urlopen(spec["url"], timeout=60) as response:
                shutil.copyfileobj(response, output)
        if sha256(temporary) != spec["sha256"]:
            raise ValueError(f"Official download failed SHA-256 verification: {name}")
        temporary.replace(cache)
        return cache
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def safe_extract(archive: Path, destination: Path) -> None:
    """Reject escaping paths and links before extracting a verified editor archive."""
    with zipfile.ZipFile(archive) as bundle:
        for member in bundle.infolist():
            path = PurePosixPath(member.filename)
            mode = member.external_attr >> 16
            if path.is_absolute() or ".." in path.parts or "\\" in member.filename or stat.S_ISLNK(mode):
                raise ValueError(f"Unsafe archive member: {member.filename}")
        bundle.extractall(destination)
        for member in bundle.infolist():
            path = destination / member.filename
            if path.is_file():
                path.chmod((member.external_attr >> 16 & 0o777) or 0o644)


def editor_path(tools: Path, family: str) -> Path:
    """Use the existing macOS layout and a local executable on Linux."""
    return tools / ("Godot.app/Contents/MacOS/Godot" if family == "macos" else "godot")


def editor_ok(path: Path) -> bool:
    """Confirm the exact pinned release without opening the game or editor."""
    return path.is_file() and run([str(path), "--version"]).startswith(VERSION + ".stable.")


def template_paths(tools: Path, family: str, arch: str) -> dict[str, Path]:
    """Stage only matching host templates; native exports still require configured presets."""
    if family == "macos":
        return {"macos.zip": tools / "macos.zip"}
    base = tools / "export_templates" / (VERSION + ".stable")
    return {name: base / name for name in (f"linux_debug.{arch}", f"linux_release.{arch}")}


def install_editor(tools: Path, family: str, arch: str) -> None:
    """Install into an empty destination, preserving conflicting or partial tools for inspection."""
    target = tools / ("Godot.app" if family == "macos" else "godot")
    if target.exists():
        raise ValueError(f"Existing tool conflicts with {VERSION}; move it aside explicitly first: {target}")
    archive = download(f"Godot_v{VERSION}-stable_{family}.{arch}.zip", tools)
    with tempfile.TemporaryDirectory(prefix="godot-stage-", dir=tools) as directory:
        staging = Path(directory)
        safe_extract(archive, staging)
        source = staging / ("Godot.app" if family == "macos" else f"Godot_v{VERSION}-stable_linux.{arch}")
        binary = source / "Contents/MacOS/Godot" if family == "macos" else source
        if not editor_ok(binary):
            raise ValueError("Extracted editor does not match the pinned version")
        source.rename(target)


def install_templates(tools: Path, targets: dict[str, Path]) -> None:
    """Verify each template independently and never overwrite a conflicting file."""
    missing = []
    for name, target in targets.items():
        if target.exists():
            if not target.is_file() or sha256(target) != LOCK["template_members"][name]:
                raise ValueError(f"Existing template differs from pinned release; preserve and inspect: {target}")
        else:
            missing.append(name)
    if not missing:
        return
    archive = download(f"Godot_v{VERSION}-stable_export_templates.tpz", tools)
    with zipfile.ZipFile(archive) as bundle:
        if bundle.read("templates/version.txt").decode().strip() != VERSION + ".stable":
            raise ValueError("Export template version mismatch")
        for name in missing:
            content = bundle.read("templates/" + name)
            if hashlib.sha256(content).hexdigest() != LOCK["template_members"][name]:
                raise ValueError(f"Template member checksum mismatch: {name}")
            target = targets[name]
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("xb") as output:
                output.write(content)
            if name.startswith("linux_"):
                target.chmod(0o755)


def missing_lfs() -> list[str]:
    """List unresolved tracked LFS pointers without changing Git configuration or the checkout."""
    listing = run(["git", "lfs", "ls-files"])
    pointers = []
    for line in listing.splitlines():
        parts = line.split(" ", 2)
        if len(parts) != 3 or parts[1] != "-":
            continue
        path = ROOT / parts[2]
        if not path.is_file():
            raise ValueError(f"Tracked LFS asset is absent; preserve possible user deletion: {parts[2]}. "
                             "Restore it explicitly if wanted, then rerun setup.")
        # A modified, real PDF/image can also have '-' in ls-files; inspect only the pointer signature.
        with path.open("rb") as source:
            if source.read(43).startswith(b"version https://git-lfs.github.com/spec/v1\n"):
                pointers.append(parts[2])
    return pointers


def bootstrap(check: bool = False, dry_run: bool = False) -> int:
    """Check or install local tools after the shell entry has handled system prerequisites."""
    family, arch = host_target(platform.system(), platform.machine())
    if sys.version_info < (3, 10):
        raise ValueError("Python 3.10+ is required; install a current Python before rerunning.")
    for name in ("git", "git-lfs", "make"):
        if shutil.which(name) is None:
            raise ValueError(f"Missing {name}; run bash tools/install.sh --system for supported package managers.")
    if not (ROOT / ".git").exists():
        raise ValueError("Use a Git clone with Git LFS; source ZIP downloads cannot hydrate repository assets.")
    if family == "macos":
        run(["xcode-select", "-p"])
        for name in ("codesign", "ditto"):
            if shutil.which(name) is None:
                raise ValueError(f"Missing macOS build prerequisite: {name}")
    tools = ROOT / ".tools"
    editor = editor_path(tools, family)
    targets = template_paths(tools, family, arch)
    editor_ready = editor_ok(editor)
    templates_ready = all(path.is_file() and sha256(path) == LOCK["template_members"][name]
                          for name, path in targets.items())
    pointers = missing_lfs()
    print(f"Host: {family}/{arch}; pinned Godot {VERSION}; native exports: macOS only")
    print(f"Editor: {'ready' if editor_ready else 'missing/conflicting'}; "
          f"templates: {'ready' if templates_ready else 'missing/conflicting'}; LFS pointers: {len(pointers)}")
    if check or dry_run:
        if dry_run and not (editor_ready and templates_ready and not pointers):
            print("Plan: verify/download missing pinned archives, stage local tools, hydrate unresolved LFS assets.")
        return 0 if dry_run or (editor_ready and templates_ready and not pointers) else 1
    if editor_ready and templates_ready and not pointers:
        print("Already configured; no files, packages or Git settings changed.")
        return 0
    tools.mkdir(exist_ok=True)
    (tools / ".gdignore").touch(exist_ok=True)
    if not editor_ready:
        install_editor(tools, family, arch)
    install_templates(tools, targets)
    if pointers:
        # Git LFS checkout preserves modified working-tree files; never force or reset them.
        run(["git", "lfs", "install", "--local"])
        run(["git", "lfs", "pull"])
        remaining = missing_lfs()
        if remaining:
            raise ValueError(f"Unresolved LFS pointers remain ({len(remaining)}); inspect git lfs status.")
    print("Local dependencies ready. No game was launched. Run make check or make build on macOS.")
    return 0


def main() -> int:
    """Expose read-only check and planning modes."""
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Read-only readiness check; never download or mutate")
    mode.add_argument("--dry-run", action="store_true", help="Describe required local setup without mutations")
    args = parser.parse_args()
    try:
        return bootstrap(args.check, args.dry_run)
    except (ValueError, OSError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        print(f"Setup failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
