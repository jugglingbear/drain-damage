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
