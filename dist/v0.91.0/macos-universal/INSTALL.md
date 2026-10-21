# Drain Damage 0.91.0 — macOS development demo

This is a playable first-level development demo, not the finished campaign. Choose Tony or Sean and a difficulty,
fight Skitterling and the Clogfather, and reach the portal ending. Level two is not playable.

## Install and open

1. Download `Drain-Damage-0.91.0-macos-universal.zip` from the GitHub release's Assets section.
2. Double-click the ZIP in Finder, then drag **Drain Damage.app** into Applications.
3. Open the app and confirm the title screen shows **v0.91.0**. Godot and developer tools are not required.

The app is ad-hoc signed, without Apple Developer ID signing or notarization. macOS may block its first opening.
If you trust this download, try opening it, then use **System Settings → Privacy & Security → Open Anyway**
for Drain Damage and confirm the prompt. Follow
[Apple's guidance for opening downloaded apps](https://support.apple.com/en-us/102445).
Do not disable Gatekeeper globally. If macOS reports damage or malicious software, stop and report the exact alert.

## Compatibility

The app contains Apple Silicon and Intel executables. It declares macOS 13 or later for Apple Silicon and macOS 11
or later for Intel. Intel hardware and those minimum versions have not been tested.

Local checks use Apple Silicon on macOS 26.6.2. Sean confirmed that the earlier **0.81.0** build opened on a fresh
Apple Silicon Mac running macOS 26.6.2 after using Open Anyway. That is historical evidence for 0.81.0 only;
fresh-machine installation, live graphics, audio output and controller pairing remain unverified for 0.91.0.

## Play

- Move with A/D or left/right arrows.
- Jump with Space; release early for a shorter jump.
- Aim with WASD or arrows. Straight-down aim requires being airborne.
- Hold Enter/Return to fire; J and X also work.
- Press Escape to pause or resume.

The demo includes difficulty-menu navigation, progressive wastewater, both boss encounters, animated Gratecrawler
throws and the full-size portal departure. Defeating Skitterling immediately saves a checkpoint beyond its exit.
The later checkpoint still takes precedence. Dialogue is text-only.

## Known gaps and feedback

Live animation transitions, water and portal layering, combat balance, sound mixing and actual-build screenshots
remain pending review. Headless checks do not establish GPU performance or an uninterrupted human playthrough.
The release manifest describes the exact automated coverage and remaining gaps.

When reporting a problem, include your Mac model/chip, macOS version, game version, what happened and any exact
error message. Useful checks include opening from Applications, movement, firing, audio, pause, checkpoint retries,
controller use and quitting/reopening.

## Verify the download

`SHA256SUMS.txt` lists the ZIP's SHA-256 checksum. Replace a download whose checksum does not match.
The release manifest records packaged-file hashes, source commit, signing and validation details.

Read the optional [Discharge Quarterly magazine](https://jugglingbear.github.io/drain-damage/).
Its historical imagery is not evidence of fresh 0.91.0 gameplay testing.
