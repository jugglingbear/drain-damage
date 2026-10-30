# Drain Damage

Drain Damage is an experimental passion project that started with a question: could we create a video game from
scratch, with zero game development knowledge, using AI?

This repository is the result of finding out. It's a retro 2D action game about Tony and Sean, two plumbers dealing
with a job that has gone horribly wrong. Expect sewer monsters, questionable plumbing equipment, and adult humour.
The game is still being built, and learning how to make it is as much a part of the project as the game itself.

- **[Read the magazine](https://jugglingbear.github.io/drain-damage/)** — Discharge Quarterly introduces the
  characters, creatures, and world.
- **[Explore the storybook](https://jugglingbear.github.io/drain-damage/storybook/storybook.html)** — screenshots and
  milestones documenting how the game has evolved.
- **[Listen to the sound auditions](https://jugglingbear.github.io/drain-damage/audio/drain-damage-sound-auditions.html)**
  — a searchable library of game sounds and alternatives. Listen directly in your browser, or save the page to use it offline.

## Try the game

The [0.138.0 prototype candidate](dist/v0.138.0/) includes
**macOS (Apple Silicon and Intel)** and **Windows x86_64** packages. Final release publication awaits the dialogue
visual check. Play Level 1, its bosses, and the Level 2
flush, landing and 13-encounter ride showcase. The campaign is still unfinished.

See the [macOS installation guide](dist/v0.138.0/macos-universal/INSTALL.md) or
[Windows installation and test guide](dist/v0.138.0/windows-x86_64/INSTALL.md). Windows is exported but has not yet
been tested on native Windows hardware. The Mac app is ad-hoc signed; the Windows executable is unsigned.

Choose Tony or Sean, then fight your way through the job. The in-game Controls screen covers keyboard and controller
bindings. This is a work in progress, so expect rough edges and changing artwork, sound, and balance.

## Behind the scenes

The game uses Godot, with AI-assisted code, artwork, writing, and sound experiments. Music and other source materials
have their credits and provenance recorded alongside the assets.

For the technical side, see the [development guide](docs/DEVELOPMENT.md), [roadmap](roadmap.html), and
[audio workflow](audio/SOUND-AUDITIONS.md). The old README's detailed prototype notes are preserved in
[the development history](docs/development-history.md).
