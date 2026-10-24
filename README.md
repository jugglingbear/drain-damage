# Drain Damage

A solo, forgiving 2D plumbing action prototype for macOS, built with Godot 4.7.2.
Bright retro visuals accompany adult dialogue. Choose Tony or Sean; BJ, the robot owner, supervises both.
Their employer’s working name is Mainframe Plumbing & Supply. The game title remains Drain Damage.

## Play

Download the [0.91.0 macOS development demo](https://github.com/jugglingbear/drain-damage/releases/tag/v0.91.0).
Extract the ZIP and move **Drain Damage.app** to Applications. Godot is not required.
See the [installation guide](dist/v0.91.0/macos-universal/INSTALL.md) for the first-launch Open Anyway procedure.
The universal app is ad-hoc signed and not notarized. Local development builds remain in `builds/Prototype-91/`.

The current demo covers the 15,200-pixel first level, including Skitterling, the Clogfather and the portal ending.
Skitterling victory immediately saves a checkpoint beyond its exit. Level two and the wider campaign are unfinished.

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
The finale retains ordinary waves; Clogfather remains planned. Prototype 69 adds Skitterling before that finale.

Tony has four contact-hit health and speed 270; Sean has five and speed 235. Both share jump physics.
One Spare Employee Dispenser near the midpoint saves progress and heals once. It holds one selected-hero clone.
Injured check-in plays a 5.5-second replacement gag; full-health check-in stamps in 0.4 seconds without using the clone.
The first replacement consumes its stock. Later respawns arrive beside the empty machine without another dispense.
Stock stays empty across deaths and revisits; only a new run refills it. The three-life system is unchanged.
Later injured sequences can use the existing dialogue-skip control. The gag costs no life. You begin with three total lives. After a death animation,
BJ presents one of twelve messages with a matching emotional portrait. Choose Continue to return to the latest
checkpoint with full health and three seconds of protection if lives remain. Held buttons cannot dismiss the popup.
Death resets encounters from the active respawn origin, including defeated enemies, while clearing old enemies,
projectiles, corpses and warnings. Before the checkpoint, the level encounters restart. After it, earlier sections
stay inactive; only checkpoint-owned encounters and those ahead return. The selected difficulty and resolved encounter
arrangement stay the same across remaining-life respawns. At zero lives, Retry starts a new run with a new seed.
Reach the exit; clearing ordinary enemy waves is optional. The approved introduction and route-specific completion dialogue remain skippable.
Prototype 35 animates body movement independently of aim, with six run frames and distinct jump, landing,
hurt and death poses. The HUD shows one selected-hero head for each remaining life.
Human pacing and visual review are pending. Automated tests verify continuous play beyond twenty seconds,
checkpoint recovery, encounter accounting, open traversal and completion conditions. They do not establish survival balance.
No game window is opened by headless tests.

Prototype 70 adds eight Gnatastrophe encounters to the existing swarm, distributed across the opening, service
route, overhead pump and three post-boss locations. These additions use a separate two-swarm capacity budget so they
cannot displace ordinary monster admissions. New swarms have 0.8 seconds of visible harmless warning and hold contact
while the hero occupies their initial footprint. Checkpoint retries restore four later encounters. The quiet approach
and Skitterling room stay empty of ordinary enemies. All eighteen packaged full-route bots encountered all nine swarms;
contact remained enabled, with test-only healing to complete coverage. Human chaos, fairness and sound review remain
pending.

## Opening screen

Prototype 12 opens with original illustrated plumbing chaos, a chunky pixel logo, subtle sparkles,
and Start / Controls / Quit. The Controls screen contains illustrated keyboard and gamepad references.
All in-game button instructions live there. The selected title song is “It Takes A Hero” by Zane Little Music.

- Open employee selection: Enter, Space, controller A, or Menu.
- Toggle music: M or controller Y (remembered for this session only).
- Return to title: choose Main Menu in the pause/completion menu. Controller B resumes or cancels pause.
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

Prototype 68 fixes Flushfiends stalling against a second platform. They jump again after landing on each reachable
step, using the same jump strength and movement collision. A blocked ceiling or unreachable wall triggers a short
retreat. This is grounded navigation, with no midair double jump. Live staircase review remains pending.

## Skitterling encounter

Prototype 71 uses lateral tunnels into and out of the locked 960×540 room. Walk, stop or reverse inside them; authored
foreground shells occlude the hero naturally. Entry closes only after the hero walks fully into the room. The camera
blends into position, stays fixed through the fight and follows the hero out after the final defeat. Background and
ceiling attack pipes retain their existing placement. The floor remains continuous, with no drowning mechanic.

Roaches enter, shriek and form a rat with 540 HP: 45 Tony hits or 30 Sean hits, roughly seven seconds of uninterrupted
fire. Its apparent death still holds for four seconds before renewed movement and the 180 HP alligator form. Excess
rat damage cannot skip the second fight. The named 720 HP bar stays visible through transitions alongside player health
and lives. Rat bites and pipe launches retain warnings.

The alligator dives and visibly swims beneath the hero. It stops at a committed column for a 0.8-second warning, then
throws one item vertically upward. The item hurts on its way up or down and never homes after the warning. Three
sequential throws use distinct nearby origins, reacquiring the hero between throws; the 28-pixel item can still hit a
stationary hero at each origin. After swimming to an emergence point, it warns, surfaces and performs two room-crossing
jaw charges, each with a warning. The cycle repeats until defeated. Hidden travel is invulnerable, and occupied returns
warn again rather than spawning on the hero. Death resets the fight at checkpoint 4650 under the normal clone-stock
rules.

Automated checks cover both heroes, all difficulties, stationary hits and moving dodges, walking portals, camera,
checkpoint resets, launch shortcuts and full routes retaining all nine swarm encounters. Live animation, sound,
human balance and screenshots remain pending; headless tests do not establish survival fairness.

## Game difficulty

After choosing Tony or Sean, select Easy, Normal or “The Computer is Cheating!!” (the Hard mode).
Prototype 67 restores the same plate size as Easy and Normal, with the original sludge, bolts and metal texture
visible. Art-approved coral tints add warmth across normal, hover and selected states; the full label fits at 22px.
Selection retains a rim, corner marks and arrow. The internal Hard mode and gameplay are unchanged. Difficulty explanations and selected
hero portraits/names remain absent, leaving the differences for players to discover.
Normal is the default. Use Up/Down or W/S, the controller
D-pad/left stick, or click a row. Enter/Space or controller A/Menu confirms; Back or Escape/controller B returns
to employee selection without changing the chosen hero. The existing introduction follows Start Job.

- Easy has a fixed authored subset, smaller groups and longer spacing.
- Normal resolves controlled encounter variations at the start of each run.
- Hard adds tested opening-role combinations and more overlap within the existing safety limits.

Health, weapon damage and attack tells are unchanged. New runs vary Normal and Hard; a remaining-life respawn
reuses that run's arrangement. Live fairness testing remains pending. Safety checks can defer or omit an entry;
there is no requirement to kill every enemy. The short encounter just after the checkpoint may safely expire
while the respawn protection interval is running.

Prototype 60 extends Hard costumes through movement, aiming, death, HUD heads and the employee dispenser.
Tony and Sean have heavily torn shirts; Sean also has torn blue overalls. Hard uses matching emotional portraits,
and both plumbers speak in uppercase, including radio replies. Easy/Normal and BJ retain their existing presentation.
Actual Godot visual review and screenshots remain pending; offline art composition and packaged checks pass.

## Portrait dialogue

The tutorial and opening controls briefing were removed in Prototype 12. Employee and difficulty selection lead to the
approved story introduction, then the basement. Story conversations still freeze gameplay and support reveal, advance
and skip.
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

## Direct playtest targets

Use `make run-targets` to list implemented destinations. Only level 1 and the Skitterling mini-boss are implemented;
full boss targets remain unavailable. Plain `make run` still opens the normal title and selection flow.

```sh
make run LEVEL=1 HERO=tony DIFFICULTY=normal
make run MINIBOSS=skitterling HERO=sean DIFFICULTY=hard SEED=42
make run-check MINIBOSS=skitterling HERO=sean
```

Choose exactly one of `LEVEL`, `MINIBOSS` or `BOSS`. Optional `HERO` defaults to `tony`, `DIFFICULTY` to `normal`, and
`SEED` to `42`; seed values range from 0 through 2147483647. Unknown, unimplemented, empty CLI or conflicting targets
fail clearly. Hero/difficulty/seed overrides require a destination. `run-check` verifies initialization headlessly and
exits without playing; `run-preview` accepts the same selectors and uses the small agent-test window.

The Skitterling shortcut starts before the entrance tunnel with full selected-hero health, three lives and checkpoint
4650 initialized. Walk through the entrance to start the fight. Earlier encounters are cleared; the post-boss route
remains available. Death uses the normal checkpoint and clone-stock rules. A level shortcut skips the opening dialogue.

To run a preserved exported build, add `APP` with its app-bundle path; the same registry and validation run inside the
exported game. For example, after building Prototype 71:

```sh
make run MINIBOSS=skitterling APP="builds/Prototype-71/Drain Damage.app"
make run-check LEVEL=1 APP="builds/Prototype-71/Drain Damage.app"
"builds/Prototype-71/Drain Damage.app/Contents/MacOS/Drain Damage" -- --miniboss=skitterling --hero=sean
```

Direct Godot source launches accept the same arguments after `--`, including `--level=1`, `--difficulty=hard`,
`--seed=42` and `--list-playtest-targets`. The registry is `data/playtest-targets.json`; new entries also require a real
initializer in `scripts/playtest_launch.gd`. Launch options do not grant agents permission to open a game window.

## Develop

From Terminal, run `cd /Users/sfoley/repos/drain_damage`, then:

| Command | What it does |
| --- | --- |
| `make` or `make help` | Show the colorized command list |
| `make install` | Install pinned local tools and fetch unresolved Git LFS assets |
| `make install INSTALL_FLAGS=--system` | Also install missing system packages through an existing package manager |
| `make install-check` | Check dependency readiness without making changes |
| `make install-plan` | Preview dependency setup without making changes |
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
On macOS the default is the project-local Godot app; Linux uses `.tools/godot` when present, then `godot` on PATH.
Linux execution is not yet verified. Native Windows setup is unsupported; use the Linux setup inside WSL2.

`make build-android`, `make build-ios`, and `make build-windows` are reserved commands that currently
fail with setup guidance. They do not claim to produce builds. SDKs, templates, signing where needed,
export presets, and real-device testing remain future work. Mac exports are not notarized for public distribution.

The project-local editor is in `.tools/Godot.app`. Import `project.godot` to edit the game.
The opening screen in `scripts/title_screen.gd` plays a repeating CC0 retro music cue.
Music provenance, adaptation details, and the Storyboarding brief are in `audio/title-music.json`.
The original recording and previous synthesized sting source are preserved under `audio/sources/`.

[Open all weapon sound auditions](drain-damage-all-weapon-auditions.html) from the repository root.
The self-contained page preserves every audition for later comparison. Prototype 97 uses T11 Water gush for Tony
and S1 Suction pop for Sean, as selected by Sean; the original sources and all 34 WAVs remain under `audio/sources/`.

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

## Install build dependencies

After cloning, run:

```sh
make install INSTALL_FLAGS=--system
make build
```

If Make is missing, invoke the same installer directly:

```sh
bash tools/install.sh --system
```

The installer detects macOS or Linux and x86_64 or ARM64. It installs the pinned Godot 4.7.2 editor and matching
host export templates under ignored `.tools/`, verifies SHA-256 digests from `tools/godot-lock.json`, and fetches
unresolved Git LFS assets. Matching tools are reused; conflicting local tools are preserved and reported.
It does not launch the game. Python 3.10+, Git, Git LFS and Make are required; the Python helpers need no pip packages.

`--system` permits installation of missing prerequisites through an existing Homebrew, apt, dnf or pacman.
Package-manager authentication and confirmation still apply. Without that flag, missing system prerequisites cause
a clear failure and an exact setup command; plain `make install` installs only project-local tools and assets.
On macOS, first install Apple's Command Line Tools with `xcode-select --install` if absent. If Homebrew is needed
but missing, install it from [Homebrew's website](https://brew.sh), then rerun setup. These first-time system
installers are not silently run by the project. Git must already be available to clone the repository.

Use `make install-plan` for a read-only plan or `make install-check` for a read-only readiness check. Their direct
equivalents are `bash tools/install.sh --dry-run` and `bash tools/install.sh --check`.

macOS setup supplies `.tools/Godot.app` and `.tools/macos.zip` for the existing build. Linux setup supplies
`.tools/godot` and host templates for development; it does not add a Linux export preset. Native Windows/MSYS and
other architectures fail explicitly; WSL2 can use the Linux path. Android/iOS SDKs and signing are outside this
desktop bootstrap. Only macOS standalone export is currently configured.

Configured-Mac and offline regression checks cover this installer. A complete fresh-machine installation,
Linux execution, package-manager installation and WSL2 remain unverified. The tracked
`licenses/GODOT_COPYRIGHT.txt` is copied into each exported Mac app. `make build` itself does not download tools.

## Creative direction

- Solo play as Tony or Sean, with distinct weapons and a robot owner bossing both around.
- Cheerful SNES-inspired presentation, original characters and environments, adult language.
- Forgiving combat, quick retries, and readable attacks.
- Next milestone: playtest the integrated first mission, Skitterling fight, character selection and weapon balance.

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

Prototype 62 adds Sputtervalve metal hit variants and a distinct pressure-collapse death sound.
Both gameplay routes use bounded SFX voices with per-enemy hit cooldowns; music mute remains independent.
Headless event/lifecycle checks pass; subjective listening and mix balance remain pending.

Prototype 63 makes the Hallowed Widow repeat its proximity-driven dive, rise and one-second upper pause,
then turn toward the hero before the next approach. Both heroes and routes have repeated-cycle checks.
The current seven-creature catalog has canonical hit/death audio references. Five ordinary enemies and the Skitterling
mini-boss use them; Clogfather remains planned with profile-ready cues.
Export validation requires both cues for every new creature and checks assets, hashes and bounded playback settings.
Live fairness, listening and screenshots remain pending.

Prototype 64 extends Normal with 30 mixed later encounter opportunities and a two-threat local admission target.
Warnings count toward pacing; the six-body safety cap and existing attack budgets remain. Safe placements use existing
prop tops and floor effects, later runners hop low obstacles, and expired encounters are bypassed without kill credit.
The opening and complete Easy/Hard plans match their previous outputs across 100 seeds. Full-level checks pass for both
heroes. That iteration reduced late accumulation but left the first continuation lighter than the opening.
Prototype 65 addresses that measured gap; checkpoint respite is retained.

Prototype 65 chooses supported shooter homes with clearance at the end of their warning, moves the first later emerger
to earlier safe floor, and permits three committed threats in the first continuation before returning to two thereafter.
The global six-body ceiling, warning durations and checkpoint grace are unchanged. With visible swarms counted, six-run
means in the first continuation are 1.74 for forward-fire bots and 1.91 for synthetic combat bots, near the opening
reference of 1.79–2.01. The finale remains controlled at about 1.46. The obstacle corridor is lighter at 1.22–1.43;
these measurements do not prove uniform density or human fairness. Full-level playtest and screenshots remain pending.

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

## Version and release handoff

`application/config/version` in `project.godot` is the canonical `X.Y.Z` version. The main title and gameplay show
it as a small white-on-dark badge at the lower right, inside a 16-pixel inset. Controls and employee selection omit
it; dialogue, death, pause, and dispenser overlays can cover it. The current layout targets the 960×540 logical
canvas. Device-specific mobile safe areas remain untested.

`make build` synchronizes both macOS export version fields before exporting. After changing the project version,
run `python3 tools/sync_project_version.py`; use `--check` to reject drift. Direct editor exports must follow that
step too. Packaged validation compares the displayed project version with the app bundle metadata.

For a future explicit release request, the release-coordination chat collects readiness from Marketing (current
lore magazine), Bestiary / Art, Game Mechanics, Audio (level music, weapons, intended dialogue sound), and
Storyboarding (plot implementation, names, and backgrounds). Engineering integrates approved deliveries, records
remaining gaps, builds the supported targets, and verifies the packages. A normal prototype build is not a release
request and does not authorize a full platform release or release-binary upload.

### Platform readiness

- **macOS:** 0.91.0 universal development/demo ZIP for Apple Silicon and Intel; ad-hoc signed, not notarized.
  Automated extracted-package checks and standalone headless startup are recorded in the release manifest.
  Sean confirmed 0.81.0 opened on a fresh Apple Silicon Mac with macOS 26.6.2 after Open Anyway; that evidence
  applies only to 0.81.0. Fresh-machine 0.91.0, Intel, minimum-OS and live graphics/input/audio review remain pending.
- **Windows:** matching export template, x86_64 preset, EXE/PCK ZIP, and optional signing. No preset or Windows
  runtime test yet. Verify controls, audio, installation, and antivirus behavior on Windows.
- **Linux:** matching template, chosen x86_64/ARM64 preset, executable permissions, and archive. No preset or Linux
  runtime test yet. Validate the target distribution, graphics, input, and audio.
- **Android:** Android template, SDK/JDK, ARM64 preset, private signing key, and APK. No mobile build yet.
  APK sideload instructions and actual Android device testing are required.
- **iOS:** iOS template, macOS/Xcode, ARM64 export, Apple team/provisioning/signing. No mobile build yet.
  Choose Xcode development install, Ad Hoc, or TestFlight; device registration and account limits apply.

For mobile readiness, assess touch controls, alternative screen layouts, aspect ratios, cutouts/safe areas,
orientation, suspend/resume, audio interruptions, controller reconnects, performance, memory, and battery use.
Successful export is not evidence that a platform has been played or tested.

### Release packages and Git LFS

Continue using ignored `builds/Prototype-NN/` and `builds/history/` for everyday local builds. For an explicitly
requested release, prepare `dist/vX.Y.Z/<platform>-<architecture>/` with packaged binaries, installation notes,
checksums, source commit, tool/template versions, signing status, and actual test evidence. Keep the source folder
and uncompressed app bundles out of `dist`; package the Mac app as ZIP or DMG to preserve its metadata.

Release binaries must be tracked through Git LFS and pushed to the public repository when Sean requests a release.
GitHub Release downloads may supplement that storage, not replace it. Verify `git check-attr filter` for every
package, run `git lfs fsck`, and verify remote download hashes after pushing. Never include signing keys, credentials,
provisioning profiles, or private references. Existing ignore rules still exclude tools, local builds, and secrets.

Git LFS is installed and release binaries are stored through it. The October 20, 2026 read-only billing request
returned HTTP 404 with insufficient account scope, so remaining quota is unknown. No authentication scopes,
budget settings or paid overages were enabled. Binary versions and downloads can consume storage and bandwidth;
check account billing before future distribution changes. See
[GitHub LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs) and
[LFS file limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage).
