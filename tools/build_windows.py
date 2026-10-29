#!/usr/bin/env python3
"""Cross-export and package Windows without claiming Windows runtime validation."""

from __future__ import annotations

import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from tools.bootstrap import ROOT, VERSION, editor_ok, install_templates, missing_lfs, run, sha256
from tools.sync_project_version import sync_version


def validate_pe(path: Path) -> None:
    """Reject missing, truncated, or non-x86_64 executables before packaging."""
    with path.open('rb') as source:
        header = source.read(64)
        if len(header) != 64 or header[:2] != b'MZ':
            raise ValueError(f'Invalid Windows executable: {path}')
        source.seek(struct.unpack_from('<I', header, 60)[0])
        pe = source.read(6)
    if pe != b'PE\0\0\x64\x86':
        raise ValueError(f'Expected Windows x86_64 PE executable: {path}')


def build() -> Path:
    """Publish a timestamped local ZIP only after export and integrity checks succeed."""
    configured = os.environ.get('GODOT', '.tools/Godot.app/Contents/MacOS/Godot')
    godot = Path(shutil.which(configured) or configured).resolve()
    if not editor_ok(godot):
        raise ValueError(f'Use pinned Godot {VERSION}: {godot}')
    if missing_lfs():
        raise ValueError('Unresolved Git LFS assets; run make install first.')
    version = sync_version()
    tools = ROOT / '.tools'
    template_dir = tools / 'export_templates' / (VERSION + '.stable')
    names = [f'windows_{mode}_x86_64{suffix}.exe'
             for mode in ('debug', 'release') for suffix in ('', '_console')]
    install_templates(tools, {name: template_dir / name for name in names})
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S-%fZ')
    name = f'Drain-Damage-{version}-windows-x86_64-{stamp}'
    builds = ROOT / 'builds'
    builds.mkdir(exist_ok=True)
    # An isolated staging directory prevents stale exports from entering a new package.
    with tempfile.TemporaryDirectory(prefix='windows-stage-', dir=builds) as temporary:
        staging = Path(temporary)
        folder = staging / name
        folder.mkdir()
        for args in (['--editor', '--import'], ['--export-release', 'Windows', str(folder / 'Drain Damage.exe')]):
            result = subprocess.run([str(godot), '--headless', '--path', str(ROOT), *args],
                                    cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            (staging / 'export.log').write_text(result.stdout)
            if result.returncode or 'ERROR:' in result.stdout or 'SCRIPT ERROR:' in result.stdout:
                failure = builds / f'{name}-failed.log'
                failure.write_text(result.stdout)
                raise ValueError(f'Godot export/import failed; see {failure}')
        validate_pe(folder / 'Drain Damage.exe')
        pck = folder / 'Drain Damage.pck'
        with pck.open('rb') as source:
            if source.read(4) != b'GDPC':
                raise ValueError('Missing/invalid external Godot resource pack')
        for executable in folder.glob('*.exe'):
            validate_pe(executable)
        # This exercises exported resources on the build host, not the Windows executable.
        shutdown_warnings: list[str] = []
        for target in ('1', '2', '2-landing', '2-12', '2-13'):
            result = subprocess.run(
                [str(godot), '--headless', '--main-pack', str(pck), '--', f'--level={target}',
                 '--hero=sean', '--difficulty=hard', '--seed=42', '--verify-playtest-launch'],
                cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120,
            )
            errors = [line for line in result.stdout.splitlines() if 'ERROR:' in line]
            known_shutdown = [line for line in errors
                              if re.fullmatch(r'ERROR: [0-9]+ resources still in use at exit.*', line)]
            shutdown_warnings.extend(f'{target}: {line}' for line in known_shutdown)
            if result.returncode or set(errors) - set(known_shutdown) or 'PASS: playtest launch' not in result.stdout:
                failure = builds / f'{name}-smoke-failed.log'
                failure.write_text(result.stdout)
                raise ValueError(f'Host resource-pack check failed: {target}; see {failure}')
            print(f'PASS: host resource-pack initialization {target}', flush=True)
        (folder / 'GODOT_COPYRIGHT.txt').write_bytes((ROOT / 'licenses/GODOT_COPYRIGHT.txt').read_bytes())
        (folder / 'README.txt').write_text(
            f'Drain Damage {version} — Windows x86_64\n\n'
            'Extract the entire ZIP, then run Drain Damage.exe. Keep the .pck beside the .exe.\n'
            'This build is unsigned. Native Windows gameplay, graphics, audio and controllers are not yet verified.\n'
            'Run Test-Windows.ps1 in PowerShell for headless initialization checks and logs.\n'
            'No Godot editor, Python, Git, or repository clone is required to play.\n'
        )
        (folder / 'Test-Windows.ps1').write_bytes((ROOT / 'tools/test_windows.ps1').read_bytes())
        manifest = {
            'version': version, 'godot': VERSION, 'platform': 'windows-x86_64',
            'source_commit': run(['git', 'rev-parse', 'HEAD']),
            'working_tree_dirty': bool(run(['git', 'status', '--porcelain'])),
            'created_at_utc': stamp, 'signed': False, 'windows_runtime_tested': False,
            'host_resource_pack_checks': ['1', '2', '2-landing', '2-12', '2-13'],
            'known_shutdown_warnings': shutdown_warnings,
            'files': {file.name: sha256(file) for file in sorted(folder.iterdir()) if file.is_file()},
        }
        (folder / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        archive = staging / f'{name}.zip'
        with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
            for file in sorted(folder.iterdir()):
                bundle.write(file, f'{name}/{file.name}')
        with zipfile.ZipFile(archive) as bundle:
            if bundle.testzip() is not None:
                raise ValueError('ZIP integrity check failed')
        destination = builds / name
        folder.rename(destination)
        output = builds / archive.name
        archive.rename(output)
        (builds / f'{name}.sha256').write_text(f'{sha256(output)}  {output.name}\n')
    print(f'Windows package: {output}\nNative Windows runtime testing: pending')
    return output


if __name__ == '__main__':
    build()
