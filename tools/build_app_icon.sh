#!/usr/bin/env bash
# Repackage Art's selected master; do not alter the original illustration.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
iconset="$project_root/.tools/app-icon.iconset"
master="$project_root/assets/app-icon/porcelain-jaw-v1.png"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$master" --out "$iconset/icon_${size}x${size}.png" >/dev/null
    doubled=$((size * 2))
    sips -z "$doubled" "$doubled" "$master" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$project_root/assets/app-icon/porcelain-jaw-v1.icns"
printf '✅ Packaged selected artwork as macOS ICNS.\n'
