# Drain Damage

A solo, forgiving 2D plumbing action prototype for macOS, built with Godot 4.7.2.
Bright retro visuals accompany adult dialogue. Choose Tony or Sean; BJ, the robot owner, supervises both.
Their employer’s working name is Mainframe Plumbing & Supply. The game title remains Drain Damage.

## Play

Open `builds/Drain Damage.app` in Finder. Godot is not required to play the exported app.
This local prototype is ad-hoc signed, not notarized for public distribution.

- Move: A/D or left/right arrows.
- Jump: Space (controller A). Release early for a shorter jump.
- Aim: WASD/arrows or controller left stick/D-pad; only straight-down aim requires being airborne.
- Fire: Hold Enter/Return (including keypad Enter). J and X also work.
- Pause/resume: Escape.

Prototype 45 starts the faster sewer opening directly from Start and continues through the 9,600-pixel first level.
There is no timed mode, twenty-second cutoff or results popup. The opening has supported one-way decks, clearer
foreground plinths, Flushfiend runners, a perched shooter, a warned floor emerger and flying spiders. Spatial triggers
and safety checks control arrivals; running past an unsafe entry does not create kill credit. Later rooms retain their
finite waves and checkpoints. Prototype 47 removes kill-count shutters: ordinary enemies never block advancement.
The finale remains toilet waves until the planned boss is implemented.

Tony has four contact-hit health and speed 270; Sean has five and speed 235. Both share jump physics.
One Spare Employee Dispenser near the midpoint saves progress and heals once. It holds one selected-hero clone.
Injured check-in plays a 5.5-second replacement gag; full-health check-in stamps in 0.4 seconds without using the clone.
The first replacement consumes its stock. Later respawns arrive beside the empty machine without another dispense.
Stock stays empty across deaths and revisits; only a new run refills it. The three-life system is unchanged.
Later injured sequences can use the existing dialogue-skip control. The gag costs no life. You begin with three total lives. After a death animation,
BJ presents one of twelve messages with a matching emotional portrait. Choose Continue to return to the latest
checkpoint with full health and three seconds of protection if lives remain. Held buttons cannot dismiss the popup.
Defeated enemies stay defeated. At zero lives, Game Over offers Retry or Return to Main Menu; Retry starts a fresh run.
Reach the exit; clearing ordinary enemy waves is optional. The approved introduction and route-specific completion dialogue remain skippable.
Prototype 35 animates body movement independently of aim, with six run frames and distinct jump, landing,
hurt and death poses. The HUD shows one selected-hero head for each remaining life.
Human pacing and visual review are pending. Automated tests verify continuous play beyond twenty seconds,
checkpoint recovery, encounter accounting, open traversal and completion conditions. They do not establish survival balance.
No game window is opened by headless tests.

## Opening screen

Prototype 12 opens with original illustrated plumbing chaos, a chunky pixel logo, subtle sparkles,
and Start / Controls / Quit. The Controls screen contains illustrated keyboard and gamepad references.
All in-game button instructions live there. The selected title song is “It Takes A Hero” by Zane Little Music.

- Open employee selection: Enter, Space, controller A, or Menu.
- Toggle music: M or controller Y (remembered for this session only).
- Return to title from pause or the completed-job screen: Q or controller B.
- Quit from title: Escape.

Title artwork and its exact generation prompt are preserved in `assets/title/`.

## Choose your employee

After Start, choose with A/D, arrows, left stick, D-pad, or a mouse click.
Confirm with Enter/Space, controller A/Menu, or CLOCK IN. Escape/controller B goes back.

| Employee | Weapon | Damage per hit | Time between shots | Tradeoff |
| --- | --- | --- | --- | --- |
| Tony: confident fourth-generation plumber | Pressure gun | 12 | 0.16 seconds | Fast recovery, lighter hits |
| Sean: idiot apprentice | Heavy plunger | 18 | 0.24 seconds | Heavier hits, slower recovery |

Tony is the default employee. The clipboard displays one profile at a time; the separate punch clock confirms it.
Restart and respawn preserve your choice. Return to title to switch employees. Balance is provisional.
The first-level profile supplies these faster values; canonical baseline records remain for comparison.
Tony’s pressure gun reaches 320 logical pixels; Sean’s plunger reaches 480.
BJ uses the approved server-rack portrait and semantic emotional expressions.

## Portrait dialogue

The tutorial and opening controls briefing were removed in Prototype 12. Character selection begins the approved story introduction, then the basement. Story conversations still freeze gameplay and support reveal, advance, and skip.
The expanded route is integrated. The Clogfather, acid hazards, and portal remain deferred.

The first world-art pass adds a layered pixel basement, animated Sean and toilet sprites, and detailed metal platforms.
Sean is completely bald with a chin-only beard and no moustache.
Idle, running, jumping, firing, and hurt poses are integrated; animation transitions still need polish.
Prototype 07 enlarges Sean to 72 logical pixels tall and fixes neighboring-pose bleed in the animation atlas.
The forgiving collision box stays unchanged; the projectile origin follows the enlarged launcher.
Portrait images were created with built-in image generation using the supplied likeness references.
The portrait prompts are preserved in `assets/portraits/prompts.json`.
World and sprite prompts are in `assets/art-prompts-v1.json` and `assets/sean-correction-v2.json`.

## Controller controls

- Move: Left stick or D-pad.
- Jump: A (hold for a higher jump).
- Fire: X or right trigger.
- Pause/resume: Menu/Start.

Bindings use Godot's standard gamepad mapping, with a stick deadzone to reduce drift.
Disconnecting a controller pauses play. Sean confirmed successful in-game testing with an Xbox Series X|S controller on
October 13, 2026.

## Develop

From Terminal, run `cd /Users/sfoley/repos/plumbing_inc`, then:

| Command | What it does |
| --- | --- |
| `make` or `make help` | Show the colorized command list |
| `make check` | Check the Godot executable |
| `make build` | Build for the local OS; currently macOS only |
| `make build-macos` | Export, include license notices, ad-hoc sign, and verify the Mac app |
| `make build-all` | Build every supported export; currently only macOS |
| `make run` | Run current source in the normal large window |
| `make run-preview` | Run current source in a small agent-test window |
| `make editor` | Open Godot's editor |

Close the game before rebuilding. The Mac build replaces `builds/Drain Damage.app`.
`make run` uses the source directly, so it does not need a standalone export first.
Use `make run GODOT=/path/to/Godot` to override the executable. Paths may be shell-quoted if they contain spaces.
On macOS the default is the existing project-local Godot; other hosts look for `godot` on PATH.
Other-host execution is not yet verified. Windows will need a compatible shell and Make environment.

`make build-android`, `make build-ios`, and `make build-windows` are reserved commands that currently
fail with setup guidance. They do not claim to produce builds. SDKs, templates, signing where needed,
export presets, and real-device testing remain future work. Mac exports are not notarized for public distribution.

The project-local editor is in `.tools/Godot.app`. Import `project.godot` to edit the game.
The opening screen in `scripts/title_screen.gd` plays a repeating CC0 retro music cue.
Music provenance, adaptation details, and the Storyboarding brief are in `audio/title-music.json`.
The original recording and previous synthesized sting source are preserved under `audio/sources/`.
For small agent-only previews, launch with `-- --agent-test`; normal launches remain maximized.
Movement, combat, and synthesized sound are in `scripts/game.gd`.
Authored terrain and solid-body collision are in `scripts/first_call.gd`; finite encounter accounting is in
`scripts/mission_state.gd`. Art crops follow `assets/world/first-call/manifest.json`.
World rendering and sprite-atlas animation are in `scripts/world_art.gd`.

```sh
.tools/Godot.app/Contents/MacOS/Godot --path .
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/smoke.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --export-release macOS
```

The official macOS template is installed in Godot's user export-template directory.
A local copy is also retained at `.tools/macos.zip`.
Downloaded tools, templates, build products, and Godot caches are ignored by version control.

## Git checkout and asset storage

Install Git LFS before cloning, then fetch the retained binary assets:

```sh
git lfs install
git clone https://github.com/jugglingbear/drain-damage.git
cd drain-damage
git lfs pull
```

Source, scenes, manifests, prompts, and documentation use ordinary Git. Retained images, audio, PDFs, and
source archives use Git LFS. Generated builds, downloaded tools, private likeness references, rejected artwork,
and obsolete magazine editions stay local and are excluded by `.gitignore`. The storybook preserves intentional
history. Some archived design records refer to excluded local drafts; those links are historical, not build inputs.

The initial commits organize the existing Prototype 52 snapshot by subsystem; they do not reconstruct its original
implementation chronology. The complete initial series is the buildable baseline.

For a fresh Mac checkout, install the Godot 4.7.2 editor and matching macOS export template. Place the editor at
`.tools/Godot.app` (or override `GODOT`) and the template at `.tools/macos.zip`, then run `make build`.
The tracked `licenses/GODOT_COPYRIGHT.txt` is copied into each exported app. Engine binaries and templates are
intentionally not downloaded by the build.

## Creative direction

- Solo play as Tony or Sean, with distinct weapons and a robot owner bossing both around.
- Cheerful SNES-inspired presentation, original characters and environments, adult language.
- Forgiving combat, quick retries, and readable attacks.
- Next milestone: playtest character selection and weapon balance, then develop the first mission and boss.

## Roadmap

Open the [development roadmap](roadmap.html) for milestones, priorities, and Android/iOS feasibility research.

## Development storybook

Follow the screenshots and milestones in the [making-of storybook](storybook/README.md).
Each delivered iteration adds a new chapter while preserving the earlier images.

## Credits and rights

Environment details and sound synthesis are authored in this project.
Background, character sprites, enemy sprites, and dialogue portraits use original AI-generated artwork.
No reference photos are bundled in the game.
The photographs serve as likeness references for character design. Confirm likeness and photo permissions before
release.

This game uses [Godot Engine](https://godotengine.org/), under the MIT license.
See [Godot's license and third-party notices](https://godotengine.org/license/).
Godot's bundled copyright notice is included alongside the exported app as `GODOT_COPYRIGHT.txt`.
Working names are provisional; no trademark or patent clearance has been performed.

## Combat metadata

Prototype 14 reads combat values from a generated, validated JSON bundle. Edit canonical specifications in
`weapons/<id>/weapon.json` and `bestiary/<slug>/monster.json`, then run `make combat-data`.
`make build`, `make run`, and `make run-preview` regenerate it automatically. `data/combat.json` is generated;
do not edit it. It is explicitly included in exports while the ignored marketing directories remain excluded.

The pressure gun and heavy plunger launcher use canonical damage, cadence, projectile speed, and maximum travel.
Flushfiends have 40 HP. Player health remains five points for both employees;
proposed player-stat changes are unresolved.
Ordinary enemy bars default off; toggle them on the Controls screen. The preference lasts for the session.
Damage rows use the approved exact boundaries, flash on every hit, and play death once, holding its final frame.

All six weapons validate, but melee, the pipe-bomb launcher, and loadout selection are not playable yet.
New weapon pixel sheets remain source artwork; current held weapons/projectiles retain their earlier visuals.
The Hallowed Widow has an animated damage preview and validated 80-HP data, not flight AI or playable encounters.
Its wing gutters and thorax alignment still need refinement. Runtime crop/anchor preparation is stored alongside
original damage specs; original images are preserved. Run the preview only when a visible window is appropriate:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . damage_preview.tscn -- --agent-test
```

Headless checks:

```sh
python3 -m unittest discover -s tests -p 'test_combat_metadata.py'
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/combat_data.gd
```

The combat test deliberately logs rejected IDs, ownership violations, and unimplemented mechanics.

## Selected soundtrack

Prototype 16 uses “It Takes A Hero” for title/selection and “Hallow Quest” (16-bit) for the basement.
Both tracks are by Zane Little Music under CC0; source URLs, originals, licenses, and hashes are in
`audio/catalog.json` and each track's `audio/sources/<id>/track.json`. The earlier Face The Facts cue is preserved.

One music voice prevents overlap: fade out for 0.25 seconds, switch, then fade in for 0.25 seconds.
Title gain is -16 dB; level gain is -20 dB, with another 4 dB reduction during dialogue.
Hero repeats after its full ending rather than pretending to be seamless. Hallow loops its complete authored stream.
Music mute applies across screens; effects remain audible. Pause suspends music, restart continues it,
and returning to the title changes back to Hero. Headless tests pass; subjective listening remains pending.

## Dialogue emotions and current art

Prototype 18 integrates the Drain Damage title art and menu plates, Tony v3, Sean v4, and BJ v2 portraits.
Tony wears his navy work shirt in portraits; Sean has no glasses; BJ uses the beige server-rack design.
Title art and movement sprites retain their existing clothing. Marketing art is not substituted for game sprites.

Every conversation line has `who`, `emotion`, and `text`. Use semantic emotions from
`assets/portraits/emotions-v1.json`: neutral, happy, amused, sad, worried, afraid, surprised, angry,
skeptical, or embarrassed. Do not use numeric face indices. For example:

```gdscript
{"who": "TONY", "emotion": "skeptical", "text": "Four generations of plumbing. Still answering to a calculator."}
```

`scripts/portrait_library.gd` shares the 5×2 atlas selection between dialogue and character selection.
Rounded boundaries and clipped filtering prevent sampling neighboring cells. Headless tests validate all 30 cells
and both endings; final in-game portrait framing remains pending a permitted visual session.
Storyboarding's future spider conversation remains deferred until a spider encounter exists.

## Opening story

Prototype 19 plays the approved seven-line introduction after character selection, once per fresh new game.
The shared script in `scripts/story_dialogue.gd` uses canonical speaker IDs and named emotional tones.
Both characters participate regardless of the selected hero. Death, checkpoint respawn, and retry do not replay it;
returning to the title and starting a new game does. The ending dialogue is unchanged.

The dialogue overlay shows the current Skip binding (Tab or controller B). This is an approved exception to keeping
button hints on Controls. Typewriter reveal and advance remain; world simulation freezes during conversations.
Dismissal waits for held dialogue/shoot/jump buttons to release before action can resume.
Future between-level scenes will use the same conversation system; no future scenes or tutorial have been added.

## Controls field guide

Prototype 20 separates primary gameplay actions from job, menu, and conversation references. The keyboard and
rounded, unbranded gamepad use original grimy hardware illustrations; live text describes the actual bindings.
Music and enemy-bar toggles have separate clickable footer buttons. Keyboard/controller shortcuts are unchanged.
Artwork, exact generation prompts, dimensions, and reference-manual links are in `assets/controls/art-v1.json`.
Source illustrations use the built-in image-generation tool; source web artwork was not copied.

Two optional sewer-fly swarms drift through the first level without chasing. Each has 12 HP; contact can hurt
plumbers and ordinary monsters. They are not required for doors to open, and stay defeated across checkpoint recovery.
Their initial movement and contact balance still need visual playtesting.
