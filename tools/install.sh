#!/usr/bin/env bash
# Direct setup entry for a fresh clone, including hosts without make or Python.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
system_packages=false
mode=""
for option in "$@"; do
    case "$option" in
        --system) system_packages=true ;;
        --check|--dry-run)
            if [[ -n "$mode" ]]; then printf 'Choose only one of --check and --dry-run.\n' >&2; exit 2; fi
            mode="$option"
            ;;
        --help)
            printf 'Usage: bash tools/install.sh [--system] [--check|--dry-run]\n'
            printf 'Default installs verified local tools; --system permits missing system packages.\n'
            printf 'Check/dry-run never install packages, download files or change Git settings.\n'
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$option" >&2; exit 2 ;;
    esac
done

host_os="$(uname -s)"
host_arch="$(uname -m)"
case "$host_os/$host_arch" in
    Darwin/arm64|Darwin/x86_64|Linux/x86_64|Linux/aarch64|Linux/arm64) ;;
    *)
        printf 'Unsupported host: %s/%s. macOS/Linux x86_64 and arm64 are supported.\n' "$host_os" "$host_arch" >&2
        printf 'On Windows use WSL2 Linux, then rerun bash tools/install.sh inside WSL.\n' >&2
        exit 1
        ;;
esac
if [[ "$host_os" == Darwin ]] && ! xcode-select -p >/dev/null 2>&1; then
    printf 'Apple Command Line Tools are required. Run xcode-select --install, finish installation, then rerun.\n' >&2
    exit 1
fi

missing=()
for dependency in python3 make git git-lfs; do
    if ! command -v "$dependency" >/dev/null 2>&1; then missing+=("$dependency"); fi
done
if command -v python3 >/dev/null 2>&1 && ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))'; then
    missing+=("Python>=3.10")
fi
if (( ${#missing[@]} )); then
    printf 'Missing prerequisites: %s\n' "${missing[*]}"
    package_command=()
    if [[ "$host_os" == Darwin ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            printf 'Install Homebrew from https://brew.sh, then rerun bash tools/install.sh --system.\n' >&2
            exit 1
        fi
        package_command=(brew install python make git git-lfs)
    elif command -v apt-get >/dev/null 2>&1; then
        package_command=(apt-get install --no-install-recommends python3 make git git-lfs ca-certificates)
    elif command -v dnf >/dev/null 2>&1; then
        package_command=(dnf install python3 make git git-lfs ca-certificates)
    elif command -v pacman >/dev/null 2>&1; then
        package_command=(pacman -S --needed python make git git-lfs ca-certificates)
    else
        printf 'No supported package manager. Install Python3.10+, make, git and git-lfs, then rerun.\n' >&2
        exit 1
    fi
    printf 'System command:'
    printf ' %q' "${package_command[@]}"
    printf '\n'
    if [[ "$mode" == --dry-run ]]; then exit 0; fi
    if [[ "$mode" == --check ]] || [[ "$system_packages" != true ]]; then
        printf 'Setup is incomplete. Rerun: bash tools/install.sh --system\n' >&2
        exit 1
    fi
    privilege=()
    if [[ "$host_os" != Darwin ]] && (( EUID != 0 )); then privilege=(sudo); fi
    if [[ "${package_command[0]}" == apt-get ]]; then "${privilege[@]}" apt-get update; fi
    # Package managers keep their normal confirmation/authentication; never auto-accept or upgrade the OS.
    "${privilege[@]}" "${package_command[@]}"
    hash -r
    for dependency in python3 make git git-lfs; do
        command -v "$dependency" >/dev/null 2>&1 || {
            printf 'Still missing %s; refresh PATH and rerun setup.\n' "$dependency" >&2; exit 1;
        }
    done
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))' || {
        printf 'Python 3.10+ is still required; select a newer Python on PATH and rerun setup.\n' >&2
        exit 1
    }
fi
arguments=()
if [[ -n "$mode" ]]; then arguments+=("$mode"); fi
exec python3 "$repo_root/tools/bootstrap.py" "${arguments[@]}"
