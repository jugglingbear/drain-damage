# Drain Damage 0.81.0 — macOS test release

Download `Drain-Damage-0.81.0-macos-universal.zip` from this release's Assets section.
The ZIP contains the standalone game and these instructions. You do not need Godot, Git, or developer tools.

## Install and open

1. Double-click the ZIP in Finder to extract it.
2. Drag **Drain Damage.app** into Applications.
3. Open the app. Confirm the title screen shows **v0.81.0**.

This test build is ad-hoc signed, without an Apple Developer ID or notarization. macOS may block the first opening.
If you trust this download, first attempt to open it, then use **System Settings → Privacy & Security → Open Anyway**
for Drain Damage and confirm the prompt. Labels vary on older macOS versions.
Follow [Apple's instructions for opening downloaded apps](https://support.apple.com/en-us/102445).
Do not disable Gatekeeper globally. If macOS reports damage or malicious software, stop and report the exact alert.

## Compatibility and test scope

The app contains Apple Silicon and Intel executables. Its bundle declares macOS 13 or later for Apple Silicon
and macOS 11 or later for Intel. Those minimum systems and Intel hardware have not been tested.
The requested fresh-Mac target is Apple Silicon on macOS 26.6.2. Local validation uses the same chip family and OS.
Headless checks do not verify graphics, sound output,
controller pairing, or first launch on a fresh Mac. This download is intended for that hands-on test.

## Play

- Move with A/D or the left/right arrows.
- Jump with Space; release early for a shorter jump.
- Aim with WASD or arrows. Straight-down aim requires being airborne.
- Hold Enter/Return to fire; J and X also work.
- Press Escape to pause or resume.

Choose Tony or Sean and a difficulty from the menus. This build includes the first-level Skitterling encounter,
the revised rat gait, six alligator debris shots, a one-second post-landing charge delay, the improved pause menu,
and 24-HP Septic Air Force swarms that take two hits from either active starter weapon.

## What to report

Please record your Mac model/chip, macOS version, the version shown in the game, and any exact error text.
Check opening from Applications, movement and firing, music and effects, pause/resume, and quitting/reopening.
Controller use, boss timing, rat animation, swarm balance, and checkpoint recovery still need human review.
Dialogue is text-only. The wider campaign, Clogfather encounter, and some story/art production remain unfinished.

## Verify the download (optional)

`SHA256SUMS.txt` lists the ZIP's SHA-256 checksum. A mismatch means the download should be replaced.
The release manifest records the source commit, packaged-file hashes, tool versions, and validation scope.
