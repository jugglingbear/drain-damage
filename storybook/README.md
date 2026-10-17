# Global Plumbing Initiative: the making-of storybook

From the first plunger to whatever happens next. Each chapter preserves a playable iteration's real screenshots,
what it could do, and the rough edges that made it a work in progress.

## 001 — First day on the job

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 01 / 0.1.0 / Godot 4.7.2 / standalone macOS app with Apple Silicon support

Sean's plumbing career begins as a handful of colored rectangles in a basement. Three toilets have developed
an attitude, Tony is supervising through commentary, and the company motto is already on the wall:
“No job too shitty.”

![Sean and three hopping toilets in the first basement room](001-first-day/01-service-bay.jpg)

### What came to life

- Running and variable-height jumping, with two platforms to try.
- A plunger launcher and three hopping toilets that take three hits each.
- Five health points, temporary damage protection, and unlimited retries.
- Synthesized sound effects, Tony's commentary, pause, restart, and a victory screen.
- A standalone Mac app that was tested through the victory condition.

### Still wonderfully rough

The characters are tiny procedural placeholder shapes. This is one fixed room, with no scrolling mission or boss yet.
Tony appears through text; his character artwork and story appearances are still ahead.

### Screenshot notes

Captured from the running exported Mac app after the first prototype was completed. This is an unedited game-window
capture, including the macOS window title bar. Earlier development steps were not archived as separate images.

## 002 — A little more reach, a better grip

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 02 / 0.2.0 / Godot 4.7.2 / standalone macOS app

The first playtest found that the ledges asked too much of an otherwise satisfying jump, and firing with J or X
cramped Sean's operator. The jump physics stay the same; the platforms now sit lower and closer together.
Enter/Return takes over as the main keyboard fire key.

![Iteration 02: reachable ledges and revised keyboard and controller hints](002-better-controls/01-room.jpg)

### New capabilities

- More forgiving platform placement, verified by complete simulated jumps onto both ledges.
- Enter/Return and keypad Enter fire plungers; J and X remain available.
- Xbox-style controller mappings: left stick/D-pad to move, A to jump, X/right trigger to fire.
- Menu/Start pauses, Y restarts, and disconnecting a controller pauses the game.
- Stick and trigger deadzones reject small accidental inputs.

![Victory reached using Enter to fire in the exported Mac app](002-better-controls/02-enter-victory.jpg)

### Validation and remaining work

Enter firing was also verified through victory in the exported app.
Automated checks cover ledge reachability, keyboard firing, controller button/axis mappings, deadzones,
and disconnect handling. These are simulated input checks; a real Xbox controller still needs a hands-on playtest.
The artwork remains the original placeholder style, with no scrolling level or boss yet.

## 003 — The crew gets a face

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 03 / 0.3.0 / Godot 4.7.2 / standalone macOS app

The visual pass starts early. Tony and Sean now have illustrated dialogue portraits, original work outfits,
and four expressions each. Tony ranges from professional confidence to exasperation and shouting;
Sean ranges from eager optimism to bewilderment, full panic, and sheepish relief.

![Tony explains the rules of the trade](003-portraits/01-tony.jpg)

![Sean confidently misunderstands the assignment](003-portraits/02-sean.jpg)

![Sean discovers that the toilet has ambitions](003-portraits/03-panic.jpg)

### New capabilities

- Large illustrated portraits over a dimmed game world, with speaker names and character-specific accent colors.
- Six-line opening conversation and a two-line victory exchange.
- Text reveal, advance, skip, and replay using keyboard or controller bindings.
- Frozen gameplay during dialogue, with a short input guard before returning control.

### Art direction and validation

Generated with built-in imagegen from the supplied likeness references. Source atlases and exact prompts are preserved
in `assets/portraits/`. The dialogue layout takes inspiration from the supplied example without copying its artwork.
Automated gameplay and dialogue checks pass; keyboard advancement and skipping were visually checked in the exported
app.
New dialogue controls still need a physical controller playtest. The world and player sprites remain placeholders;
more detailed pixel sprites and environment art are the next visual work alongside the scrolling level.

## 004 — Tony runs apprentice induction

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 04 / 0.4.0 / Godot 4.7.2 / standalone macOS app

The basement becomes a tutorial. Tony introduces one action at a time through portrait dialogue, then disappears
while Sean tries it. Lessons complete through actions, not timers. The controls strip and floating jump labels are gone.

![Tony introduces movement and the yellow marker](004-guided-basement/01-movement-lesson.jpg)

![Tony introduces the plunger launcher](004-guided-basement/02-shooting-lesson.jpg)

![The camera follows Sean into the practice area](004-guided-basement/03-scrolling-practice.jpg)

![Tony explains the activated checkpoint](004-guided-basement/05-checkpoint-instructions.jpg)

![Sean reaches the end of training](004-guided-basement/06-training-finished.jpg)

### New capabilities

- A scrolling basement with movement, platform landing, firing, combined practice, checkpoint, and exit stages.
- Portrait instructions adapt to keyboard or controller input, with optional current-lesson reminders.
- Visible shutters separate lesson areas; each completed action opens the next section.
- Maintenance cabinet restores health and becomes the return point after defeat for the current run.
- Full tutorial skip opens the route while keeping combat, checkpoint, and exit functional.
- Health stays visible; no permanent controls banner interrupts the game world.

### Validation and remaining work

Gameplay, dialogue, and tutorial checks pass, including checkpoint recovery and skip behavior.
The exported Mac app was played through from movement instruction to the exit conversation using the keyboard.
Physical-controller playtesting of this new lesson flow remains for Sean. World and sprite artwork remain placeholders;
there is no boss or progress saved across app launches yet.

## 005 — Less talk, more toilets

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 05 / 0.5.0 / Godot 4.7.2 / standalone macOS app

Sean's feedback reshapes induction: Tony gives one short controls briefing and lets the apprentice get on with it.
The game launches maximized. The toilets now roam farther, hop faster, and chase nearby apprentices.

![Tony gives a brief controller introduction](005-less-talk-more-toilets/01-short-briefing.jpg)

![Keyboard controls in the same short briefing](005-less-talk-more-toilets/02-keyboard-briefing.jpg)

![A roaming toilet closes in on Sean](005-less-talk-more-toilets/04-gameplay.jpg)

### New capabilities

- Immediately visible opening briefing, with keyboard or controller instructions.
- Free exploration without walking, jumping, shooting, or checkpoint dialogue interruptions.
- Wider toilet patrols and faster movement, with local pursuit when Sean approaches.
- Large launch window while preserving the game's aspect ratio.
- Five health points, damage protection, and automatic checkpoint recovery retain forgiving play.

### Validation and remaining work

Gameplay, dialogue, and tutorial regression checks pass, including patrol bounds and pursuit.
The exported Mac app was visually checked for window size, briefing layout, movement, and enemy contact damage.
The physical controller remains available for Sean's playtest of the updated pacing.
World and player artwork remain placeholders, with no boss or saved progress across launches yet.
Markdown lint tooling was unavailable locally; document whitespace and line widths were checked directly.

## 006 — The basement gets its first pixel-art pass

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 06 / 0.6.0 / Godot 4.7.2 / standalone macOS app

The art milestone moves ahead of the first boss mission. Flat wall blocks become a detailed boiler basement with
brickwork, copper pipes, gauges, warm lamps, and layers that scroll at different speeds.
Sean gets an animated pixel sprite, and the toilets become angry porcelain creatures with little pipe feet.
The first Sean sheet incorrectly added side hair and a moustache. Sean caught it, and the integrated revision has a
completely bald head and a chin-only beard. The rejected sheet is not bundled in the game.

![The first pixel-art basement with Sean and a toilet enemy](006-first-pixel-art/01-basement.jpg)

![Sean after clearing the first encounter](006-first-pixel-art/02-combat.jpg)

![The maintenance area with its own sign and first-aid cabinet](006-first-pixel-art/03-maintenance.jpg)

### New capabilities

- Original generated background and transparent sprite atlases, integrated into the actual running game.
- Sean idle, four running poses, jump, fire, and hurt poses; mirrored correctly when facing left.
- Toilet walking, hopping, and hit poses, plus grounded shadows and updated plunger projectiles.
- Layered scrolling, decorative water drips, detailed platform edges, and distinct area signs.
- The company slogan appears only at the entrance.
- Art rendering is separated from movement and combat, preserving the existing collision geometry and controls.

### Validation and remaining work

Movement/combat, dialogue, and tutorial regression checks pass. The exported Mac app was checked for sprite scale,
left/right facing, combat, scrolling, and checkpoint-area readability. Its local code signature verifies.
Original screenshots above were captured from the game window. Earlier chapters are preserved.
This is the first art pass: animation transitions, foreground props, effects, and visual consistency
need further polish.
Tony's in-world sprite, defeat animation, boss mission, music, and saved progress remain future work.

Art was generated with the built-in image tool. Sources are in `assets/world/` and `assets/sprites/`;
exact prompts are in `assets/art-prompts-v1.json` and `assets/sean-correction-v2.json`.
Markdown lint tooling remains unavailable locally; whitespace and line widths were checked directly.

## 007 — A larger, steadier Sean

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 07 / 0.7.0 / Godot 4.7.2 / standalone macOS app

Sean was too small, and an animation crop caused a visible vertical offset. The generated sheet was not a perfectly
uniform grid: the jump crop included a neighboring pose's boot. Explicit pose boundaries now isolate each character.
Sean is 72 logical pixels tall instead of 50, a 44% increase, while retaining his bald head and chin-only beard.

![Larger Sean at the entrance](007-larger-steady-sean/01-larger-sean.jpg)

![Sean standing on the first platform after jumping](007-larger-steady-sean/02-jump.jpg)

### Changes and validation

- Corrected jump and firing crops; running poses stay within two logical pixels of the standing height.
- Kept the forgiving collision size and movement physics; moved the shot origin to match the enlarged launcher.
- Sprite-alignment regression checks and existing gameplay, dialogue, and tutorial checks pass.
- Exported app checked for character size and platform landing; local code signature verifies.

The animation is still an initial small pose set, so smoother transitions and additional frames remain future polish.
Markdown lint tooling remains unavailable locally; document whitespace and line widths were checked directly.

## 008 — Stop the apprentice leaking

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 08 / 0.8.0 / Godot 4.7.2 / standalone macOS app

Sean proposes a more appropriate healthcare plan: plumber's tape. The first-aid cabinet becomes a large tape roll
with a loose white tail and an amber rim that turns green when activated. The label changes to LEAK SEALED.
Tony explains the logic in the existing short briefing, without adding another interruption.

![Tony explains apprentice leak prevention](008-stop-the-leaks/01-briefing.jpg)

![The tape checkpoint is activated](008-stop-the-leaks/02-tape-checkpoint.jpg)

### Changes and validation

- Plumber's tape replaces the first-aid cabinet artwork and wording.
- Existing full-health restoration and checkpoint respawn remain intact.
- Checkpoint and tutorial regression checks pass; exported briefing and activated tape were visually checked.
- The local app signature verifies. Roadmap and player documentation reflect the change.

The tape is currently a stationary checkpoint, not a carryable consumable or wrapping animation.
Markdown lint tooling remains unavailable locally; document whitespace and line widths were checked directly.

## 009 — Press Start, call a plumber

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 09 / 0.9.0 / Godot 4.7.2 / standalone macOS app

The opening screen moves ahead of the boss mission. Tony poses like an action hero, Sean panics with his plunger
launcher, and a giant toilet looms over both. Chunky pixel lettering, drifting sparkles, rotating silly slogans,
and an original synthesized chiptune sting give the game a nostalgic introduction.

![Original opening screen with Tony and Sean](009-press-start/01-title.jpg)

![Start leads into the existing playable basement](009-press-start/02-gameplay.jpg)

### Changes and validation

- Enter/Space or controller A/Menu starts the game and preserves Tony's short briefing.
- M/controller Y toggles title sound; Q/controller B returns to the title from pause or job completion.
- Automated title lifecycle, keyboard/controller binding, tutorial, dialogue, gameplay, and sprite checks pass.
- Exported app visually checked in a small agent-test window; local code signature verifies.
- Normal launches remain maximized for Sean's playtests. Earlier chapters are preserved.

The illustrated giant toilet is title art, not an implemented boss. The sting is not a full soundtrack.
The mute setting lasts only for the current session. New title controller bindings have automated coverage;
physical-controller confirmation remains part of Sean's playtest. No source commit exists yet.
Original artwork was created with built-in imagegen; source and prompt are saved in `assets/title/`.
Markdown lint tooling remains unavailable locally; whitespace and line widths were checked directly.

## 010 — Choose your employee

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 10 / 0.10.0 / Godot 4.7.2 / standalone macOS app

Tony and Sean are both playable. The confident fourth-generation plumber gets a fast pressure gun;
the idiot apprentice gets a heavy, slow plunger cannon. S.U.M.P., a CRT-faced robot company owner,
orders either employee into the basement. The working name means Supervisory Utility Management Processor.

### Changes and validation

- Press Start opens employee selection, with portraits, weapon stats, strengths, and weaknesses.
- Tony fires for 1 damage every 0.16 seconds; Sean fires for 3 damage every 0.60 seconds.
- Both retain the same forgiving movement and health. Restart and respawn preserve the employee choice.
- Tony has an original eight-pose sprite atlas; S.U.M.P. uses original code-drawn artwork.
- Title/selection, weapon cadence and damage, respawn, sprite alignment, and existing regression checks pass.
- The standalone macOS export succeeds and its local code signature verifies. No source commit exists yet.

The initial locked-Mac capture gap was resolved later on October 13. The exported build was checked in a small
agent-only window: selection, Tony's launch, S.U.M.P.'s briefing, gameplay, and return to title.
Physical-controller playtesting remains pending until Sean returns to the MacBook.

![Choose Tony or Sean under S.U.M.P.'s supervision](010-choose-your-employee/01-selection.jpg)

![S.U.M.P. briefs its employee](010-choose-your-employee/02-sump-briefing.jpg)

![Tony in the playable basement](010-choose-your-employee/03-tony-gameplay.jpg)

This is the first weapon-balance pass. S.U.M.P.'s name and design are provisional. There is no AI companion or co-op;
the unselected employee does not follow the player. Boss combat and the full mission remain future work.
Tony's sprite was made with built-in imagegen; the exact prompt is in `assets/sprites/tony-prompt-v1.json`.
Markdown lint tooling remains unavailable locally; document whitespace and line widths were checked directly.

## 011 — Tony’s experience

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 11 / 0.10.1 / Godot 4.7.2 / standalone macOS app

Tony’s selection line now reads “Fourth-generation plumber. Limitless experience.”
It spans two lines to fit the card and emphasizes his expertise with a warmer tone.
The exported build was visually checked in a small agent-only window. Gameplay remains unchanged.

![Tony’s updated description](011-tonys-experience/01-selection.jpg)

![Representative gameplay from this build](011-tonys-experience/02-gameplay.jpg)

Earlier captures remain intact. Weapon balancing and mission development remain pending.
Markdown lint tooling is unavailable locally; whitespace and line widths were checked directly.

## 012 — Less reading, more plumbing

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 12 / 0.12.0 / Godot 4.7.2 / standalone macOS app

The title keeps its artwork and logo, with only Start, Controls, and Quit. Original keyboard and generic
Xbox-compatible gamepad diagrams explain every assigned action in one dedicated screen with two pages.
Button hints elsewhere and the tutorial are removed. Selecting an employee starts the basement immediately.

![Simplified title](012-clean-title-and-controls/01-title.jpg)

![Keyboard reference](012-clean-title-and-controls/02-keyboard.jpg)

![Gamepad reference](012-clean-title-and-controls/03-gamepad.jpg)

![Immediate basement gameplay](012-clean-title-and-controls/04-basement.jpg)

Six automated suites pass: movement/combat, crew, dialogue, basement progression, title navigation, and sprite
alignment. macOS export and signature verification pass. Screens were checked in a small agent-only window.
The basement still contains three toilets. Expanded encounters, acid hazards, and the Clogfather await Storyboarding.
No new physical-controller playtest was requested. Markdown lint tooling is unavailable; whitespace was checked.

Twelve SNES opening/title images were inspected in the
[reference collection](https://www.fandomspot.com/snes-best-title-screens/): F-Zero, Plok, Super Tennis,
Battletoads in Battlemaniacs, Pilotwings, The Lost Vikings, Mortal Kombat II, Mega Man X, Super Mario Kart,
Star Fox, A Link to the Past, and Super Mario World. Most show a logo, artwork, copyright, and at most a short
prompt or small menu. Some captures precede the menu animation. None provide a full control guide.
Reference artwork was not imported into the game.

## 013 — First names only

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 13 / 0.12.1 / Godot 4.7.2 / standalone macOS app

Selection cards and dialogue now use Tony and Sean only. The separate full-name field was removed so both
screens use the same first-name source. This convention is recorded in the project instructions.

**Capture gap:** Screenshots await permission for a visual session. The game was not opened or foregrounded.
Earlier screenshots remain historical records. Preserve this build until selection and gameplay captures can be added.

## 014 — Metadata-driven combat and visible damage

**Date:** October 13, 2026 (America/Los_Angeles)

**Build:** Prototype 14 / 0.14.0 / Godot 4.7.2 / standalone macOS app

Canonical per-weapon and per-monster JSON now generates a validated exportable runtime bundle. Tony's pressure gun
uses 6 damage every 0.15 seconds and a 500-pixel range. Sean's plunger uses 40 damage every second
and a 650-pixel range.
Flushfiends have 40 HP. Player health and movement remain unchanged while the proposed player balance is unresolved.

Every hit flashes and emits particles, even without crossing a damage threshold. Five living damage stages lead to
a nonlooping four-frame death. Remains fall to the floor and hold the last frame. Health bars are continuous and hidden
by default, with a session-only toggle in Controls. Source artwork is preserved; runtime alpha cutoff and measured
Flushfiend row crops prevent haze and neighboring-row bleed. All poses share a scale rather than resizing individually.

Sean explicitly approved this small-window visual session. The preview and exported gameplay were inspected and closed.

![Six damage stages at two scales](014-metadata-and-damage/01-damage-preview.jpg)

![Optional health bars in Controls](014-metadata-and-damage/02-health-bar-option.jpg)

![First-name-only employee selection and updated cadence](014-metadata-and-damage/03-selection.jpg)

![Damaged Flushfiend during actual gameplay](014-metadata-and-damage/04-damaged-flushfiend.jpg)

![Grounded rubble with health bars hidden](014-metadata-and-damage/05-settled-rubble.jpg)

Seven Godot regression suites and three Python validation tests pass. Checks cover ownership and unsupported weapons,
missing IDs, invalid types/ranges, exact HP boundaries, repeated hits, death completion, reset, swept collisions,
solid platforms, travel-distance limits, and atlas loading. Export/signature checks pass; the exported package was
checked from outside the source directory to verify runtime JSON inclusion and marketing-art exclusion.
Deliberate invalid-ID/ownership cases log errors. Headless combat/crew tests also report an AudioStreamGeneratorPlayback
shutdown reference warning; assertions pass, and no gameplay crash was observed. Markdown lint tooling is unavailable;
changed documents were checked for whitespace and line width.

Still pending: four additional weapon mechanics, loadout UI, new weapon-art attachment, Widow flight gameplay, and
further small-scale readability polish. The Widow's 80 HP and damage/death animations are preview-only; wing gutters
and thorax alignment remain provisional. Boss gameplay and expanded basement flow are separate work.
Prototype 13 remains preserved in `builds/history/Prototype-13.app` for its deferred historical captures.

## 015 — Opening-screen music

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 15 / 0.15.0 / Godot 4.7.2

The brief from Storyboarding calls for cheerful professional confidence with trouble underneath: energetic retro
rhythm, warmth for Tony and Sean, and playful instrumentation. The first stock cue is “Face The Facts” by Zane Little
Music, released under CC0. It replaces the short synthesized sting and repeats throughout the opening menus and
employee selection. Gameplay stops it; returning to the title restarts it unless muted.

The source WAV, license/source metadata, adaptation recipe, and earlier sting code are preserved in `audio/`.
The full cue retains its ending before repeating; it is not a verified seamless musical loop. Custom character motifs,
level and boss music, voice acting, and subjective listening approval remain pending.

Headless title lifecycle tests pass, including repeat configuration, mute, gameplay stop, and return playback.
Audio decodes successfully with a measured peak of -1 dBFS. macOS export and signature verification pass.
Godot reports sandbox-related certificate, log, and editor-settings warnings. Markdown lint is unavailable;
changed prose received whitespace and width checks.

**Capture gap:** No game window was opened because this request did not authorize a foreground playtest.
Title and representative gameplay screenshots remain pending in `015-title-music/`; no earlier images were reused.
The exported Prototype 15 build is preserved in `builds/history/Prototype-15.app` for later capture.

## 016 — Hero at the door, Hallow in the basement

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 16 / 0.16.0 / Godot 4.7.2 / standalone macOS app

Sean's chosen songs now accompany the opening and first level: “It Takes A Hero” and “Hallow Quest” (16-bit),
both by Zane Little Music (CC0). A single music voice fades between tracks. Hero plays its full ending before
repeating; Hallow uses its authored loop. Music mute follows the player, pause suspends playback, restart continues
level music, and return-to-title restores Hero. Dialogue reduces the music level. Effects remain independent.

**October 14 capture follow-up:** Sean explicitly approved a small preview. Original window-only captures now show
Prototype 16's title and basement, plus the current development damage preview. The preview shows airborne death
fragments and settled remains for both creatures. Living stages remain within their columns; Widow anchors remain
provisional. These still images do not validate the brief hit flash in motion. No new boss encounter is shown.
Both preview and game windows were closed afterward. No player interaction was requested.

![Prototype 16 title](016-hero-and-hallow/03-title.png)

![Prototype 16 basement](016-hero-and-hallow/04-basement.png)

![Development preview: death fragments](016-hero-and-hallow/01-damage-review.png)

![Development preview: settled remains](016-hero-and-hallow/02-damage-review.png)

Prototype 16 is preserved in `builds/history/Prototype-16.zip`; Prototype 15 also remains archived.
Original source files and the previous Face The Facts cue are unchanged. Artwork and gameplay visuals are unchanged.

Headless checks cover track identity/duration, gain, fade sequencing, mute, pause, restart, return, title repeat,
rapid transition cancellation, and cleanup. Source and runtime hashes match the Audio handoff.
Export inclusion is checked from outside the project directory. Subjective listening remains pending.

## October 14 art update awaiting a game capture

Sean's approved, modestly slimmer proportions now appear in the current title illustration and all four dialogue
portraits. The magazine cover and player page use the same direction. Gameplay sprites remain unchanged.
Versioned originals and exact generation prompts are preserved in `assets/sean-proportions-v3.json`.

**Validation:** Headless title-screen and dialogue checks passed. The magazine cover and Sean page were rendered
and visually checked. Source changes target the existing 0.17.0 development configuration; no new export is claimed.

**Capture gap:** No game window was opened because current permission to foreground it has not been granted.
A fresh title and dialogue capture is pending. Existing exported builds and original screenshots remain intact.
Generated illustrations and PDF renders are not presented as running-game screenshots.

## 018 — Drain Damage and expressive employees

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 18 / 0.18.0 / Godot 4.7.2 / standalone macOS app

Integrated the updated Drain Damage title illustration and dripping menu plates. Dialogue and character selection
now use Tony v3 (navy work shirt), Sean v4 (bare bald scalp), and BJ v2 (beige server rack). Each has ten expressions.
All current dialogue lines carry semantic emotions: Tony's closing joke is skeptical, Sean's is worried,
and BJ's response is neutral. Existing dialogue wording is preserved. BJ replaces the old S.U.M.P. display name.

Integer-boundary slicing and clipped atlas filtering replace the old four-cell crops. Tests cover all thirty
portraits, both employee endings, menus, dialogue lifecycle, music, movement, combat, and metadata.
macOS export/signature checks and an isolated exported-game check pass. Markdown lint is unavailable;
changed prose passed whitespace and width checks.
A sporadic existing ObjectDB cleanup warning appears in headless combat testing; functional assertions pass.
Prototype 17 was an intermediate source-art configuration, not a delivered export.

**Capture gap:** No game window was opened in this iteration. Permission is needed for fresh title, selection,
dialogue, and gameplay captures. Earlier screenshots remain intact and are not reused as evidence of this build.
The build is preserved in `builds/history/Prototype-18.zip`. Final portrait framing and readability remain unreviewed
in-game. Gameplay sprites and monster behavior are unchanged; marketing art and future story scenes remain separate.

## 019 — Meet Billy-Joe

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 19 / 0.19.0 / Godot 4.7.2 / standalone macOS app

The approved seven-line opening introduces BJ, Tony, Sean, and the tire iron after character selection.
Each line has its specified emotional tone. Both character routes share this scene, and the selected hero remains
selected. The scene plays once per fresh run; death, checkpoint respawn, and retry do not replay it.
A binding-aware Skip hint stays visible during dialogue. Action freezes, and held dismissal inputs cannot fire/jump.
The existing ending is unchanged. This introduction contains no movement or combat tutorial.

Headless checks pass for both heroes, skip/completion parity, fresh-run replay, death/checkpoint/retry behavior,
current keyboard/controller hints, held-input protection, portraits, dialogue, title, and music.
macOS export and signature checks pass; the full opening checks also pass against the isolated exported game.
Markdown lint is unavailable; changed prose passed whitespace and width checks.
The pre-existing intermittent headless ObjectDB cleanup warning remains; functional assertions pass.

**Capture gap:** No permission for an interrupting visual session was granted with this task, so no window was opened.
Fresh opening and gameplay captures are pending in `019-meet-bj/`; original screenshots remain intact.
The export is archived in `builds/history/Prototype-19.zip` for later visual review.

## 020 — A field guide with fingerprints

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 20 / 0.20.1 / Godot 4.7.2 / standalone macOS app

The Controls pages now use original worn keyboard and rounded, unbranded controller illustrations with grime,
rust and plumber's tape. Four prominent action cards sit beside the hardware. Smaller job, menu, and conversation
cards replace the old wall of mixed-device instructions. Music and enemy-bar settings have separate clickable
footer buttons. Existing gameplay mappings remain unchanged.

Reference research used the Alien: Isolation manual and EA's F1 25 keyboard guide for diagram/legend structure.
No artwork from those sources was copied. Exact prompts, source links, and image dimensions are preserved in
`assets/controls/art-v1.json`; the unused second controller variation is retained alongside the selected original.

**Validation:** Headless tests cover primary label widths, texture dimensions, separate setting hit areas,
and keyboard/controller navigation and toggles. Menu regression checks pass. Existing intermittent Godot
headless cleanup warnings may occur after passing assertions. Markdown lint is unavailable; text hygiene checked.

**Approved visual review:** Sean authorized a small preview. Both Controls pages were checked for readable text,
spacing, and original hardware artwork; fresh window-only captures are below. Keyboard setting shortcuts worked.
The mouse check exposed unreliable click handling; using the event position now passes headless mouse-event tests.
The artwork/layout is unchanged by that 0.20.1 correction; another live mouse check remains pending.

![Keyboard field guide](020-controls-field-guide/01-keyboard.png)

![Gamepad field guide](020-controls-field-guide/02-gamepad.png)

**Capture gap:** Representative gameplay was not captured during this controls-focused review. The preview tool
briefly reopened the app at normal large size during a close check; it was closed immediately. No test window remains.
The captured 0.20.0 build is in `builds/history/Prototype-20.zip`; the final input correction is preserved in
`builds/history/Prototype-20.1.zip`. Earlier screenshots and generated originals remain intact.

## 021 — Extra sharp controls

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 21 / 0.21.0 / Godot 4.7.2 / standalone macOS app

The conventional controller illustration becomes an original Swiss-cheese device with a golden rind,
cheese holes, dark controls, and clear colored face-button letters. No downloaded controller artwork is used.
The keyboard, action cards, and input mappings are unchanged. Earlier controller illustrations are preserved.
The exact generation prompt and dimensions are in `assets/controls/art-v1.json`.

**Validation:** macOS export/signature and packaged controls checks pass. Existing audio-resource cleanup
warnings still appear after passing checks. Markdown lint is unavailable; changed text hygiene was checked.

**Capture gap:** No new game window was opened. Fresh Controls and representative gameplay screenshots await
permission; this folder reserves the chapter. The build is preserved in `builds/history/Prototype-21.zip`.
The generated asset is artwork, not a screenshot of the running game.

## 022 — Salvage Special

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 22 / 0.22.0 / Godot 4.7.2 / standalone macOS app

Sean and Bestiary / Art selected the Salvage Special: blue PVC and black rubber grips, copper straps,
and metal washers. A generated derivative corrects the View icon and requests transparent background,
while preserving the approved design. Originals and exact prompts remain under `assets/controls/`.
Controls and layout are unchanged. The cheese design remains preserved as an earlier iteration.

**Validation:** macOS export/signature and packaged-controls checks pass. Existing audio-resource cleanup
warnings appear after passing assertions. Live readability at 315 × 210 remains pending visual review.

**Capture gap:** No game window was opened. Controls and representative gameplay screenshots await permission.
The build is archived in `builds/history/Prototype-22.zip`; generated artwork is not a running-build screenshot.

## 023 — Employee files

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 23 / 0.23.0 / Godot 4.7.2 / standalone macOS app

One clipboard with stacked sheets replaces the two stat-heavy cards. Left/right selects Tony or Sean;
each profile shows its portrait, approved biography and high-level traits. BJ has the approved introduction
and concrete basement remark. Numeric firing rates and the old slogan-like selection copy are removed.

Tony now moves at 270 pixels/second with four contact-hit health; Sean retains 235 and five.
Checkpoint healing, restart and death recovery use each employee’s maximum; HUD slots match it.
Weapon balance is unchanged: Tony’s pressure gun fires faster, Sean’s plunger hits harder.
This is initial tuning, not a final balance claim.

**Validation:** Headless selection and character/checkpoint checks pass; opening/skip regression is checked.
Live appearance, readability and gameplay balance remain unreviewed. No game window was opened.

**Capture gap:** Controls, selection and representative gameplay screenshots await permission.
The export is preserved in `builds/history/Prototype-23.zip` for later capture.

## 024 — Punching in

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 24 / 0.24.0 / Godot 4.7.2 / standalone macOS app

Clock In moves off the clipboard onto a separate code-drawn punch-clock panel with a paper timecard,
slot and high-contrast button. Tony (1/2) is now the default on launch and whenever selection opens.
Keyboard/controller confirmation remains unchanged; the mouse uses the visible button’s rectangle.

**Validation:** Packaged selection tests check Tony’s default, reopening selection after choosing Sean,
and non-overlapping clipboard/button bounds, alongside existing character and new-game checks.
The panel is a simple code-drawn illustration; live visual review remains pending.

**Capture gap:** No game window was opened. Fresh selection and gameplay screenshots await permission.
The build is archived in `builds/history/Prototype-24.zip` for later capture.

## 025 — Checking in after the job

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 25 / 0.25.0 / Godot 4.7.2 / standalone macOS app

Both plumbers now have approved seven-line completion conversations. Tony checks on Sean; Sean asks for a
breather. The nonselected plumber is labeled radio support. Every line has an explicit emotional tone,
using existing portraits. BJ’s next address is narrative setup, not a playable next level.

**Validation:** Both routes are tested for full advancement, skipping, emotional portrait validation,
radio designation, repeated completion protection and retry/title behavior. Existing input guards remain.

**Capture gap:** No game window was opened. Fresh dialogue and gameplay screenshots await permission.
The build is archived in `builds/history/Prototype-25.zip`. No new artwork was needed.

## 026 — No invisible leash

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 26 / 0.26.0 / Godot 4.7.2 / standalone macOS app

Toilets keep chasing once they detect the player, even beyond their spawn patrol and off camera.
Movement stops six pixels away without overshoot. Surviving enemies retain aggro across checkpoint respawn;
death and restart clear it. Pursuit parameters are validated and bundled from canonical monster metadata.

Tony’s pressure gun retains damage 6 and interval 0.15s, with range 320 logical pixels.
Sean’s heavy plunger now deals 24 every 1.0s with range 480. Toilets take seven Tony hits or two Sean hits.
Range remains measured from the muzzle, independent of camera and window size. Boss timing needs later tuning.

**Validation:** Metadata tests, persistent pursuit/reversal/patrol/reset tests, hit counts and exact range caps
pass. Existing swept collision, out-of-range rejection and solid-platform tests pass. Godot reports an existing
shutdown object-leak warning; negative metadata tests deliberately emit rejection errors.

**Capture gap:** No game window was opened. Gameplay captures and balance playtesting await permission.
Build preserved at `builds/history/Prototype-26.zip`. No new artwork was needed.

**Prototype 26 distribution note:** A friend-playtest ZIP now includes the unchanged standalone app and
`START HERE.txt` under `builds/share/Drain-Damage-0.26.0-macOS.zip`. Both arm64 and x86_64 executables are
present; Intel hardware and another Mac’s first-launch experience remain untested. No new game iteration
or screenshot is claimed for this packaging-only change.

## 027 — The first full route

**Date:** October 14, 2026 (America/Los_Angeles)

**Build:** Prototype 27 / 0.27.0 / Godot 4.7.2 / standalone macOS app

The basement expands to six zones across 9,600 pixels, with 30 finite Flushfiends and three tape checkpoints.
Art’s 17 grounded props provide solid sides and reachable tops. Visible shutters open after their encounters;
no gate closes behind the player. Shared geometry blocks players, enemies and projectiles consistently.

Reinforcements flash harmlessly for 1.25 seconds, with safe visible positions rechecked before activation.
Forward placement is preferred; warned rear arrivals prevent gate-camping softlocks. Warnings and enemies
share a cap of four. The finale has two finite toilet waves (3+2), not the deferred Clogfather boss.
Existing approved dialogue and music are retained. New zone backgrounds, hazards and portal remain deferred.

**Validation:** Both plumbers complete scripted full-route runs using real movement and weapons.
Tony: 93.75 seconds, no damage. Sean: 139.73 seconds, damage by zone 0/4/8/6/9/1, including respawns.
These are automated runs, not human playtest timings; the proposed 4–6 minute duration remains unverified.
Tests also cover actual pursuit across all props both ways, gate camping, warning cancellation, checkpoint
recovery, descending shots, finite counts, menus and dialogue. Existing shutdown object-leak warnings remain.
Final coordinates and limitations are recorded in `handoffs/first-call-integration.json`.

**Approved visual follow-up:** Captured the exported build in a small window, then closed it.
Tony defaults to employee 1/2, the separate Clock In button is clear, and the entry pipe bundles align
with their standing surfaces. Reinforcement warnings and toilets pursuing over the props were observed.
This was a partial visual check: later machinery, shutters and the finale still need live review.
The preserved build is `builds/history/Prototype-27.zip`; automated completion is not full visual validation.

![Tony selected with a separate punch-clock button](027-first-call-route/01-selection.png)

![Service entry with grounded pipe bundles](027-first-call-route/02-service-entry.png)

![Opening-area pursuit during the preview](027-first-call-route/03-pipe-bundle-encounter.png)

## 028 — Aim high, enter quietly

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 28 / 0.28.0 / Godot 4.7.2 / standalone macOS app

The starter weapons now read directional permissions from their metadata. W/Up aims instead of jumping;
Space/controller A jumps. Both starters support upward diagonals and airborne downward fire. Diagonal
projectiles are normalized, swept collision works on both axes, and original damage/range limits remain.
Flushfiends enter fully outside the camera after encounter triggers, immediately walk toward the player,
and retain proximity-latched pursuit. Full sprite bounds are checked before entry, including backtracking.
Finite counts persist across checkpoint respawn and reset on restart.

**Validation:** Aim permissions, eight directions, range caps, vertical collision, offscreen bounds,
entry motion, trigger persistence/reset, all seven encounter waves, and existing controller/combat checks pass.
Both heroes complete the route using real weapons and movement in scripted runs (not human pacing tests).
Known Godot shutdown object-leak and sandbox certificate diagnostics remain.

**Presentation limitation:** Existing hero sprites still hold weapons horizontally. Art was consulted;
modular character/weapon layers are recommended for the larger roster. Directional poses remain unfinished.

**Capture gap:** No game window was opened for this iteration. Screenshots await explicit permission.
Preserve `builds/history/Prototype-28.zip` for later capture; earlier screenshots do not represent this build.

**October 15 playtest refresh:** All six agents confirmed no additional approved runtime changes.
Rebuilt Prototype 28 from current sources and verified the exported package: aiming/entrances, both complete
routes, keyboard/controller controls, music and dialogue. This is a rebuild of the same game iteration,
not a new visual milestone. No game window was opened; the capture gap remains. Fresh package preserved at
`builds/history/Prototype-28-refresh-2026-10-15.zip`, with checksum in the dated playtest handoff record.

## 029 — Drain Damage on the label

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 29 / 0.29.0 / Godot 4.7.2

The HUD and current build/help labels use Drain Damage. Service-entry signage drops the old company
initials; employee paperwork says STAFF. The employer name remains undecided. The current exported app
is `builds/Drain Damage.app`; earlier builds, screenshots and stable bundle identity remain intact.

**Capture gap:** No game window opened. New screenshots await explicit permission; preserve
`builds/history/Prototype-29.zip` for later capture. This is a text/packaging change, not new gameplay art.

## 030 — A proper punch clock

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 30 / 0.30.0 / Godot 4.7.2

Art’s illustrated teal mechanical clock, paper timecard and brass button replace the code-drawn selection prop.
The supplied crop preserves aspect ratio; CLOCK IN is centered over the brass face and its click target follows
that face. Tony remains the default; keyboard and controller confirmation remain unchanged.

**Capture gap:** No game window opened. Source artwork was inspected, but live appearance and screenshots
await permission. Build preserved at `builds/history/Prototype-30.zip` for later capture.

## 031 — Employee snapshots

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 31 / 0.31.0 / Godot 4.7.2

Selection portraits now share Art’s taped instant-photo border, muted photo backdrop and live first-name
caption. The entire assembly tilts together and stays inside the left column. The shared helper accepts
any selectable hero’s portrait and name; dialogue portraits and combat sprites remain unchanged.

**Capture gap:** Source art preview inspected; no game window opened. Live screenshots await permission.
Preserve `builds/history/Prototype-31.zip` for later capture. Bounds and selection regressions checked headlessly.

## 032 — Meet Billy-Joe

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 32 / 0.32.0 / Godot 4.7.2

Storyboarding’s revised seven-line opening introduces Billy-Joe, Tony and Sean before the basement job.
Every line retains an emotional portrait tone. Text wraps inside the dialogue panel; the final direction is
“Head on down” because the entrance does not establish a visible door. Both routes, skip/advance behavior,
held-input guards and unchanged completion scenes pass headless checks. Persistent visible aiming is unfinished.

**Capture gap:** No game window opened. Screenshots await permission; the build is preserved at
`builds/history/Prototype-32.zip` for later capture.

## 033 — Hold your aim, take a break

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 33 / 0.33.0 / Godot 4.7.2

Both plumbers now use Art’s layered standing and airborne aiming holds. Held direction selects the pose
independently of firing, with matching mirrored muzzle positions and landing restrictions. These provisional
holds replace the older walk/fire frames; walking and recoil animation cycles still need work.

Pause now offers Resume and Return to Main Menu buttons. Keyboard, controller and mouse paths are checked,
including release guards and title music. Flushfiends brake for 0.35 seconds, wait 0.65 seconds, then accelerate
for 0.20 seconds toward the player. Repeated crossings do not restart that timer. Both heroes complete all
30 enemies in automated level runs; this does not substitute for human pacing or visual review.

**Capture gap:** Art’s static composition preview was inspected; no game window opened. Actual game screenshots
await permission. Preserve `builds/history/Prototype-33.zip` for later capture.

## 034 — Employee checklists

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 34 / 0.34.0 / Godot 4.7.2

Tony and Sean’s traits appear as three separate checked-box lines on their employee files. Traits are now
stored as lists, and the same renderer formats future profiles with wrapped rows below their biographies.
Existing portraits and clipboard art are unchanged.

**Capture gap:** No game window opened. Actual screenshots await permission; preserve
`builds/history/Prototype-34.zip` for later capture.

## 035 — Plumbers in motion, three chances

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 35 / 0.35.0 / Godot 4.7.2

Art’s six-frame run cycles and separate takeoff, rise, apex, fall, landing and hurt poses now replace the
static moving bodies. Body motion advances independently of aim/fire; arm, weapon and muzzle attachment offsets
follow each body frame. Grounded diagonal-down shots are allowed; only straight down requires a jump.

Three total lives appear as selected-hero heads. A fatal hit consumes one life, disables control and plays a
nonlooping fall/ground-impact/settle sequence. Surviving lives respawn at the checkpoint with protection;
zero lives opens Game Over with deliberate Retry or Return to Main Menu. Enemy/checkpoint progress persists
between lives. Retry begins a fresh run. The Controls reference no longer offers the old single-button reset.

**Checks:** 240 animation/aim/fire combinations, all six run frames, mirrored muzzles, landing restrictions,
three-life lifecycle, death lock, pause, retry and input safety pass headlessly. Tony completes the automated
full route; the Sean bot exhausts three lives partway through. Sean difficulty remains a playtest issue.
Generated stride silhouettes and shoulder attachment still need visual polish; no dedicated recoil cycle exists.

**Capture gap:** Art’s static assembly preview was inspected. No game window opened; actual screenshots await
permission. Preserve `builds/history/Prototype-35.zip` for later capture.

## 036 — Mainframe Plumbing & Supply

**Date:** October 15, 2026 (America/Los_Angeles)

**Build:** Prototype 36 / 0.36.0 / Godot 4.7.2

The employer’s working name appears in employee selection, BJ’s introduction, Controls and entrance signage.
Drain Damage remains the game title, and Discharge Quarterly remains the magazine. Historical artwork and
provenance are preserved. No unselected game-over dialogue was added.

**Capture gap:** No game window opened. Actual screenshots await permission; preserve
`builds/history/Prototype-36.zip` for later capture.

## 037 — BJ handles the paperwork

**Date:** October 15, 2026

**Build:** Prototype 37 / 0.37.0 / Godot 4.7.2

Both heroes receive a death popup after their animation settles. Twelve approved BJ quips select matching emotional
portraits, remain stable while open, and avoid immediate repeats. Continue preserves checkpoint and enemy progress;
Game Over offers a fresh Retry. Main Menu is available in either case. Held-action protection prevents accidental dismissal.
Art approved reuse of the existing dark panel and portraits. Packaged popup, hero lifecycle, opening and pause-menu checks passed; export and signing succeeded.
Headless logs retain sandbox log/settings/certificate warnings and exit-resource warnings; live visual review is pending.

**Capture gap:** No game window opened. Actual screenshots await permission; preserve
`builds/history/Prototype-37.zip` for later capture. Existing Sean full-route difficulty concerns remain unresolved.

## 038 — Doors going down

**Date:** October 15, 2026

**Build:** Prototype 38 / 0.38.0 / Godot 4.7.2

Service shutters descend into the floor over 0.9 seconds after their existing encounter-clear requirement.
The original shutter artwork is cropped as it descends, keeping its proportions. Player and projectile collision
follow the remaining visible panel. Pause freezes motion; checkpoint recovery preserves it; a fresh run resets it.
Running-shot collision now includes the visible projectile thickness, using the same sweep against walls and enemies.
Art approved retaining the existing sprite registration. All six run frames, both heroes and both facings passed
504 geometry cases and 24 actual combat hits. High airborne enemies can still legitimately clear horizontal shots.
Packaged door, running-shot, aiming, animation, death and checkpoint checks passed. Export and signing succeeded.
Headless checks retain sandbox log/certificate and exit-resource warnings; live visual review is pending.

**Capture gap:** No game window opened. Actual screenshots await permission; preserve
`builds/history/Prototype-38.zip` for later capture. Earlier gameplay balance concerns remain open.

## 039 — Uninvited plumbing inspectors

**Date:** October 16, 2026

**Build:** Prototype 39 / 0.39.0 / Godot 4.7.2

Two optional sewer-fly swarms wander through the first level without hunting. Each has one 12 HP core,
shared contact cooldowns per target, a nonlooping death and checkpoint persistence. Their incidental monster
kills count toward the existing doors without giving player weapon-kill credit. Art corrected the source slicing
with animation-v3.json, retaining the v2 PNG and its fixed center/scale. Peripheral flies are decorative.

Twenty seeded one-minute corner/door simulations and focused combat/lifecycle checks pass. Tony completes the
full-route bot run; Sean exhausts lives in the fourth section, matching the earlier unresolved difficulty concern.
The proposed name Drain Brains and backstory await approval. No six-stage damage art, future weapon support,
or playable boss interaction is claimed. Export/signing, seven metadata tests, and packaged swarm, aiming, door,
death and checkpoint checks passed. Headless logs retain sandbox log/certificate and exit-resource warnings.
The isolated introduction sits after the first cleared encounter, with the next wave delayed until beyond it.

**Capture gap:** No game window opened. Visual readability, motion and contact fairness await permission to inspect.
Preserve `builds/history/Prototype-39.zip` for later screenshots; no static art preview is claimed as a game capture.

## 040 — Bigger clouds of trouble

**Date:** October 16, 2026

**Build:** Prototype 40 / 0.40.0 / Godot 4.7.2

Sewer-fly swarms display at twice their previous width and height, including their death animation.
The shared center stays fixed; optional health bars move above the larger cloud. The 16-pixel contact core,
movement and combat balance stay unchanged. BJ’s approved completion-line revision is included with his neutral portrait.
The Spare Employee Dispenser remains pending artwork and is not part of this build. Export/signing and packaged swarm/completion checks passed.

**Capture gap:** No game window opened. Actual screenshots and size/readability review await permission.
Preserve `builds/history/Prototype-40.zip` for later capture. Sean’s full-route difficulty concern remains open.

## 041 — Please collect your replacement

**Date:** October 16, 2026

**Build:** Prototype 41 / 0.41.0 / Godot 4.7.2

The Spare Employee Dispenser replaces the tape checkpoint. Injured heroes are scanned, grabbed and cartoon-compressed,
then thrown toward the screen for a bloody X-eyed SPLAT and downward slide. A separate trail fades as a replacement
emerges, looks around and shrugs. Art’s authored poses, shared anchors and foreground opening trim drive the sequence;
Audio’s event cues include the revised wet impact and slide. No life is consumed and BJ stays silent.

Full check-in targets 5.5 seconds with a 7-second watchdog. Healthy check-in stamps in 0.4 seconds; checkpoint recovery
uses dispense-only in 1.9 seconds. First injured use plays fully; later uses accept a fresh skip input. Combat freezes
without catch-up, and every exit clears effects/audio. Saved progress and hero identity remain intact.
Sean’s fuller chin beard and soul patch now use Art’s revised gameplay, death and modular aiming sheets.

Export/signing and eleven packaged suites pass, including timing, cleanup, inputs, checkpoints and both hero animations.
Tony’s full-route bot completes in 134.2 seconds; Sean still exhausts lives in section four (13 cleared).
Seven Python metadata checks also pass. Headless logs retain sandbox log/certificate and exit-resource warnings.
Visual alignment/hand reach, emergence composition and audio mix remain unreviewed in a running window.

**Capture gap:** No game window opened. Preserve `builds/history/Prototype-41.zip` for later actual screenshots.
Earlier captures and source art are unchanged; headless checks are not visual approval.

## 042 — Cancel means back, moving doors and surprise splats — October 16, 2026

**Build:** Prototype 42 / 0.42.0.

B now closes ordinary pause regardless of the focused button. A confirms the selected option; death/Game Over remain
separate. Resume guards prevent that B press from skipping dialogue or a dispenser sequence. Controls text is updated.

Audio’s original latch, motor and end-stop cues follow each door’s actual movement transitions. Pausing/freezing suspends
voices; restart/menu exit clears them; restored open gates stay silent. Dispenser throws now sample one safe impact point
with an independent cosmetic RNG. Full transformed artwork bounds, maximum scale and HUD clearance determine the region;
the throw, splat and slide share that point. Tiny viewports scale the effect to fit before sampling.

Export/signing and six packaged suites pass: pause menu, door audio, dispenser, death popup, opening and restart guards.
Impact bounds cover both heroes, 100 seeds and all four extremes across four viewport sizes. No new art was generated.
Live visual/audio review remains pending, as does the existing Sean section-four automated route balance issue.
Headless checks retain sandbox log/certificate and exit-resource warnings; no script errors occurred.

**Capture gap:** No game window opened; permission is required. Preserve `builds/history/Prototype-42.zip` for later
actual game screenshots. This entry does not claim visual approval or substitute source artwork for screenshots.

## 043 — The flies have something to say — October 16, 2026

**Build:** Prototype 43 / 0.43.0.

Audio’s original two-second synthesized fly loop now fades with living-swarm proximity. A single aggregate voice caps
volume at -8 dB player gain; repeated frames do not restart it. Pause/dialogue/dispenser freezes suspend the voice;
death, restart and menu exit clean it up. The existing Master SFX route honors mute; music mute remains music-only.
Menu-navigation candidates remain audition-only pending Sean’s choice.

Export/signing and four packaged suites pass: swarm audio, pause menu, door audio and dispenser. Listening/mix review
remains pending, along with the existing Sean section-four route balance issue. Sandbox log/certificate and exit-resource
warnings persist; no script errors occurred. Markdown linter is unavailable; changed-file hygiene was checked.

**Capture gap:** No game window opened. Preserve `builds/history/Prototype-43.zip` for later actual screenshots.
The new capability is audio; no visual change or visual approval is claimed.

## 044 — A busier opening and a pipe full of bad decisions — October 16, 2026

**Build:** Prototype 44 / 0.44.0.

Opening Trial is a separate main-menu choice with twenty active seconds, both heroes, faster trial-only weapons,
supported decks, runners, a perched shooter, a warned floor emerger and fly-through spiders. Results freeze the trial
and report actual issued enemies, kills, active threats, deferrals, damage, shots and misses. Unsafe rear entries no
longer block the whole schedule. The normal campaign retains its existing balance and progression.

Art’s wastewater cutaway now runs beneath the first level. Rightward water and debris give way to lower water and
increasing grease buildup, ending in a motionless full clog. World-position sampling preserves backtracking; the trial
uses the early profile. No collision or damage is added. Art rejected the replacement hero run cycles for continuity
and registration issues, so current animations remain; the running defect is still open.

Export/signing, nine Python tests and eleven packaged suites pass. Invulnerable moving observations issue 11/12 enemies
for Tony and 10/12 for Sean; idle observations issue 6/12. These measure scheduling and caps, not survival fairness.
Pickups and the playable Clogfather are not included. Live visual/audio review and human balance feedback
remain pending.
Sandbox log/certificate/settings and some exit-resource warnings persist; no script errors occurred.

**Capture gap:** No game window opened; fresh permission is required. Preserve `builds/history/Prototype-44.zip` for
later actual screenshots in `storybook/044-opening-trial-and-cutaway/`. Source art and headless drawing checks are not
screenshots or visual approval. Previous entries remain intact.

Sean supplied these actual Prototype 44 captures during playtesting on October 16. They document the unwanted
20-second interruption and low-contrast pipe obstacle; those corrections are underway for the next build.

![User capture of the trial results interruption](044-opening-trial-and-cutaway/01-user-trial-results.png)

![User closeup of a pipe obstacle blending into the background](044-opening-trial-and-cutaway/02-user-obstacle-contrast.png)

## 045 — The opening belongs in the level — October 16, 2026

**Build:** Prototype 45 / 0.45.0.

Sean clarified that twenty seconds described a pacing sample, not a separate timed mode. Start now enters the
continuous first level: the faster mixed encounters and sewer decks replace the first two rooms, then lead into the
existing route without a reset. There is no trial menu, cutoff, timer HUD or results interruption. Later required
encounters, checkpoints, shutters, the remaining swarm and completion conditions are preserved. Safe entry deferrals
never grant kill credit. The faster starter-weapon profile continues throughout the level.

Art supplied worn ivory frames, light steel pipes and distinct landing edges for the plinths and decks. Collision
footprints stay unchanged. Tony’s standing shots previously passed above the trial Flushfiend’s 36-pixel movement box;
projectiles now target the visible 43-pixel body. Muzzle, aim, movement and contact collision are unchanged.

Nine Python tests and ten packaged suites pass. New coverage includes 16 standing-shot cases and 504 existing running
shot checks, a thirty-second scripted run, single projectile travel, boundary/backtracking, checkpoints,
life preservation, later gates and completion conditions. Scripted movement uses invulnerability and is not a full
survival-balance measurement. Running animations remain unchanged after Art rejected the replacement candidates.
The actual Clogfather encounter is still pending. Environment diagnostics and some shutdown-resource warnings remain;
no script errors occurred in the passing checks.

**Capture gap:** No game window opened. Preserve `builds/history/Prototype-45.zip` for actual screenshots
after permission.
The two user-supplied Prototype 44 captures above document the issues motivating this correction; they are not images
of Prototype 45. Live contrast/composition and human pacing review remain pending.

## 046 — A wrench clink for the menus — October 16, 2026

**Build:** Prototype 46 / 0.46.0.

Sean selected the exact 0.24-second wrench-clink audition. The original CC0 Kenney cue now plays on successful
pre-game directional navigation across the main menu, employee selection and controls pages. Keyboard, D-pad and
accepted stick movements share the behavior. Ineffective directions and repeat/held-input spam do not retrigger it.
One voice avoids stacking; entering gameplay or exiting cleans it up. Existing SFX/Master mute is honored, while the
music toggle remains music-only. Provenance and all earlier auditions remain preserved.

Export/signing and four packaged suites pass: menu audio, title/selection, controls and music lifecycle. Listening and
mix review remain pending. Existing environment and shutdown-resource warnings persist; no script errors occurred.

**Capture gap:** No game window opened. This iteration changes audio, not artwork. Preserve
`builds/history/Prototype-46.zip` for later running-build capture after permission. No screenshot or listening approval
is claimed.

## 047 — Crowds on an open route — October 16, 2026

**Build:** Prototype 47 / 0.47.0.

Sean replaced mandatory kill gates with larger enemy crowds. The first level now permits continuous traversal past
ordinary enemies, retaining scenery collision and checkpoints. Four later finite waves schedule 8, 10, 10 and 8
Flushfiends, with safe offscreen entrances and bounded live populations. Passing a wave never awards fake kills.
The temporary exit is reachable with enemies alive; the actual Clogfather encounter is still pending.

The Hallowed Widow uses twice the previous linear size with matching body targeting and 180 HP. A fixed four-second
hover creates an engagement window without tracking the player or requiring a kill. Tony needs 15 hits and Sean 10
with their current first-level weapons. Enlarged-art readability and human balance remain unreviewed.

Flushfiend defeats use Audio’s ceramic-style shatter, including environmental kills. Ordinary hits retain their tone.
A four-voice pool bounds overlapping sounds and handles pause, mute, restart and exit. Listening review is pending.

**Validation:** Export/signing, nine Python tests and nine packaged suites pass: integrated traversal/waves,
standing shots (16 cases), running shots (504 cases), durable flyer, defeat audio, pause, completion, dispenser and
menu audio. Scripted movement uses invulnerability and does not establish survival balance. Existing environment
and shutdown-resource warnings remain; no script errors occurred in the passing suites.

**Capture gap:** No game window opened. Preserve `builds/history/Prototype-47.zip` for actual screenshots after
permission. No new artwork or running screenshot is claimed.

## 048 — Employees behind glass — October 16, 2026

**Build:** Prototype 48 / 0.48.0.

The missing glass-front dispenser handoff is integrated. Art supplied cabinet, glass and hatch layers around two
sleeping copies of the selected hero. Each occupant is clipped to its own compartment and animates with the gameplay
clock. Existing checkpoint healing, hand/impact gag, emergence and respawn timings remain unchanged; no stock or
restocking mechanic is added. All earlier art remains preserved.

BJ’s dialogue role label now matches his established title. Story reviewed the current dialogue and kept the approved
lines intact. Widow backstory now matches the approved shared lore; this adds no reproduction behavior. The audit
confirmed that the full-route wastewater cutaway and server-rack BJ were already integrated. Marketing portraits
remain marketing assets.

**Validation:** Export/signing, nine Python tests and six packaged suites pass: glass stock/geometry, dispenser
lifecycle, dialogue, completion, wastewater and integrated level. BJ’s longest role label measures 376 of 520 available
pixels. Live composition remains pending. Existing environment and shutdown-resource warnings persist; no script
errors occurred in the passing checks.

**Capture gap:** No game window opened. Preserve `builds/history/Prototype-48.zip` for actual screenshots after
permission. Source-art inspection and geometry checks do not substitute for running-game screenshots.

## 049 — A swoop, steady feet, and clearer platforms — October 16, 2026

**Build:** Prototype 49 / 0.49.0.

The enlarged 180-HP Widow now warns before committing to a captured target position, swoops into the player lane,
and recovers before another attack. Scenery stops its expanded body; the attack does not home after commitment.
Art and Level replaced all twenty raised surfaces with moss-green frames and lighter treads across four families,
preserving geometry. The optional new Widow lunge pose awaits visual registration; current flight art is retained.

Sean’s clone shifted almost a sprite width when looking left because the renderer treated a negative width as a UV
flip, while our code also shifted its left edge. Mirroring now respects the frame anchor, with checks for both heroes,
both facings and emergence/look/shrug poses. The behavior is confirmed in
[Godot’s canvas renderer](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_canvas_cull.cpp).

Both endings now contain nine reciprocal turns with emotional portraits. Headless tests confirm support-radio lines,
typewriter reveal, held-input behavior and the final release guard. The old source already included Sean’s response;
the reported missing turn was not reproduced, so a separate runtime omission is not claimed fixed.

**Validation:** Export/signing, nine Python tests and ten packaged suites pass: durable flyer, dispenser registration,
ending input, completion, dispenser lifecycle, glass stock, integrated traversal, standing shots, running shots and
platform geometry. Existing environment and shutdown-resource warnings persist; no script errors occurred.

**Capture gap:** Daughter’s active playtest remains untouched. No game window opened. The new app will be delivered
separately at `builds/Prototype-49/Drain Damage.app`, preserving the existing default app. Actual screenshots and
human swoop/contrast/animation review await permission; archive `builds/history/Prototype-49.zip` for later capture.

## 050 — Wreckage that stays, preparation before play — October 16, 2026

**Build:** Prototype 50 / 0.50.0.

Sean reported opening Flushfiends disappearing on defeat and a one-time midair freeze near the start. The opening
adapter removed defeated actors after 0.6 seconds, bypassing the later level’s persistent wreckage. Opening runners
now enter the shared corpse list with their position, direction and death animation; cleanup removes only the actor.
Kill credit and shatter sound remain single events. Restart clears wreckage as before.

The first drawn Flushfiend also performed a synchronous pixel-by-pixel damage-atlas cleanup. A headless measurement
found about 237 ms cold versus 0.003 ms cached. Preparation now occurs before gameplay; shared textures and frame data
are reused across restarts and new games. This removes a measured stall source but is not a live confirmation that all
of the reported hitch is gone. GPU first-use behavior is outside headless validation.

**Validation:** Export/signing, nine Python tests and nine packaged suites pass, including both heroes and runner
roles, death-frame progression, retained wreckage beyond four seconds, single kill/audio, reset cleanup, cache reuse,
continuous level traversal, standing/running shots, swoop, pause, completion and title lifecycle. Existing environment
and shutdown-resource warnings remain; no script errors occurred in the passing suites.

**Capture gap:** No game opened or foregrounded. Separate app `builds/Prototype-50/Drain Damage.app` and archive
`builds/history/Prototype-50.zip` preserve this iteration for actual screenshots after permission. Earlier builds and
captures remain intact.

Prototype 50 was rebuilt on request October 16 at `builds/Drain Damage.app`. Signing and the packaged
opening-wreckage/warmup regression check passed. No new visual iteration or screenshot is claimed.

## 051 — One checkpoint and one spare — October 16, 2026

**Build:** Prototype 51 / 0.51.0.

Sean reduced the first level to one checkpoint near the midpoint. Level chose x4650, roughly 49% of the route, to keep
the cabinet clear of the next platform. Extra machines and triggers are gone. Art approved using the existing left
compartment for one sleeping copy of the selected hero and leaving the right compartment empty.

Full-health check-in saves progress without consuming stock. The first replacement consumes the clone when vending
begins; skipping the replacement completes that same single use. Afterward, the cabinet remains empty across deaths
and revisits. Subsequent respawns arrive beside it with no duplicate vending, emerging clone or invented refill.
A new run restores stock. Checkpoint activation and stock are independent; the existing three lives remain unchanged.

**Validation:** Export/signing, nine Python tests and eight packaged suites pass: dispenser lifecycle/stock, glass
slots, integrated traversal, midpoint recovery, clone registration, opening wreckage/warmup, ending input and pause.
Both heroes cover full-health, injured, fresh/held skip, death, empty arrival and new-run reset. Existing environment
and shutdown-resource warnings remain; no script errors occurred in the passing checks.

**Capture gap:** No game opened or foregrounded. Separate app `builds/Prototype-51/Drain Damage.app` and archive
`builds/history/Prototype-51.zip` preserve this iteration for actual screenshots after permission. Earlier apps remain.

## 052 — A flush for the fallen — October 16, 2026

**Build:** Prototype 52 / 0.52.0.

Audio delivered a three-second CC0 toilet-flush recording with preserved source and processing provenance. It plays
once on either hero’s actual death transition, including the final life, replacing the short lethal-hit tone. Ordinary
hits, enemy deaths and the dispenser gag do not trigger it. Manual pause suspends playback; the automatic death popup
and respawn allow it to finish naturally. Title, new run and shutdown clean it up. Audio never gates gameplay timing.

**Validation:** Export/signing, nine Python tests and six packaged suites pass: hero death audio, dispenser,
Flushfiend shatter, pause, completion and integrated level. Natural audio completion is tested with allowance for
headless mixing-clock lag; the file remains exactly three seconds. Both heroes and final-life deaths are covered.
Existing environment and shutdown-resource warnings remain; no script errors occurred in the passing checks.
Listening remains pending.

**Capture gap:** No game or audio audition opened. Separate app `builds/Prototype-52/Drain Damage.app` and archive
`builds/history/Prototype-52.zip` preserve this audio iteration for later running-build capture after permission.

## 053 — Swarms with substance and forward swoops — October 16, 2026

**Build:** Prototype 53 / 0.53.0.

Septic Air Force now uses a 48-pixel contact radius instead of 16, covering most of the visible fly mass.
The same shared bounds apply to shots and scenery. The Hallowed Widow maintains its heading through a V-shaped
attack, climbing forward to its original altitude rather than retracing the dive. It flies straight during cooldown;
obstacles still stop unsafe movement.

**Validation:** macOS export/signing, nine Python tests, and four packaged suites pass: durable flyer, sewer swarm,
integrated opening, and opening death/warmup. Tests cover both flight directions, altitude recovery, contact bounds,
seeded swarm paths, and existing level behavior. Environment/editor-settings and shutdown warnings remain.

**Capture gap:** No game window opened. Visual playtest and actual screenshots await permission. The separate
`builds/Prototype-53/Drain Damage.app` and `builds/history/Prototype-53.zip` preserve this iteration.

## 054 — Know which build is running — October 16, 2026

**Build:** Prototype 54 / 0.54.0.

The title and gameplay now show a small white-on-dark version badge at the lower right, inset 16 pixels.
Controls and selection omit it; gameplay overlays may cover it. The canonical project version drives the label,
and the Makefile synchronizes macOS bundle versions before export. Future release handoffs, platform blockers,
installation/testing evidence, and requested LFS package storage are documented in the project README.

**Validation:** Eleven Python tests and four packaged suites pass: version badge, integrated opening, durable flyer,
and sewer swarm. Version tests cover synchronization/drift rejection, matching title/game text, text fit, and
HUD/menu clearance. The initial safe-inset check caught an eight-pixel bottom margin; it was corrected to 16 and
retested. The exported app reports 0.54.0. Existing environment and shutdown warnings remain.

**Capture gap:** No game opened. Actual visual review and screenshots await permission; the separate app and
`builds/history/Prototype-54.zip` retain this iteration. No release binaries were pushed.

## 055 — The porcelain jaw app icon — October 16, 2026

**Build:** Prototype 55 / 0.55.0.

Sean selected Art's first app-icon concept: a red plunger inside a monstrous porcelain jaw. The original master
and provenance are preserved. Standard and Retina sizes are packaged into ICNS, with project and Mac export icon
settings pointing to the selected artwork. Reproduce the package with `bash tools/build_app_icon.sh` on macOS.

**Validation:** Export/signing and packaged version checks pass. The app's icon matches the generated ICNS
byte-for-byte and the app reports 0.55.0. The sandboxed icon utility initially rejected the icon set; rerunning
with required host access succeeded. No gameplay changes. Finder/Dock visual review remains pending.

**Capture gap:** No game opened. Actual screenshots await permission; the separate Prototype-55 app and archive
preserve this iteration. The concept board is design history, not a running-build screenshot.

## Future chapters

Each delivered iteration gets its own numbered folder, dated entry, and fresh screenshots. Earlier chapters stay intact
so changes to the characters, environments, interface, and gameplay remain visible side by side.
