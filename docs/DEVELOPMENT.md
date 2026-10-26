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

macOS is the supported export target. Other platform exports remain future work. The Mac app is ad-hoc signed,
not notarized; see the release's installation notes for first-launch instructions.

## Useful commands

| Command | Purpose |
| --- | --- |
| `make help` | List available commands |
| `make build-macos` | Export and verify the Mac app |
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
Each encounter ends with three full seconds without hazards or next-encounter warnings.
Deaths and retries resume the current encounter without replaying the flush.
Ordinary obstacles and gaps cost one HP, with shared immunity and gap recovery. Only missing the mandatory-ramp
long pit forces a life loss. The ramp launches automatically from grounded contact, locks horizontal steering
through flight, and permits bank steering. Flight lasts 1.25 seconds and peaks about 93.33 pixels above water.
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
