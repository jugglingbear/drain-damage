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

## 056 — Visible Sputtervalve bolts — October 17, 2026

**Build:** Prototype 56 / 0.56.0; source HEAD `49cc403` plus uncommitted integration changes.

The violet bolt was too small to read in Sean's 0.55 screenshot. Art's existing star now draws on a 64-pixel
canvas instead of 16, with its bright core centered on the projectile trajectory. Decorative rays and sparks
remain harmless; collision radius 4, damage 1, speed 150, cadence and warnings are unchanged. The prepared
three-shooter limit ships here, with six bullets and three patterns still the caps and no added spawn entries.
The separate 1.5× body enlargement and contrast repaint remain unfinished.

**Validation:** Eleven Python tests, five source Godot suites and six packaged suites pass. Coverage includes
both gameplay paths, core registration, radius-edge hits/misses, scenery sweeps, existing shooting cadence,
shooter limits, both-hero continuous traversal, platform geometry, standing shots and version display.
The first export failed because the destination folder did not exist; creating it resolved the failure.
Export/signing pass. Existing editor-settings/log-write permission, macOS environment and resource-shutdown
warnings remain.

**Capture gap:** No game window opened. Actual screenshots and live projectile readability review await permission.
The separate `builds/Prototype-56/Drain Damage.app` and `builds/history/Prototype-56.zip` preserve this iteration.

**Record created:** 2026-10-17T15:12:58-07:00 (`America/Los_Angeles`); this is not a capture time.

[Timestamped capture backlog and archive hash](056-visible-sputtervalve-bolts/20261017-151258-capture-status.json).

## 057 — Gratecrawler keeps to the floor — October 17, 2026

**Build:** Prototype 57 / 0.57.0; source HEAD `49cc403` plus uncommitted integration changes.

The Gratecrawler had inherited the runners' obstacle jump and could land on a step, then jitter at its patrol
boundary because it reversed every physics tick. It now stays on the floor, walking back and forth without
chasing. It turns when heading outward at its patrol limit or when its actual body meets blocking scenery.
Runners keep their existing jump behavior. No new attack, artwork or lore is introduced.

**Validation:** Eleven Python tests and seven packaged Godot suites pass, including both gameplay paths at
60 and 120 Hz, both starting headings and three real grate positions. The tests verify sustained floor patrol,
solid-wall turns and the full 1.45-second warning/emergence/settling delay. An occupied grate remains harmless;
contact damage starts only after safe activation. Existing projectile, traversal, geometry, shooting and
version checks also pass. Export/signing and archive integrity pass; existing environment, permission and
resource-shutdown diagnostics remain. Live motion review is pending.

**Capture gap:** No game window opened. The separate `builds/Prototype-57/Drain Damage.app` and
`builds/history/Prototype-57.zip` preserve this iteration for an approved capture session.

**Record created:** 2026-10-17T15:23:27-07:00 (`America/Los_Angeles`); no image capture occurred.

[Timestamped capture backlog and archive hash](057-gratecrawler-floor-patrol/20261017-152327-capture-status.json).

## 058 — Choose the job’s difficulty — October 17, 2026

**Build:** Prototype 58 / 0.58.0; source HEAD `49cc403` plus uncommitted integrations.

Employee selection now leads to Game Difficulty before the existing introduction. Easy uses a fixed, smaller
encounter plan; Normal varies controlled arrangements; Hard adds tested opening combinations and greater overlap.
Damage, health and attack tells stay the same. Art's muscular, torn-workclothes portraits appear when Hard is selected.
These are selection portraits only; the complete gameplay costumes remain in production.

Death now resets encounters from the active respawn origin. Earlier enemies cannot pursue from behind after a
checkpoint retry. Defeated eligible enemies return at full health, while old shots, corpses, warnings and attack
tokens clear. Remaining-life respawns retain the selected hero, difficulty, run arrangement and consumed clone stock.
The short encounter just after the checkpoint may expire during the protected restart; it is intentionally optional.

**Validation:** Eleven Python tests and thirteen packaged Godot suites pass, including 300 resolved plans,
eighteen scripted mode/hero/seed traversals at 60/120 Hz, input/release guards, crowd admission and genuine
lethal-hit/popup/Continue paths at both origins. Review caught and fixed the old crowd cap and an early death-flush
cutoff; regressions cover both. Export/signing and archive integrity pass. Existing permission/environment and
resource-shutdown diagnostics remain. Invulnerable scripted traversal does not establish human survival balance.

**Capture gap:** No game window opened. Actual menu/readability/fairness review and screenshots await permission.
The separate `builds/Prototype-58/Drain Damage.app` and `builds/history/Prototype-58.zip` preserve this iteration.

**Record created:** 2026-10-17T15:47:12-07:00 (`America/Los_Angeles`); no image capture occurred.

[Timestamped capture backlog and archive hash](058-difficulty-and-encounter-resets/20261017-154712-capture-status.json).

## 059 — More torn workshirts for Hard selection — October 17, 2026

**Build:** Prototype 59 / 0.59.0; source HEAD `49cc403` plus uncommitted integrations.

Sean asked for much heavier shirt damage, with roughly half of each hero's shirt gone. Art's revised Tony and Sean
busts now appear on Hard selection, retaining their identities, colors and Sean's bib straps. Both keep the existing
96×96 header position. Earlier portraits and Prototype 58 remain preserved. Gameplay costumes are still in production;
this iteration changes selection portraits only.

**Validation:** Two Python version tests and two packaged suites pass: difficulty navigation and version display.
The exported screen loads both v2 portraits at their recorded 1254×1254 size. Export/signing, bundle versions and
archive integrity pass. Existing log/editor-settings permission, macOS environment and shutdown diagnostics remain.
The original portrait images were inspected; their live 96-pixel composition remains unreviewed.

**Capture gap:** No game window opened. The separate `builds/Prototype-59/Drain Damage.app` and
`builds/history/Prototype-59.zip` preserve this iteration for an approved capture session.

**Record created:** 2026-10-17T15:58:09-07:00 (`America/Los_Angeles`); no image capture occurred.

[Timestamped capture backlog and archive hash](059-hard-portrait-shirt-revision/20261017-155809-capture-status.json).

## 060 — Hard costumes and louder dialogue — October 17, 2026

**Build:** Prototype 60 / 0.60.0; source HEAD `49cc403` plus uncommitted integrations.

Hard now carries the torn-workclothes treatment through both heroes' movement, aiming, death, HUD heads and dispenser
sequences, including sleeping clones and impact frames. Sean's blue overalls are torn as well as his orange shirt.
Matching emotional portraits cover both speakers, and Tony and Sean speak in uppercase throughout Hard dialogue,
including radio replies. BJ and Easy/Normal retain their authored presentation.

Art corrected motion-row overlap and expanded muscular arm crops while preserving pixel registration. Twelve source
sheets remain intact; approved alpha cleanup is prepared and cached before gameplay. Art's eleven offline composition
pages are preserved separately as asset studies, not gameplay screenshots. Existing animation/shoulder polish and
raised-weapon face occlusion remain limitations.

**Validation:** Eleven packaged suites and two Python version tests pass. Hard animation checks cover 240 combinations;
mode switching, respawn, all costume paths, binary alpha, cache reuse, wrapping and dialogue input also pass.
Export/signing, both bundle versions and ZIP integrity pass. Existing environment and shutdown diagnostics remain.

**Capture gap:** No game window opened. Actual Godot composition and first-load feel remain unreviewed. The separate
`builds/Prototype-60/Drain Damage.app` and `builds/history/Prototype-60.zip` preserve this build for approved capture.

**Record created:** 2026-10-17T16:38:08-07:00 (`America/Los_Angeles`); no image capture occurred.

[Timestamped capture backlog and archive hash](060-hard-costumes-and-dialogue/20261017-163808-capture-status.json).

## 061 — Let the difficulty speak for itself — October 17, 2026

**Build:** Prototype 61 / 0.61.0; source HEAD `49cc403` plus uncommitted integrations.

Sean wanted players to discover the differences between difficulty levels. The explanatory paragraphs and selected
character's portrait/name are removed. Easy, Normal and Hard now sit in a centered stack of the existing menu plates.
The background illustration, heading, prompt, Back and Start Job remain. Gameplay mechanics and costume assets are
unchanged, and earlier builds preserve the former screen.

**Validation:** Three packaged suites pass: both heroes and all difficulties through keyboard/controller/mouse,
release guards, Back navigation, intro entry, menu audio and version display. Two Python version tests, export/signing,
bundle metadata and archive integrity also pass. Existing environment/shutdown diagnostics remain.

**Capture gap:** No game window opened. Live layout review and actual difficulty/gameplay captures await permission.
The separate `builds/Prototype-61/Drain Damage.app` and `builds/history/Prototype-61.zip` preserve this iteration.

**Record created:** 2026-10-17T16:49:20-07:00 (`America/Los_Angeles`); no image capture occurred.

[Timestamped capture backlog and archive hash](061-simple-difficulty-selection/20261017-164920-capture-status.json).

## 062 — Sputtervalve sounds damaged — October 17, 2026

**Build:** Prototype 62 / 0.62.0; source HEAD `49cc403` plus uncommitted integrations.

Sputtervalve now answers nonlethal hits with alternating short metal clanks and gauge rattles. Its defeat has a distinct
collapse and escaping-pressure sound. Audio supplied licensed source recordings, originals and a reproducible recipe;
no firing cue or new creature lore was added. Both projectile paths share the damage hook. Separate bounded pools and
a per-enemy cooldown keep rapid hits controlled, while the terminal cue bypasses that cooldown and plays only once.

**Validation:** Focused source checks, seven packaged suites and two Python version tests pass. Actual hit/death events,
variant alternation, independent cooldowns, excluded contacts, pause/mute separation and reset/disposal cleanup are
covered. Existing hero/Flushfiend audio, projectile collision and opening/respawn regressions pass. PCM source headers,
export/signing, bundle versions and ZIP integrity pass. Godot's existing import compression is retained.

**Capture/listening gap:** No game window opened and no subjective audition occurred. Mix balance and actual gameplay
captures remain pending permission. Earlier builds are preserved; this iteration is stored in
`builds/Prototype-62/Drain Damage.app` and `builds/history/Prototype-62.zip`.

**Record created:** 2026-10-17T17:00:25-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record and archive hash](062-sputtervalve-hit-and-death-audio/20261017-170025-capture-status.json).

## 063 — The Widow circles back and the creatures answer hits — October 17, 2026

**Build:** Prototype 63 / 0.63.0; source HEAD `49cc403` plus uncommitted integrations.

The Hallowed Widow now repeats its attack cycle: approach the nearby hero, dive at the warned position, rise, pause
for one second at the top and choose a direction from the hero's current side. Its committed dive remains dodgeable;
scenery and world bounds still constrain movement. Active Widows remain until defeated or the run resets.

All six registered creature profiles now contain hit and death audio references. Five implemented enemies play them:
Flushfiend, Hallowed Widow, Sewer Flies, Sputtervalve and Gratecrawler. Clogfather has profile-ready cues
but no playable boss encounter; no canonical mini-boss exists. The Widow has a short insect-like hit
and a longer screeching death.
Existing shatter and valve cues remain preserved. Export validation requires both events and rejects missing assets,
bad hashes, invalid playback settings and profiles omitted from the catalog. The standing requirement is in AGENTS.md.

**Validation:** Twelve packaged suites and fifteen Python tests pass. Coverage includes repeated cycles for both heroes
and routes, both directions, pause/death/reset, scenery sweeps, standing shots, swarms and all creature
damage/audio paths.
Bounded pools, per-enemy cooldowns, lethal-only death, mute separation and disposal are checked. Source checks,
export/signing, bundle versions and ZIP integrity pass. Environment and immediate-shutdown diagnostics remain recorded.

**Capture/listening gap:** No game window or audio audition. Human fairness, live composition and mix balance remain
unreviewed. Preserve `builds/Prototype-63/Drain Damage.app` and `builds/history/Prototype-63.zip` for approved capture.

**Record created:** 2026-10-17T17:14:06-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record and archive hash](063-widow-cycles-and-creature-audio/20261017-171406-capture-status.json).

## 064 — A varied route with less late crowding — October 17, 2026

**Build:** Prototype 64 / 0.64.0; source HEAD `49cc403` plus uncommitted integrations.

Normal now uses 30 mixed later encounter opportunities, replacing its 36 runners. Incoming warnings count toward a local
two-threat target, while the separate six-body safety ceiling remains. Shooters use existing prop tops, emergers find
safe floor beyond the predicted landing area, and later runners hop low scenery. An earlier later-Widow opportunity
helps the obstructed middle. The approved opening and all Easy/Hard plans are preserved across 100 seeds.

The first candidate still crowded the finale despite fewer scheduled slots. Measuring actual bodies led to the local
admission target. Counting every distant survivor then made later sections too empty, so local pressure now follows
nearby threats while the global safety ceiling still includes survivors. No enemy is erased to make space.

**Measured limits:** Six synthetic combat runs improve the first continuation from 0.41 to 1.32 visible enemies on
average and reduce the finale from 2.40 to 1.55. These bots stop and synthetically defeat each Widow after four seconds;
they do not establish natural combat balance. Forward-fire bots retain a surviving Widow and produce different results.
The first continuation remains lighter than the opening, so uniform whole-level density is not complete. Further tuning
should examine safe activation delays there. The checkpoint respite remains intentional.

**Validation:** Fourteen packaged suites and fifteen Python tests pass. Coverage includes 18 full-level difficulty, hero
and seed runs, six additional Normal baseline runs, six synthetic combat runs, shared caps, unique Widow admission,
checkpoint ownership/grace, safe homes, fallback accounting, audio, costumes and projectiles. Export/signing, bundle
versions and ZIP integrity pass. Existing environment and immediate-shutdown diagnostics remain in the logs.

**Capture gap:** No game window opened. Actual full-route, mixed-role and finale comparisons await approved capture.
Preserve `builds/Prototype-64/Drain Damage.app` and `builds/history/Prototype-64.zip` for that session.

**Record created:** 2026-10-17T17:44:55-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record, measurements and archive hash](064-normal-route-pacing/20261017-174455-capture-status.json).

## 065 — Safe entrances close the early pacing gap — October 17, 2026

**Build:** Prototype 65 / 0.65.0; source HEAD `49cc403` plus uncommitted integrations.

Prototype 64 reduced late crowding but left the first continuation too light. Tracing each entrance showed a shooter
waiting until the hero passed its perch before safely activating, while other slots expired. Shooter placement now
accounts for the hero's expected position after the unchanged warning and can use farther existing supports. The first
later emerger moves to earlier open floor and prefers a position beyond the predicted landing area.

The first continuation allows three committed nearby threats, then returns to two after x4450. The six-body safety cap,
attack budgets, warnings and checkpoint grace remain unchanged. Passive swarms count toward local pressure when their
visible bounds enter view. They are also included in the final measurements, correcting the earlier proxy's omission.

**Measured outcome:** Six runs per policy put the first continuation at 1.74 visible creatures for forward-fire bots and
1.91 for synthetic combat bots, compared with 0.74/0.67 in Prototype 63 and an opening reference of 1.79–2.01.
Empty-time fractions there fall to 9.1%/5.2% from 47.6%/50.0%. The finale averages about 1.46 instead of 2.18/2.40. The
obstacle corridor remains lighter at 1.22–1.43 and the checkpoint retains respite. These bots are invulnerable; the
controlled policy stops and synthetically kills Widows after four seconds. The results do not establish exact uniformity
or human combat fairness. A full-route playtest remains the next review.

**Validation:** Fourteen packaged suites and fifteen Python tests pass. Both heroes and three seeds reach the exit in
all difficulties and both Normal measurement policies. Tests retain the original opening/Easy/Hard signatures across 100
seeds, check shared caps and unique Widow admission, preserve respawn ownership/grace and stock, and hold occupied
warning markers harmless until cleared. Audio, costumes, projectiles, export/signing, versions and ZIP integrity pass.
Existing environment and immediate-shutdown diagnostics remain recorded.

**Capture gap:** No game window opened. Preserve `builds/Prototype-65/Drain Damage.app` and
`builds/history/Prototype-65.zip` for approved screenshots. Prototype 64 and all earlier chapters remain intact.

**Record created:** 2026-10-17T17:52:33-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record, measurements and archive hash](065-sustained-normal-encounters/20261017-175233-capture-status.json).

## 066 — The difficulty button gets angry — October 17, 2026

**Build:** Prototype 66 / 0.66.0; source HEAD `49cc403` plus uncommitted integrations, isolated UI snapshot.

Sean renamed the Hard choice exactly “The Computer is Cheating!!” and asked for a more angry-looking button. Art
approved reusing the existing salvaged-metal plate: dark oxblood normally, hotter red on hover and a warm rim with
corner marks and an arrow when selected. A quiet charcoal center keeps the cream label readable. The wider button fits
the entire line at the existing 27px font size; the original artwork is preserved.

The internal difficulty remains Hard. Easy and Normal keep their existing labels and geometry, and the screen still has
no difficulty explanations or selected-hero portrait/name. The muscular reveal stays in gameplay. Hover highlights the
new button without selecting or starting a mode; keyboard, controller and click behavior retain their release guards.

**Validation:** Six packaged suites and fifteen Python tests pass. Checks cover exact text/ID, label fit at logical
scales, hover/selected drawing, both heroes and all modes through keyboard/controller/mouse, Back/intro flow, navigation
audio, Hard costumes, encounter/respawn invariants and version display. Export/signing, bundle metadata and archive
integrity pass. Gameplay source hashes match Prototype 65. The isolated snapshot excludes unfinished roach assets and
retains the previous six creature profiles without reverting concurrent Art work.

**Capture gap:** No game window opened. Live appearance, hover/focus readability and actual screenshots remain pending.
Preserve `builds/Prototype-66/Drain Damage.app` and `builds/history/Prototype-66.zip` for an approved capture session.
Earlier chapters and original assets remain intact. Existing environment and immediate-shutdown diagnostics are
recorded.

**Record created:** 2026-10-17T18:06:24-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record, layout checks and archive hash](066-angry-hard-option/20261017-180624-capture-status.json).

## 067 — The angry button returns to its original size — October 17, 2026

**Build:** Prototype 67 / 0.67.0; source HEAD `49cc403` plus uncommitted integrations, isolated UI snapshot.

Sean rejected Prototype 66's wider button and opaque maroon center after reviewing its appearance. This correction
restores the same 375×64 artwork and 355×46 interaction area as Easy and Normal. The center cover is removed so the
original sludge, bolts and metal texture remain visible. Art supplied lighter coral tints for the normal, hovered and
selected states. The exact label “The Computer is Cheating!!” fits at 22px; selection retains its outline and arrow.

Gameplay, title flow and the original menu artwork are byte-identical to Prototype 66. The snapshot retains the previous
six creature profiles and excludes unfinished Skitterling work without reverting concurrent source changes.

**Validation:** Six packaged suites and fifteen Python tests pass, including equal button geometry, label fit/scales,
both heroes/all modes through keyboard/controller/mouse, hover/Back/intro flow, audio, costumes, encounter/respawn
invariants and version. Export/signing, bundle metadata and ZIP integrity pass. Existing environment and shutdown
diagnostics remain recorded.

**Capture gap:** No game window opened. Live color, texture and readability review and actual screenshots remain pending.
Preserve `builds/Prototype-67/Drain Damage.app`, `builds/history/Prototype-67.zip` and all earlier iterations.

**Record created:** 2026-10-17T18:42:11-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record and verification](067-original-size-angry-button/20261017-184211-capture-status.json).

## 068 — Flushfiends climb the next step — October 17, 2026

**Build:** Prototype 68 / 0.68.0; source HEAD `49cc403` plus uncommitted integrations.
Isolated fix atop Prototype 67.

Sean found a Flushfiend frozen against a taller plinth while standing on the lower platform to its right. A regression
reproduced the problem in Prototype 67: the opening and Normal-route runner logic allowed hops only at floor height.
Landing on a platform therefore prevented the next jump. The campaign movement already checked relative step height;
both paths now share grounded-support detection and a collision test of the proposed hop.

Flushfiends can jump again after each landing, ascending successive reachable steps in either direction. They retain
their existing jump strength and physics. Low ceilings and unreachable walls cause a short retreat rather than endless
wall-walking; an unsupported jump apex cannot grant another jump. Prototype 67's menu correction and the difficulty
schedules remain intact. Unfinished Skitterling work is excluded from this isolated delivery.

**Validation:** Eleven packaged suites and fifteen Python tests pass. The regression covers both heroes, runner roles,
opening/later/campaign paths, landings at 380/320/260, both directions, ceilings, tall walls and no midair jump.
Both heroes complete the full route in all three difficulties across three seeds. Collision, crowd budgets, checkpoint,
respawn, menu, costume, audio and version checks pass, as do export/signing, bundle metadata and ZIP integrity.
Existing environment and immediate-shutdown diagnostics remain recorded.

**Follow-up verification:** A second screenshot from 0.66.0 showed two Flushfiends stuck on the taller staircase.
An additional test against the unchanged packaged Prototype 68 uses that actual five-plinth geometry and two active
pursuers. Both land on the 380/320/260 steps and reach the hero on top, for both heroes and both directions. No further
runtime change or rebuild was needed; manual motion review remains pending.

**Capture gap:** No game window opened. Actual staircase behavior and gameplay screenshots remain pending. Preserve
`builds/Prototype-68/Drain Damage.app`, `builds/history/Prototype-68.zip` and all earlier iterations for comparison.

**Record created:** 2026-10-17T18:48:18-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record, cause and verification](068-flushfiend-successive-steps/20261017-184818-capture-status.json).

## 069 — Skitterling takes over a locked room — October 17, 2026

**Build:** Prototype 69 / 0.69.0; source HEAD `49cc403` plus uncommitted integration, isolated snapshot atop Prototype
68.

The first mini-boss now interrupts the service route after the checkpoint. An empty approach leads into a fixed room,
where roaches spill from the rear pipe, shriek and assemble into a rat. Its defeat appears conclusive: the collapse
takes
half a second and the swarm stays still for four seconds. Renewed skittering then gathers into the larger alligator.
The camera remains locked until the fight ends and the player leaves through the opened right pipe.

Both forms have separate guarded 180 HP budgets. Rat overkill cannot skip the second fight. Bites, pipe ambushes and
submerged debris attacks have visible warnings; occupied returns warn again or retreat harmlessly. The boss health bar
retains its damage through transitions while player health and lives remain readable. A checkpoint retry restores the
encounter without refilling the clone dispenser. Final defeat awards one kill.

Art's measured sprites and room props are integrated with cached alpha preparation and continuously crawling authored
roach overlays. Audio supplies bounded insect beds, shriek, warnings, transitions, impacts and final death. The quiet
approach and room replace conflicting platforms and ordinary encounters; the seeded plan definitions remain intact.
The angry menu correction and Flushfiend navigation fix are retained. Earlier builds and source artwork are preserved.

**Validation:** Sixteen packaged suites and sixteen Python tests pass. Eighteen full-route runs cover both heroes, all
three difficulties and three seeds at 60/120 Hz, defeating both forms with actual weapon shots and reaching the exit.
Checks cover phase gates, shared shots, camera and boundaries, pause, mid-fight death, hazards, checkpoint stock/lives,
final audio/kill dispatch, renderer preparation and the existing menu, navigation and crowd rules. Export/signing,
bundle versions and ZIP integrity pass. Existing environment and immediate-shutdown diagnostics remain recorded.

**Capture gap:** No game window opened. Actual gameplay screenshots, animation continuity, sound mix and human combat
fairness remain unreviewed. Preserve `builds/Prototype-69/Drain Damage.app` and `builds/history/Prototype-69.zip` for an
approved session. Source-art studies and headless draw checks are not gameplay captures.

**Record created:** 2026-10-17T20:14:34-07:00 (`America/Los_Angeles`); no image capture occurred.

[Capture record, sequence and verification](069-skitterling-locked-room/20261017-201434-capture-status.json).

## 070 — Additive Septic Air Force — October 17, 2026

**Version:** Prototype 70 / 0.70.0, built from an isolated snapshot atop 69; source HEAD `49cc403` plus local changes.

The first level now has nine swarm encounters instead of one. Three appear through the opening, two across the service
route, one above the pump and three after Skitterling. Eight new slots have their own capacity budget, so adding them
does not replace ordinary monsters or consume their admission slots. The original swarm keeps its placement and seed.

New arrivals remain harmless for 0.8 visible seconds; offscreen time cannot consume that warning. Contact waits longer
if the hero occupies the footprint. Checkpoint retries restore four later slots, and the boss approach and room stay
isolated. Existing artwork, movement, health and audio are retained. Skitterling, the angry menu and the Flushfiend
navigation fix remain in the build.

**Validation:** Seventeen packaged suites and twenty-eight Python tests pass. Eighteen baseline runs saw one swarm;
all eighteen updated runs issued and saw nine, including all three post-boss encounters. Eighteen paired scheduling
comparisons preserved ordinary admission. Contact-enabled bots used test-only healing to complete route coverage;
combined populations peaked at five or six, with at most two added swarms. These measurements do not establish human
survival balance. Checkpoint, visible warnings, boss isolation, geometry, audio bounds and existing regressions pass.
Export/signing, bundle versions and ZIP integrity pass.

**Capture gap:** No game window opened and no screenshots were captured. Human chaos/fairness, listening and visuals
remain pending. Preserve `builds/Prototype-70/Drain Damage.app` and `builds/history/Prototype-70.zip`, alongside 69.

**Record created:** 2026-10-17T20:30:46-07:00 (`America/Los_Angeles`, UTC offset -0700);
no image capture occurred.

[Capture record and measured distribution](070-additive-septic-air-force/20261017-203046-capture-status.json).

## 071 — Walking tunnels and a tougher Skitterling — October 17, 2026

**Version:** Prototype 71 / 0.71.0, isolated snapshot atop 70; source HEAD `49cc403` plus local changes.

The player now walks through lateral entrance and exit tunnels. Authored foreground shells cover the hero naturally;
movement can stop or reverse inside, and the camera blends into the room without a teleport or fade. Entry closes only
after the hero emerges. The right tunnel stays locked until the final defeat, then permits walking and backtracking.
Background and ceiling attack pipes remain unchanged, and the floor still supports the player above the water.

The rat's health increases from 180 to 540: 45 Tony hits or 30 Sean hits, about seven seconds of uninterrupted fire for
either hero. The false death remains intact; the alligator keeps its 180 HP budget, for a guarded 720 HP display. It
now visibly swims beneath the hero, pauses at a committed warning and throws one item vertically upward. Three distinct
nearby origins threaten a stationary hero while leaving moving dodges possible. Each item clears before the next throw.
Afterward, the alligator swims to an emergence point and performs two warned snapping-jaw charges before diving again.

Playtest shortcuts are discoverable with `make run-targets`. `make run LEVEL=1` starts the first level, while
`make run MINIBOSS=skitterling` initializes the checkpoint and places the hero before the real entrance walk. Optional
hero, difficulty and seed selectors work in source and exported games. Invalid or unimplemented destinations fail
clearly. Plain `make run` retains the normal menus; `make run-check` verifies initialization headlessly.

**Validation:** Twenty packaged suites, thirty-two Python tests and sixteen source/exported CLI checks pass. Eighteen
full-route runs retain all nine swarms. Checks cover physical portals, alpha masks, camera continuity, health gates,
three upward hits against a stationary hero, moving dodges, rendered jaw damage, reset/audio and prior regressions.
Bots use test-only healing for full-route coverage; these checks do not establish human survival balance. Export,
signing, versions and ZIP integrity pass.

**Capture gap:** No game window opened. Clean screenshots, animation/camera feel, listening and human balance remain
pending. Preserve `builds/Prototype-71/Drain Damage.app` and `builds/history/Prototype-71.zip` alongside earlier builds.
The separately archived user-provided Prototype 69 screenshot is historical source evidence, not a capture of 71.

**Record created:** 2026-10-17T20:48:29-07:00 (`America/Los_Angeles`, UTC offset -0700);
no image capture occurred.

[Delivery record](071-walking-portals-and-skitterling-revision/20261017-204829-capture-status.json).

## 072 — Cockroaches constitute the body — October 19, 2026

**Version:** Prototype 72 / 0.72.0; source HEAD `6b522a2e4f05bca808065a9b88219228e382fd1f`
plus renderer integration, preserved in an isolated source snapshot.

Skitterling now consists of 600 independently moving authored cockroach sprites. The renderer no longer draws a solid
animal beneath them. Continuous individual motion and staggered leg cycles keep the rat and alligator forms crawling.
Four drawing batches, separate front/body buffers and shared immutable preparation support the composition.
Existing artwork is reused; earlier source sheets and animation studies remain preserved for comparison.

Combat geometry is maintained separately from the decorative insect outline. Engineering checked 64,908 samples against
preserved Prototype 71 across mapped states, 601 times, both facings and two origins, with exact agreement.

**Validation:** Twenty packaged suites and thirty-two Python tests pass, along with export, signing and ZIP integrity.
Existing environment and shutdown warnings remain recorded; final checks report no script, parse or assertion failures.

**Capture gap:** No game window opened and no actual Prototype 72 screenshots were captured. Live appearance, silhouette
readability and real device/GPU performance remain unreviewed. Human balance and listening checks carried over from 71
remain pending. Preserve `builds/Prototype-72/Drain Damage.app`, `builds/history/Prototype-72.zip` and earlier builds.
The archived animation source study is not a gameplay capture.

**Record created:** 2026-10-19T12:32:09-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](072-constituent-roach-animation/20261019-123209-capture-status.json).

**Later visual feedback:** Sean rejected this appearance as brown static. He requested fewer, larger, readable roaches
with visible writhing, smooth pipe entry and exit, and the warning swarm behind the pipe rim. Art owns the renderer
revision; Engineering identified missing front occlusion at individual attack ports. This feedback does not invalidate
the recorded automated checks, which did not establish visual quality. Prototype 72 remains preserved; the next revision
is pending, with no Prototype 73 delivery or new capture claimed.

## 073 — Larger roaches and active attacks — October 19, 2026

**Version:** Prototype 73 / 0.73.0; source HEAD `6b522a2e4f05bca808065a9b88219228e382fd1f`
plus integration, preserved in an isolated source snapshot.

Following Sean's rejection of Prototype 72 as brown static, Skitterling now uses 140 larger authored cockroaches with
new rat and tail pose guides. No solid animal is drawn underneath. Warning insects appear behind pipe rims, and
individual insects converge into or emerge from the openings. Exposed insects can be shot during retreat only.

The encounter adds wall climbing, a committed pounce, accelerating rush, secondary pipe ambush and rear tail sweep.
An airborne rat collapse lands harmlessly within the existing timer; assembly no longer waits indefinitely when its
footprint is occupied. A one-second original synthetic rat-like squeal and insect rasp accompanies the encounter;
it is not a recording of a real animal.

**Validation:** Engineering reports twenty-one packaged suites and thirty-two Python tests passing. Eighteen room
pressure cases cover both heroes, all modes and three positions, recording nine to twelve hits per minute. These tests
pin position, restore health and disable shooting while retaining normal 1.5-second immunity; they do not establish
human dodge fairness. CPU retreat-target queries averaged about 0.49–0.52ms, not a GPU performance result.

All eighteen full-route checks passed after correcting the test driver's zero-gap facing handling. The app was unchanged
and did not require another build; the original diagnostic log remains preserved. Export, signing and ZIP checks pass.

**Capture gap:** No game window opened and no actual Prototype 73 screenshots were captured. Roach readability, pipe
and attack poses, listening/mix, real device GPU performance and human fairness remain pending. Preserve 72 and 73 apps
and ZIPs for an approved comparison. Archived source studies remain distinct from gameplay captures.

**Record created:** 2026-10-19T12:55:06-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](073-readable-roaches-and-active-attacks/20261019-125506-capture-status.json).

## 074 — Clearer silhouettes and a three-shot volley — October 19, 2026

**Version:** Prototype 74 / 0.74.0; source HEAD `6b522a2e4f05bca808065a9b88219228e382fd1f`
plus integration, preserved in an isolated source snapshot.

Sean reported that Prototype 73's roaches obscured the rat and alligator anatomy. Art now fits the 140 insects to thin
features, with smaller aligned edge insects, restrained edge motion and original-resolution crops. There is still no
solid animal underneath. The archived software comparison documents source composition, not accepted gameplay visuals.

Rat health is now 900 and alligator health 540, for 1,440 total: Tony needs 75 plus 45 hits, Sean 50 plus 30.
Pipe flight takes 1.1 seconds; its two-second warning and 0.15-second reveal remain. The midpoint transition shortens
to 1.6 seconds of collapse, 1.2 seconds of renewed skittering and 1.4 seconds of assembly, totaling 4.2 seconds.

A single 0.8-second warning marks and locks three floor targets before a vertical, random-arc and aimed-arc shot.
They launch at 0, 0.22 and 0.44 seconds, with at most three live projectiles. Existing attacks and the synthetic pounce
cue remain. The approved continuous-water follow-up is separate and excluded from this build.

**Validation:** Engineering reports twenty-one packaged suites, thirty-three Python tests and eighteen full-route cases
passing. Eighteen room-pressure cases and both-hero/all-mode volley checks cover stationary hits, moving evasion,
target locking and the three-projectile cap. Controller escape checks sample twelve seeds, three positions and two
hero speeds with reaction delays. Export, signing and ZIP checks pass; automated checks do not establish human balance.

**Capture gap:** No game window opened or actual screenshot was captured. Live silhouette and attack appearance,
listening, human balance and device GPU performance remain pending. Preserve 73 and 74 builds for an approved
comparison.

**Record created:** 2026-10-19T13:14:02-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](074-silhouettes-and-volley-tuning/20261019-131402-capture-status.json).

## 075 — Continuous room water — October 19, 2026

**Version:** Prototype 75 / 0.75.0; source HEAD `6b522a2e4f05bca808065a9b88219228e382fd1f`
plus integration, preserved in an isolated source snapshot.

The room water now flows continuously using the existing authored water crop. A cached mirrored texture replaces
switching crests, moving at 12 pixels per second with small spatial wave displacement across 120 bounded strips.
The room clock controls pause and reset. The water band and swimmer/warning layer order remain unchanged, as do
Prototype 74's health, attacks and timing. No new artwork was needed; health-bar concepts remain proposals.

**Validation:** Engineering reports nine focused packaged suites and thirty-three Python tests passing, plus export,
signing and ZIP checks. Water checks cover sample motion, mirrored joins, band bounds, frozen-clock equality and cache
reuse. Prototype 74's full twenty-one-suite and eighteen-route matrix was not rerun as part of this delivery.

An initial volley test always moved right and could enter a marked random arc. The corrected test uses a deterministic
seed and chooses the clearer marked escape; it passes against the unchanged app. The initial failure remains recorded.

**Capture gap:** No game window opened or actual Prototype 75 screenshot was captured. Water appearance, seams, crests
and GPU performance remain unreviewed; earlier silhouette, human fairness and listening checks remain pending.
Preserve 74 and 75 builds for an approved comparison.

**Record created:** 2026-10-19T13:18:20-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and focused verification](075-continuous-room-water/20261019-131820-capture-status.json).

## 076 — Living Swarm health bar — October 19, 2026

**Version:** Prototype 76 / 0.76.0; preserved app and ZIP with source snapshot designated `builds/source-76`.

Skitterling now uses Sean's selected Living Swarm health-bar design. Authored cockroach rails and endcaps surround an
orange fill and dark track, preserving insect proportions. The frame is static. Health loss crops the fill from right
to left, with the brief damage trail retained. The boss name, player status, phase continuity, death fade and retries
remain intact; other boss bars retain their appearance.

**Validation:** Engineering reports four packaged suites passing: boss HUD, Skitterling integration, portals and build
version. Thirty-three Python tests, export, signing and ZIP checks pass. The source aperture is transparent and the
textures load from the packaged app. These are focused checks, not a newly rerun full gameplay matrix.

**Capture gap:** No game window opened or actual gameplay screenshot was captured. Small cockroach detail at normal HUD
size and live appearance remain unreviewed. Software art previews are not gameplay captures. Preserve Prototype 76
and earlier builds for an approved comparison.

**Record created:** 2026-10-19T13:30:18.823265-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](076-living-swarm-health-bar/20261019-133018-capture-status.json).

## 077 — Contact, six-shot volleys and a larger health bar — October 19, 2026

**Version:** Prototype 77 / 0.77.0; preserved app, ZIP and source snapshot `builds/source-77`.

Visible insects in the formed rat now damage the hero on contact through the shared damage path and normal 1.5-second
immunity. Hidden, assembling and collapsing states remain harmless. The alligator fires six arcs at 0.22-second spacing:
five seeded random floor targets, then a final target sampled when that shot fires. Projectiles do not home afterward.

Actual-contact testing exposed a rush that could block a corner escape. A uniformly scaled low rush pose now stays at
most 50 pixels high through warning, rush and recovery, with matching visible, contact and projectile bounds. Its
committed endpoint stops 48 pixels from the target; stationary heroes still take contact damage.

Sean reported Prototype 76's health-bar insects were unreadable. Living Swarm v2 enlarges the rails from 6 to 18 pixels,
uses larger endcaps and reserves a 110-pixel HUD band. Orange fill and the dark track remain. Prototype 76 is preserved
as the rejected readability iteration; software HUD previews are not gameplay screenshots.

**Validation:** Engineering reports eleven packaged suites and thirty-three Python tests passing, plus export, signing
and archive checks. Twelve actual-contact dodge routes cover both heroes, pounce/rush and left/center/right positions
through recovery; six stationary rush cases still register hits. Eighteen room-pressure cases, firing-time aim,
impact/escape and bounded audio checks pass. Earlier test failures remain in logs; final suites contain no script,
parse or assertion errors. Automated routes do not establish human combat balance.

**Capture gap:** No game window opened or actual Prototype 77 screenshot was captured. Larger-HUD and low-rush visual
acceptance, human balance, listening and GPU performance remain pending. Preserve 76 and 77 for an approved comparison.

**Record created:** 2026-10-19T14:13:01.575103-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](077-contact-volley-and-readable-hud/20261019-141301-capture-status.json).

## 078 — Repairing the stair pocket and styling pause — October 19, 2026

**Version:** Prototype 78 / 0.78.0; preserved app, ZIP and source snapshot `builds/source-78`.

The post-checkpoint Flushfiend stall came from the integrated level geometry: removing the last stair for the quiet
approach left a narrow floor pocket below a wall too tall to climb. Earlier tests restored the full old platform list
and missed this combination. Both heroes and both actor paths reproduced the trap before the repair.

The repaired stairs restore 60-pixel rises without entering the quiet approach. Art approved cropping the existing
pump's right third to preserve scale and its exposed edge; the lower step reuses existing artwork. Legacy platform
records and AI behavior are unchanged. Eight actual-geometry cases at 60 and 120 Hz now climb back toward the hero.

Pause now reuses the industrial main-menu plates with gold focus, a pointer and centered ivory heading. Resume and
Return to Main Menu callbacks, input methods, release guards, pause freezing and death-popup behavior remain intact.
Checkpoint health/replacement clarity is a roadmap proposal only; healing, animation, clones and lives are unchanged.

**Validation:** Engineering reports twelve packaged suites and thirty-three Python tests passing, including eighteen
full-route runs and eight navigation cases. Export, signing and archive checks pass. Final packaged checks contain no
script, parse or assertion failures; existing environment diagnostics remain recorded.

**Capture gap:** No game window opened or actual Prototype 78 screenshot was captured. Live pause-menu readability,
platform crop review and gameplay screenshots remain pending. Preserve 77 and 78 for an approved comparison.

**Record created:** 2026-10-19T14:34:29.223156-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](078-checkpoint-navigation-and-pause/20261019-143429-capture-status.json).

## 079 — Authored rat gait without shrinking — October 19, 2026

**Version:** Prototype 79 / 0.79.0; preserved app, ZIP and source snapshot `builds/source-79`.

Six authored running phases and six full-length crouched sprint phases replace the uniform rush-shrinking workaround
introduced in 77. Whole-body scale remains 1.0. Grounded travel drives one gait cycle per 120 pixels; standing still,
pausing or climbing holds the gait, and reset clears accumulated distance. Warning/recovery posture and fractional gait
transitions share pose selection with visible contact and projectile geometry. Health, speed, acceleration, warnings
and attack timings remain unchanged.

**Validation:** Engineering reports eleven packaged suites and thirty-three Python tests passing. Contact coverage
includes twenty-four starting-phase corner cases across six phases, both heroes and both corners, twelve baseline
pounce/rush routes and six stationary rush-hit cases. Eighteen room-pressure cases and phase, hold, continuity and
source-dimension checks pass, along with export, signing and archive verification.

**Capture gap:** No game window opened or actual Prototype 79 screenshot was captured. Live leg-gait and posture
readability, human balance and GPU performance remain pending. Preserve 78 and 79 for an approved comparison.
The [archived gait study](art-studies/20261019-144349-skitterling-gait/20261019-144550-archive-record.json)
is software source composition, not gameplay or live visual acceptance.

**Record created:** 2026-10-19T14:48:03.713077-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](079-authored-rat-gait/20261019-144803-capture-status.json).

## 080 — Faster charge after landing — October 19, 2026

**Version:** Prototype 80 / 0.80.0; preserved app, ZIP and source snapshot `builds/source-80`.

The alligator now starts its charge one second after actually landing on the floor, instead of 2.9 seconds.
Surface recovery drops from 2.0 to 0.1 seconds, followed by the existing 0.9-second warning. Charge speed, damage,
health, the second-leg warning, water-emergence duration, artwork and audio cues remain unchanged.

**Validation:** Engineering reports six focused packaged suites and thirty-three Python tests passing, plus export,
signing and archive checks. Timing checks at 60 and 120 Hz start from the actual floor-landing boundary, verify no
early movement and exactly one warning, and confirm pause freezes the delay. Full-route and gait-phase matrices were
not rerun for this narrow timing change.

**Capture gap:** No game window opened or actual Prototype 80 screenshot was captured. Live pacing review remains
pending. Preserve 79 and 80 for an approved comparison.

**Record created:** 2026-10-19T14:51:35.184076-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and focused verification](080-faster-alligator-charge/20261019-145135-capture-status.json).

## 081 — Tougher Septic Air Force — October 19, 2026

**Version:** Prototype 81 / 0.81.0; preserved app, ZIP and source snapshot `builds/source-81`.

Septic Air Force health increases from 12 to 24 HP. Both active first-level starter weapons now need two hits:
Tony's first 12-damage shot leaves 12 HP; Sean's first 18-damage shot leaves 6 HP. Other swarm behavior is unchanged.

**Validation:** Engineering reports seven focused packaged suites and thirty-three Python tests passing. Actual shots
from both heroes across all three difficulties verify one nonlethal hit cue and one lethal death cue. Full reset and
checkpoint spawns restore 24 HP. Swarm behavior, scheduling, audio, respawn and version checks pass, as do export,
signing and archive checks. Full-route traversal was not rerun. An initial missing export directory was corrected
before the successful export; final checks contain no script, parse or assertion failures.

**Capture gap:** No game window opened or actual Prototype 81 screenshot was captured. Live balance review remains
pending. Preserve the build and earlier iterations for an approved comparison.

**Record created:** 2026-10-19T14:58:22.063344-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and focused verification](081-tougher-septic-air-force/20261019-145822-capture-status.json).

## 082 — Alligator legs and jaws move independently — October 20, 2026

**Version:** Prototype 82 / 0.82.0; preserved app, ZIP and source snapshot `builds/source-82`.

Six authored alligator leg phases now follow actual charge travel at 96 pixels per cycle. Rest and pause hold the gait.
Upper and lower jaws open, snap and recover independently on a 0.52-second visual cycle. Fixed torso and tail
anchors and seven stable anatomical groups keep the 140 insects from migrating across the body during gait changes.
Four drawing batches remain; health, speed, damage, warnings, attack events and legacy combat geometry are preserved.

The source study retains an earlier rejected thin composition and the approved v3 before the final stable v4.
Art approved v4's sampled shoulder/hip joins, continuous abdomen and tail, and separate jaws and feet. This approval
covers software composition, not live gameplay motion.

**Validation:** Engineering reports thirteen packaged suites and thirty-three Python tests passing, plus export,
signing and archive checks. Phase selection, fractional gait wrap, transition continuity and pause/reset checks pass.
Ninety-second controller comparisons at 60 and 120 Hz match Prototype 81 apart from new visual counters, with combat
regions and events preserved. Full-route traversal was not rerun for this rendering-focused iteration.

**Capture gap:** No game window opened or actual Prototype 82 screenshot was captured. Live motion, foot sliding,
gameplay-background contrast and GPU performance remain pending. Preserve 81 and 82 for an approved comparison.

[Final v4 software study](art-studies/20261020-115814-alligator-animation/20261020-120155-v4-study.json)
records its own creation time and is not a gameplay capture; earlier study versions remain intact.

**Record created:** 2026-10-20T12:03:28.468972-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](082-alligator-gait-and-jaws/20261020-120328-capture-status.json).

## 083 — Consistent plumbing buttons — October 20, 2026

**Version:** Prototype 83 / 0.83.0; preserved app, ZIP and source snapshot `builds/source-83`.

Approved metal-and-sludge artwork now provides consistent focus, hover, pressed and disabled states across the menus.
Coverage includes employee arrows and Back, difficulty Back/Confirm, Controls tabs and settings, pause, Life Lost,
Game Over and trial results. Completion exposes one working Return to Main Menu button. The same-size angry Hard
option and Prototype 82 alligator animation remain preserved. Existing art is reused; Art approved source/layout work,
not an actual rendered-screen playtest.

**Validation:** Engineering reports twelve packaged suites and thirty-three Python tests passing, plus export,
signing and ZIP verification. Checks cover input routes, guards, label fit, plate slices, death/retry/reset and related
difficulty, audio and alligator regressions. An old title-screen test also failed against 82 because it omitted confirm
releases and the difficulty step; the corrected test passes against the final 83 package.

**Capture gap:** No game window opened or actual Prototype 83 screenshot was captured. Rendered-screen review, live
input/visual playtesting and running-build screenshots remain pending. Preserve 83 alongside earlier builds.

**Record created:** 2026-10-20T12:19:29.784925-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](083-consistent-plumbing-buttons/20261020-121929-capture-status.json).

## 084 — Platform shots, denser encounters and a weaker Widow — October 20, 2026

**Version:** Prototype 84 / 0.84.0; preserved app, ZIP and source snapshot `builds/source-84`.

Shots now pass through thin one-way decks from either side; solid platforms and floors still block them.
Actor collisions remain unchanged. Normal and Hard gain approximately 25% more eligible ordinary enemies,
including swarm additions, with extra-only pacing and safe entry. Easy remains unchanged. Widow health drops
from 180 to 135 HP in every mode: Tony needs 12 starter hits instead of 15, and Sean needs 8 instead of 10.

**Validation:** Engineering reports seventeen packaged suites, eighteen full routes and thirty-three Python tests
passing, plus export, signing and ZIP verification. Bot encounters rise from 26–27 to 34–35 on Normal and from
34 to 43–46 on Hard; Easy stays at 27 for Tony and 26 for Sean. Observed increases depend on the route and
spawn conditions and do not establish human fairness.

**Capture gap:** No game window opened or actual Prototype 84 screenshot was captured. Human fairness and live
input/visual review remain pending. Preserve 83 and 84 for an approved comparison.

**Record created:** 2026-10-20T14:16:47.608157-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](084-projectiles-density-and-widow/20261020-141647-capture-status.json).

## 085 — Clogfather finale and checkpoint inspection — October 20, 2026

**Version:** Prototype 85 / 0.85.0; source commit `4e16bc4`; preserved app, ZIP and snapshot `builds/source-85`.

The route now extends about 6500 logical pixels from the Skitterling exit to the Clogfather approach, including
existing continuation, with five distinct new background panels. A second checkpoint at 13800 preserves defeated
Skitterling progress. The rooted 1080 HP Clogfather uses sludge and ceiling acid attacks, five-second weak-point
recovery, a continuous health bar, damage stages, collapse and dedicated music. Completion requires terminal boss
defeat and reaching the exit; both heroes receive a four-line victory exchange. No portal or level-two work is included.

Injured checkpoint check-in now lasts 6.8 seconds: grab/lift, opposite-arm magnifying inspection, diagnosis using
actual pre-heal HP, crush/throw, bloody screen slide and same-hero clone. Each dispenser owns one spare employee.
Healthy 0.4-second and respawn 1.9-second paths and normal death life accounting remain intact.

**Validation:** Engineering reports thirty-one final packaged suites and thirty-four Python tests passing, plus
export, signature and ZIP checks. Coverage includes eighteen original-route regressions, twelve extended-route
forward/reverse cases across both heroes, all modes and 60/120 Hz, and six boss integration cases. Traversal bots
restore HP for coverage; these results do not establish human fairness or fight duration.

Art approved composed boss body/open and closed weak points/HUD and all four normal/Hard held-hero inspection poses.
Damage and collapse sheets/crops were registered and inspected; full composed-stage and continuous transition review
remain pending.
[Preserved source studies](art-studies/20261020-153001-clogfather-and-inspection/20261020-153001-archive-record.json)
are software compositions, not gameplay screenshots. Creation date is October 20; exact creation times are unknown.
Their archive time, 15:30:01 America/Los_Angeles (UTC−07:00), is recorded separately.

**Capture gap:** No game window opened or actual Prototype 85 screenshot was captured. Live balance, boss duration,
animation, damage/collapse transitions, checkpoint stock-window occlusion, background seams and subjective audio mix
remain pending. Earlier captures and builds are preserved; outstanding Prototype 83 menu views remain on the backlog.

**Record created:** 2026-10-20T15:35:08.958034-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](085-clogfather-finale-and-inspection/20261020-153508-capture-status.json).

## 086 — Enemy pressure and portal departure — October 20, 2026

**Version:** Prototype 86 / 0.86.0; source commit `1ddb8cc`; app, ZIP and snapshot `builds/source-86` preserved.

Sputtervalve fires without an attack windup and repeats every 2.5 seconds; Gratecrawler adds arcing muck shots, and
Hallowed Widow pursuit is revised. Clogfather alternates low and higher weak points. The higher opening was adjusted
40 pixels vertically to support ordinary horizontal jump shots from both heroes; the before/after source studies
are preserved. The ending automatically follows collapse with route-specific dialogue and involuntary portal suction.
Only the selected hero enters; the partner remains on radio. Completion states that level two is not yet playable.

**Validation:** Engineering reports all thirty-six final packaged suites and thirty-four Python tests passing,
plus export, signature and ZIP checks. Eighteen original-route cases retain the actual 25% density gate, and twelve
extension cases pass. The density regression came from a high Widow incorrectly blocking floor entrances regardless
of height. A vertical-overlap check fixes admission while preserving caps and ground/diving exclusions; acceptance
was not weakened. The source snapshot is preserved.

**Source review:** The contact sheet, portal/remains view and collapse studies are source compositions, not gameplay.
The initial portal/remains occlusion led to an Engineering fade adjustment. Collapse height/damage continuity remains
unapproved. Earlier compositions and the revised higher-opening contact sheet are preserved separately.

**Capture gap:** No game window opened or actual Prototype 86 screenshot was captured. Human balance, animation,
collapse continuity, portal occlusion and subjective audio review remain pending. Level-two gameplay remains held.

**Record created:** 2026-10-20T16:14:32-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](086-projectiles-and-portal/20261020-161432-capture-status.json).

## 087 — Difficulty menu navigation — October 20, 2026

**Version:** Prototype 87 / 0.87.0; source commit `c08a687`; app, ZIP and snapshot `builds/source-87` preserved.

Back and Start previously sat outside the difficulty menu's three-row focus loop. Navigation now covers all five
controls while preserving the selected difficulty. Keyboard arrows/Tab and controller D-pad/stick reach the footer.
Confirming a difficulty row focuses Start; releasing and confirming again starts the game. Escape/B retains the Back
shortcut, with mouse edge buttons and release guards covered. Existing artwork is reused.

**Validation:** Engineering reports ten relevant packaged suites and thirty-four Python tests passing, plus export,
signature and ZIP verification. Coverage includes both heroes, all difficulty choices and supported navigation routes.
This focused delivery does not claim a new full combat test matrix.

**Capture gap:** No game window opened or actual Prototype 87 screenshot was captured. Live input/visual review
remains pending. The user-supplied desktop screenshot was not archived because it includes unrelated/private content.

**Record created:** 2026-10-20T16:30:46-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](087-difficulty-navigation/20261020-163046-capture-status.json).

## 088 — Full-size portal departure — October 20, 2026

**Version:** Prototype 88 / 0.88.0; source commit `18f5f61`; app, ZIP and snapshot `builds/source-88` preserved.

The selected hero is carried toward the portal at full size with frightened, splayed arms and legs. Four variants
cover Tony and Sean in normal and Hard costumes. A huge six-frame water/debris surge follows the Clogfather's defeat;
portal occlusion hides the hero progressively instead of shrinking them. Five blocking dialogue lines establish the
released water, then the selected hero's “UUAAAAAAAAAA!!” appears during the pull as a world caption.

Gratecrawler health rises from 24 to 72 HP: six Tony starter hits or four Sean hits. Its existing doubled size,
45 movement speed and 2.5-second muck cadence remain unchanged. Level-two gameplay remains held.

**Validation:** Engineering reports all nine suites passing against the final exact re-export, thirty-four Python
tests passing, and signed ZIP verification. Art approved source fit for the poses and surge, not live animation.

**Capture gap:** No game window opened or actual Prototype 88 screenshot was captured. Live pose/wave/occlusion,
caption readability and human balance remain pending. The preserved contact sheet is a source composition only.

**Record created:** 2026-10-20T16:43:19-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred. Art confirmed October 20 source creation; its exact time is unknown.

[Capture status and verification](088-full-size-portal-departure/20261020-164319-capture-status.json).

[Source-composition archive](art-studies/20261020-164319-portal-departure/20261020-164319-archive-record.json).

## 089 — Progressive wastewater across the extended level — October 20, 2026

**Version:** Prototype 89 / 0.89.0; source commit `8ddb961`; signed app, ZIP and source snapshot preserved.

Progressive bottom water and clog presentation now follows the extended 15200-pixel route and 14150 boss approach.
The stale renderer limit and terminal profile are replaced while the opening 0–1440 section stays intact. Existing
art and visual targets are reused. Pipe/wastewater draws after room scenery and before the ending wave.
Only Skitterling's opaque water base is suppressed in the integrated route; aquatic attack effects and standalone
water remain. Prototype 88 is preserved.

**Validation:** Engineering reports ten exact packaged suites and thirty-four Python tests passing, plus signed-app
and ZIP integrity checks. Coverage includes wastewater profile/art/route, Skitterling water/art/integration,
Clogfather integration, ending, role combat and version checks.

**Capture gap:** No game window opened or actual Prototype 89 screenshot was captured. Live water/clog progression
and layer readability remain pending. No new artwork or source composition is represented as a gameplay capture.

**Record created:** 2026-10-20T16:50:40-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](089-progressive-wastewater/20261020-165040-capture-status.json).

## 090 — Gratecrawler throwing motion — October 20, 2026

**Version:** Prototype 90 / 0.90.0; source commit `62fcce9`; app, ZIP and snapshot `builds/source-90` preserved.

Gratecrawler pauses, faces the hero and locks its aim before throwing. Two 0.15-second windup poses lead to release
from the authored hand at 0.3 seconds, followed by 0.12 seconds of follow-through and 0.18 seconds of recovery.
It then resumes its original patrol direction. Four authored poses support left and mirrored right facings.

Hit, death and offscreen events cancel pending throws; pause/reset behavior remains safe. Close targets cannot force
a backward throw. Health stays at 72 HP, size at its doubled scale, speed at 45 and cadence at 2.5 seconds; the existing
muck trajectory is retained. Boss gas and Septic Air Force ideas remain discussion-only, and level two remains held.

**Validation:** Engineering reports all eleven suites passing against the final exact re-export and thirty-four
Python tests passing, with signed app and ZIP verified. Checks cover throw/patrol behavior, role combat, creature audio,
wastewater, Skitterling, Clogfather, the ending and version. Art approved the both-facing source composition.

**Capture gap:** No game window opened or actual Prototype 90 screenshot was captured. Live pose transitions and
hand-aligned projectile release remain pending. The archived facing study is source composition, not gameplay.

**Record created:** 2026-10-20T17:01:01-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred. The source study's exact creation time is unknown; its archive time is recorded separately.

[Capture status and verification](090-gratecrawler-throw/20261020-170101-capture-status.json).

[Source facing study archive](art-studies/20261020-170101-gratecrawler-throw/20261020-170101-archive-record.json).

## 091 — Skitterling checkpoint and coherent ending dialogue — October 20, 2026

**Version:** Prototype 91 / 0.91.0; final source `2c627a6`, checkpoint change `0f9bd65`;
app, ZIP and source snapshot `builds/source-91` preserved.

Skitterling's terminal zero HP now saves an automatic checkpoint before the 1.2-second death/exit sequence.
Retry starts at 7650 beyond the exit and retains the defeated boss. Victory itself grants no teleport, healing,
life or clone; retry uses existing full-health/immunity behavior without adding dispenser stock. The original
4650/13800 machines remain, later checkpoint progress takes priority, and a new game clears saved progress.
Post-boss roster and swarm ownership are retained for retry. Previously completed-boss restoration required 13800.

Both Clogfather conversations now follow their water-release setup. In Tony's route, Sean asks where the water is
going before Tony identifies the portal. In Sean's route, explicit boss defeat prompts Tony to advise getting clear
of the water, replacing the disconnected “Leave it alone.” Five dialogue lines and the action scream remain intact.

**Validation:** Engineering reports ten packaged runtime suites passing, including eighteen paired swarm-admission
runs, and thirty-four Python tests passing. After the dialogue-only re-export, dialogue, Hard dialogue, ending and
version checks pass against the final package. This is twelve unique suites across exports, not twelve suites all
rerun against the final export; runtime was unchanged. Signed app and ZIP verification pass.

**Capture gap:** No game window opened or actual Prototype 91 screenshot was captured. Human checkpoint/retry and
dialogue-flow review remain pending. No new artwork is part of this iteration.

**Record created:** 2026-10-20T17:18:22-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and verification](091-skitterling-checkpoint-and-dialogue/20261020-171822-capture-status.json).

## 092 — Clogfather gas and reinforcements — October 23, 2026

**Version:** Prototype 92 / 0.92.0; source commit `d5b887a`; app, ZIP and snapshot `builds/source-92` preserved.

Clogfather now alternates gas and reinforcement pressure after its weak-point windows. The
sequence uses a 1.2-second warning, then either two seconds of drifting gas or three seconds of capped Septic Air
Force pressure, followed by 0.25 seconds clear before the original acid/volley attacks. Full five-second alternating
low/high windows and a 0.8-second clear approach remain. Clogfather health stays at 1080 HP.

Reinforcements retain 24 HP, with a cap of one early and two later; arena geometry may admit fewer. No refill occurs,
and all reinforcements clear before the next original attacks/window. Normal damage and invulnerability apply without
interrupting movement or firing.

**Validation:** Engineering reports fifteen exact final packaged suites and thirty-four Python tests passing, plus
export, signature, archive and standalone headless checks. Coverage includes all pressure phases at 60/120 Hz, six
hero/mode cases, damage/immunity/projectiles, pause/repeated waves/reset/death/windows, art/audio and prior
checkpoint/ending/throw/water regressions. Gas artwork is delivered; its reviewed contact composition is source art,
not evidence of live gameplay acceptance.

**Capture gap:** No game window opened or actual Prototype 92 screenshot was captured. Foreground permission has not
been given. Prototype 91 is preserved;
live visuals, listening, human fight duration/balance and actual captures remain pending.

**Record created:** 2026-10-23T10:15:20-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](092-clogfather-gas-and-reinforcements/20261023-101520-capture-status.json).

## 093 — Clogfather music and playback lifecycle — October 23, 2026

**Version:** Prototype 93 / 0.93.0; source commit `95ea42c`; app, ZIP and snapshot `builds/source-93` preserved.

Pressure Tarantella is an original 48-second, 160 BPM Italian-inspired Clogfather theme using synthetic mandolin-like
tremolo, accordion-like voices, low brass and percussion. Measured effective loudness rises from -38.8 to -28.4 LUFS.
Runtime gain is -16 dB; warnings add -12 dB ducking with immediate attack and 200 ms release. Dialogue ducking does
not stack. Prototype 92 combat and build are preserved.

**Diagnosis:** Engineering's baseline host starts the old music; complete silence has not been reproduced.
Low audibility is a measured contributor. The confirmed completed-fade resume error from per-frame pause refresh
is fixed; this does not establish that every reported silence case was reproduced.

**Validation:** Engineering reports twelve exact exported suites and thirty-four Python tests passing, plus export,
signature, archive and standalone checks. Actual-host entry, retry, pause, mute, loop wrap, warnings, victory and title
checks pass. Subjective listening and perceived loop seam/mix acceptance remain separate from these checks.

**Capture gap:** No game window opened or actual Prototype 93 screenshot was captured. Foreground permission has not
been given. Prototype 92 is preserved;
live listening, perceived loop seam/mix review and gameplay captures remain pending.

**Record created:** 2026-10-23T10:46:07-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](093-clogfather-music/20261023-104607-capture-status.json).

## 094 — Right-side boss HUD — October 23, 2026

**Version:** Prototype 94 / 0.94.0; source commit `add25b2`; app, ZIP and snapshot `builds/source-94` preserved.

Sean selected Art option B for a right-side boss HUD. The normal 82-pixel player HUD retains health pips, lives,
name, weapon, kills and route. An earlier overlay proposal hid Skitterling's right port, so the delivered framing
uniformly scales the 960-wide world to 864 at scale 0.9 and offset (0,54), leaving a dedicated 96-pixel sidebar.
All world layers share the same aspect and alignment; UI stays unscaled. Combat geometry and camera behavior
are unchanged. Both registered art skins use bottom fill, a damage trail and names. The meter draws at z10,
behind dialogue at z20 and pause at z30.

Framing persists through Skitterling death/exit until release and through Clogfather death/portal departure,
then resets on retry/new game. The dramatic boss-name entrance is a separate concept, not part of this build.

**Validation:** Engineering reports fifteen exact final PCK suites and thirty-four Python tests passing, plus
signature, archive and standalone checks. All six hero/mode framing, GUI order and reset cases pass, alongside
both-boss combat, right-port, checkpoint, weak-point, pressure, music, dialogue, pause and portal regressions.
Art and Engineering reviewed the persistent HUD source compositions; those are not gameplay captures.
The separate Art concept commit `18b5497` is preserved.

**Capture gap:** No game window opened or actual Prototype 94 screenshot was captured. Foreground permission has not
been given; live HUD readability, framing transitions and gameplay screenshots remain pending.

**Record created:** 2026-10-23T11:23:49-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](094-right-side-boss-hud/20261023-112349-capture-status.json).

## 095 — Boss title reveals — October 23, 2026

**Version:** Prototype 95 / 0.95.0; source commit `4be6e43`; app, ZIP and snapshot `builds/source-95` preserved.

The selected white S2 Skitterling title and goopy C1 Clogfather title appear centered on the full
viewport. Timing is 0.4 seconds fading in, three seconds fully visible and 0.25 seconds fading out. Gameplay resumes
when fade-out begins. Each boss reveal occurs once per run; checkpoint retries skip it and a new run resets it.

Persistent sidebar names are removed while the vertical meters and Prototype 94 world framing remain.

**Validation:** Engineering reports sixteen exact final PCK suites and thirty-four Python tests passing, plus export,
ad-hoc signature, archive integrity and standalone headless startup checks. A regression fix preserves zero-delta
exit/ending transitions.

**Capture gap:** No game window opened or actual Prototype 95 screenshot was captured. Permission to open the game
has not been given. Live title readability, timing and resumed-gameplay review remain pending.

**Record created:** 2026-10-23T12:37:31-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](095-boss-title-reveals/20261023-123731-capture-status.json).

## 096 — Gnatastrophe and stronger boss pressure — October 23, 2026

**Version:** Prototype 96 / 0.96.0; source commit `356bc0d`; app, ZIP and snapshot `builds/source-96` preserved.

The existing sewer-fly swarm is renamed Gnatastrophe; its stable ID and historical records remain intact.
The new 48-second Festering Pressure loop replaces the jaunty boss track. Sparse roars use a 10–14-second interval
and an eight-second phase-roar cooldown, with attack-warning priority. Listening acceptance remains pending.

Easy/Normal/Hard gas tuning uses 1/4/6 clouds, 1.2/0.75/0.55-second warnings, 2/4/4.5-second lifetimes and
30/65/90 movement speeds. Clouds take five starter hits each: 60 HP against Tony or 90 against Sean. Reinforcements
number 2/4/8 with 24 HP, a 1.2-second warning, 3/4/5-second lifetime and a central 180-pixel safe corridor.
They do not refill, and there is no hidden contact grace after the warning.

Normal and Hard add two separately aimed rounds of three or four shots, with 0.7/0.55-second warnings and
0.35/0.25-second spacing. Easy retains one round at 0.9/0.45. Acid warnings are 1.2/0.9/0.7 seconds with safe lanes
180/140/120 pixels wide and more Normal/Hard columns. Full five-second low/high windows, 1080 boss HP and
Prototype 95 title/HUD behavior remain.

**Validation:** Engineering reports twenty-two packaged regressions passing on the corrected-contact build and
thirty-four Python tests passing. The final export changed only an embedded old-name layout note; four checks
(current creature names, pressure integration, boss intro and version) passed on that exact final export. Do not
interpret this as twenty-two exact-final checks. Export, signature, archive and standalone checks pass.

Audio commit `316861d` and magazine commit `d977865` accompany the feature. Magazine 31 deployment succeeded;
Marketing verified the live eight-page PDF hash, Gnatastrophe naming and reciprocal links.

**Capture gap:** No game window opened or actual Prototype 96 screenshot was captured. Live listening, readability,
human balance/duration and gameplay captures remain pending. Preserve Prototype 95 and earlier chapters.

**Record created:** 2026-10-23T21:39:45-07:00 (`America/Los_Angeles`, UTC offset -07:00);
no image capture occurred.

[Capture status and final verification](096-gnatastrophe-and-boss-pressure/20261023-213945-capture-status.json).

## Future chapters

Each delivered iteration gets its own numbered folder, dated entry, and fresh screenshots. Earlier chapters stay intact
so changes to the characters, environments, interface, and gameplay remain visible side by side.
