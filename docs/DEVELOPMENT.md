# Development guide

Drain Damage uses Godot 4.7.2. Run commands below from the repository root. The project keeps its tools and everyday
builds in ignored `.tools/` and `builds/` directories.

## Set up and build

Install Git LFS before cloning, then fetch the binary assets:

```sh
git lfs install
git clone https://github.com/jugglingbear/drain-damage.git
cd drain-damage
git lfs pull
make install
make build
```

Python 3.10+, Git, Git LFS, and Make are required. `make install-plan` previews dependency setup;
`make install-check` checks readiness. `make install INSTALL_FLAGS=--system` can install missing prerequisites
through an existing supported package manager. Use `bash tools/install.sh --system` if Make is not installed.
The installer pins tools using `tools/godot-lock.json` and does not launch the game.

macOS and Windows x86_64 exports are configured. Windows runtime validation is still pending. The Mac app is
ad-hoc signed and not notarized; Windows exports are unsigned. See each package's installation notes.

## Useful commands

| Command | Purpose |
| --- | --- |
| `make help` | List available commands |
| `make build-macos` | Export and verify the Mac app |
| `make build-windows` | Cross-export, check resources, and ZIP Windows x86_64 |
| `make build-all` | Build both platforms sequentially on macOS |
| `make run` | Launch current source |
| `make editor` | Open the Godot editor |
| `make run-targets` | List available direct playtest destinations |
| `make combat-data` | Validate and rebuild combat metadata |
| `python3 -m unittest discover -s tests -p 'test_*.py'` | Run Python checks |
| `python3 tools/build_sound_auditions.py` | Regenerate the portable sound auditions |

Close the game before rebuilding its app. Agents must follow [the project instructions](../AGENTS.md), including
permission before opening or foregrounding the game for a playtest. A build or documentation update
is not launch permission.

## Direct Level 2 playtests

Start the flush sequence without completing Level 1:

```sh
make run LEVEL=2 HERO=tony DIFFICULTY=normal
```

Skip the flush and start at the post-flush log landing:

```sh
make run LEVEL=2-landing HERO=sean DIFFICULTY=hard
```

Both entries initialize a fresh run without a prior save. Either accepts `HERO=tony|sean`,
`DIFFICULTY=easy|normal|hard`, and optional `SEED=42`. The landing entry shows the existing landing dialogue,
then starts the ten-encounter ride showcase. Start directly at an encounter with `LEVEL=2-01` through `LEVEL=2-10`.
Steer with arrows/stick; up/down moves between banks and left/right shifts within the view. Space/A jumps.
The ride advances at 560 pixels/second, with horizontal/bank steering at 400/350 pixels/second.
Regular jumps last 0.6 seconds, reach 54 pixels and have a 0.1-second landing cooldown.
Prototype 108 accepts fresh grounded jump presses during safe rests and carries flight across encounter boundaries.
Holding Space/A does not repeat jumps; airborne/cooldown presses are not queued.
Each encounter ends with three full seconds without hazards or next-encounter warnings.
Deaths and retries resume the current encounter without replaying the flush.
In Prototype 107, every true pit or unsupported-gap fall costs one life and visibly descends
before the death menu. Ordinary solid/overhead/spike hits remain one HP; normal riding water is safe.
Prototype 122 requires at least half of the hero’s contact footprint over an opening before a fall; edge and
corner grazes are safe. Ride platforms support the rider at half-footprint overlap. Jump clearance and swept
collision timing remain active.
The preserved Prototype 106 app still has its earlier nonlethal ordinary-gap policy. The ramp launches automatically
from grounded contact, locks horizontal steering through flight, and permits bank steering. Flight lasts 1.25 seconds and peaks about 93.33 pixels above water.
The Prototype 107 ramp is 100 pixels across the banks: visible edges 280–380, with full-board center support
294–366. Poor alignment misses the boost; the approved ascent curve and angles are unchanged.
All ten encounters use the same course in every mode. Shared health/life markers remain visible.
This movement-only showcase has no combat; the full ride and later stages remain unfinished.
Actual gameplay screenshots and visual ramp-contact review remain pending.
During the flush, steer to swim and dodge; firing and jumping are disabled. Tony uses freestyle and Sean uses
breaststroke. Weapons remain equipped for later gameplay but cannot fire in this sequence.
Flush dialogue has doubled reading time with unchanged wording: hazards start at 34 seconds, the automatic drain at
61, and landing at 71. The six-second landing line leads into the ride at 77. The original 45-second score plays
from 26 through 71 seconds without changing speed. Pause freezes these times.
Use `make run-check` with the same selectors to verify initialization without opening a window.

## Where things live

- `scripts/` contains game logic; `project.godot` defines the project and canonical version.
- `bestiary/*/monster.json` and `weapons/*/weapon.json` contain canonical combat specifications.
- `data/combat.json` is generated: edit its canonical inputs instead.
- `audio/sound-registry.json` connects permanent audition IDs to files and their runtime mapping sources.
- `handoffs/` contains integration records; [the roadmap](../roadmap.html) tracks current work.
- [The storybook](../storybook/README.md) preserves development captures and records capture gaps.
- [The magazine guide](../marketing/magazine/README.md) explains publication editing and generation.

See [the audio workflow](../audio/SOUND-AUDITIONS.md) before changing any sound. Keep auditions in the repository and
regenerate the HTML in the same delivery. Retained media uses Git LFS; local tools, build products, and
private reference
material stay out of commits.

## Historical reference

[The former README](development-history.md) preserves detailed prototype notes, older setup explanations, credits,
and release procedures. Its dated gameplay claims are historical and sometimes superseded. Consult current canonical
metadata and delivery records before relying on them.

## Screenshot freeze

Prototype 109 and the source launcher accept an opt-in screenshot flag; Prototype 106 does not include it.

```sh
make run LEVEL=2-landing SCREENSHOT_MODE=1
```

With the flag set, controller Y (the top face button) freezes the current gameplay scene without adding a pause menu,
dimmer or buttons. The normal HUD remains visible. Press Y again and release the controls to resume. Gameplay,
animations, dialogue, particles and audio pause together. Focus loss leaves the scene frozen until Y is pressed again.
Ordinary pause/death menus retain their existing controls; capture mode does not replace an already-open menu.
The flag also works with other launch targets or an ordinary `make run SCREENSHOT_MODE=1` start.
Use `SCREENSHOT_MODE=0` or omit it for unchanged controls. Only `0` and `1` are accepted.
To use the preserved export, add `APP="builds/Prototype-109/Drain Damage.app"` to the command.

## Prototype 108 encounter corrections

`LEVEL=2-01` uses visible far-wall, near-wall and center structures with matching collision surfaces. The safe weave
moves near, far, then near again; the structures are spaced 520 pixels apart. Neutral horizontal steering keeps the
tested approach timing. The safe-route tests allow 50 milliseconds of early or late bank-change input.

`LEVEL=2-02` routes along the far bank around a broken lower channel. The pipe occupies x2320–2500 and costs one HP
on contact; the pit occupies x2520–3220, y300–430 and costs a life on an unsupported fall. Target bank y270 leaves
16 pixels of full-board clearance. The cascade is animated; its artwork, rims and collision bounds are registered.
The earliest visible pipe approach at the rightmost anchor is about 2.90 seconds; safe rests remain three seconds.

Prototype 109 anchors the float arm to the far wall at y220, clips the mount at the waterline and keeps the rod
connected throughout its sweep. The ball collider and movement are unchanged; mount and rod remain decorative.
Mixed-course pacing, brush-curtain redesign and the new final
boss remain proposals; Prototype 108 does not implement them. Human visual and controller review remains pending.

## Level 2.1 camera proof

Launch the isolated comparison course with either hero:

```sh
make run LEVEL=2.1 HERO=sean
```

The existing Level 2 entries remain available. This proof contains a raised porcelain slab, brass platform,
round opening with flowing water, and ramp. Move with the existing arrows/WASD/stick and jump with Space/A.
C, controller RB, or the camera button toggles between fixed +18-degree and -18-degree yaw views from safe water.
Movement pauses for the 1.2-second comparison turn; Escape pauses the whole test. A fall costs one life and uses
normal retry controls. The interface stays flat while the world camera turns.

This is a presentation and contact proof, not a converted production level. Surrounding water is safe; the round
opening is lethal. Slabs auto-step, the ramp uses a center-height contact model, and the reused hero image includes
its painted board. Prototype 119 uses a 35-degree camera pitch, contact-anchored billboards and blended water texture seams.
Actual macOS captures were inspected at both angles, on the basin and on the ramp. Props remain simplified;
performance benchmarking and native Windows rendering still need review. Full-level migration remains unapproved.

## Windows exports and testing

On the Mac, run `make build-windows`, or `make build-all` to produce both platform exports.
Windows export also works with a pinned Linux Godot editor selected through `GODOT`; Linux host execution is untested.
`make install` stages checksum-verified Windows templates locally alongside the host tools. The Windows build target
also installs those templates if missing. No VM, Wine, Windows SDK, signing certificate, or Windows machine is
required for these unsigned exports. Godot embeds the existing game icon and synchronized Windows version metadata.

The game version remains canonical in `project.godot`. Windows file/product versions append `.0` to that version.
Each Windows build writes a new timestamped folder, ZIP, and SHA-256 file under `builds/`, preserving earlier builds.
The ZIP contains the EXE, separate PCK, console companion, Godot license notice, instructions, a file-hash manifest,
and `Test-Windows.ps1`. These build products are ignored by Git; attach the ZIP and checksum to a release when publishing.
`make build-all` builds both platforms but does not create or publish a GitHub Release.

Before packaging, the builder rejects unresolved LFS assets, mismatched templates, export errors, invalid x86_64 PE
headers, and invalid resource packs. It initializes six destinations from the exported PCK using the host Godot
engine. Those checks verify exported resource availability and initialization; they do not execute Windows machine code.
The manifest records the source commit, dirty working-tree state, host checks, and pending Windows validation.

On a Windows x86_64 machine, extract the whole ZIP and launch `Drain Damage.exe`. Keep the PCK beside it.
There is no need to clone this large repository or install Godot, Python, or Git just to play the exported build.
The unsigned executable may produce a Windows reputation warning; no publisher certificate is included.

For automated native initialization checks, open PowerShell in the extracted folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-Windows.ps1
```

This invocation applies the script policy only to that PowerShell process. The script checks package hashes,
launches the Windows executable headlessly for both heroes across six destinations, requires success markers,
and saves logs in a timestamped `test-results-*` folder. Each launch has a two-minute timeout.
The existing verification path can report resources still in use during shutdown after its success marker.
These warnings remain in the logs and manifest; other errors fail the checks.
Native execution and PowerShell behavior remain unverified until run on Windows.
Follow with a visual check of menus, both heroes, Level 1, the flush, the ride, sound, keyboard/controller input,
fullscreen/window behavior, and frame pacing. A headless pass does not establish those results.

## Ramp contact invariant

Supported riders follow the surface slope using the rigid board’s underside contacts. Elevation alone is insufficient:
the board and rider pitch must track the slope without penetration or hovering through entry, ascent and exit.
Camera-facing artwork must preserve that pose at every supported viewing angle. Jump takeoff, flight and landing
retain continuous contact behavior. This applies to production levels and camera prototypes alike.
