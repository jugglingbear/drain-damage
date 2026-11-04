# Task-specific project requirements

Read the relevant sections before work in that area. These remain mandatory project rules.

## Windows testing and cross-machine work

- Start with [Windows export and test instructions](DEVELOPMENT.md#windows-exports-and-testing)
  and the current delivery record in `handoffs/first-call-integration.json`. Discover the local checkout path;
  do not reuse Mac absolute paths or assume Mac chats, tools, credentials or permissions transferred with Git.
- Check the branch, commit and working-tree changes before updating the checkout. Preserve local work and hydrate
  Git LFS assets before source-based checks. Use a separate `codex/` branch for Windows fixes.
- The current dependency bootstrap supports macOS/Linux hosts, not native Windows setup. Do not assume
  `make install` or the Mac packaging commands work in Windows. Use the exported Windows package for initial tests;
  record any additional native development setup explicitly.
- Build ZIPs under `builds/` are ignored by Git and do not arrive with a clone or pull. Obtain the intended ZIP
  and checksum separately, extract the complete package, and keep its EXE and PCK together. Record the version,
  archive checksum, manifest source commit and dirty-tree flag so results identify the exact tested build.
- Run the package's `Test-Windows.ps1` using the documented PowerShell command. Retain its timestamped logs,
  failures and shutdown warnings. This checks package hashes and native headless initialization for both heroes;
  it does not verify rendering, audio, input, performance or full gameplay.
- Follow successful headless checks with an approved visual playtest of menus, both heroes, Level 1, flush,
  landing and ride, keyboard/controller input, audio, window/fullscreen behavior and frame pacing. The playtest
  permission and screenshot rules above and below apply on Windows too.
- Record Windows version, CPU architecture, GPU/driver, tested controls, reproduction steps and observed results.
  Distinguish real Windows hardware from Windows ARM emulation or a VM. Update the existing delivery record and
  roadmap with evidence and remaining gaps; never mark Windows validated solely from Mac-side export checks.
- Share fixes and durable test findings through Git commits and review. Cross-machine chat access is not assumed;
  follow the consultation scope above rather than treating a new Windows project as the same app project ID.

## Gameplay health and lives HUD

- Use the shared `draw_vitals` HUD throughout all gameplay, including levels, bosses, flush, landing and ride.
- Show one health marker per selected hero maximum HP, filled for current HP, and one selected-hero head per life.
- Preserve these visual indicators across damage, death, retry and transitions. Numeric-only substitutes require
  Sean's explicit approval; new modes inherit this standard unless he requests an exception.

- Health/lives HUD artwork and rendering contain no text on any level: no hero names, HP/LIVES labels, numbers
  or decorative lettering. Selected-hero portraits identify the hero; filled/depleted markers and grouping convey counts.

## Monster motion and purple projectiles

- Monsters must never materialize suddenly inside the visible playfield. Admit them outside the viewport and
  animate their entrance from an edge, or stage a continuous depth entrance from a background opening or from
  the viewer's side of the screen. Foreground entrants start large in the super-foreground and shrink as they
  travel away from the viewer to the hero's plane, reversing the employee dispenser's visual direction.
- Apply this to every monster and spawn path, including trials, reinforcements and swarms. A flashing sprite,
  warning ring or opacity fade at the final spawn position does not substitute for an entrance.
- Choose the entrance per encounter. Level 1 mixes left/right/top/bottom approaches with selective foreground and
  background depth entrances; the no-pop-in rule does not make foreground arrival the default for all monsters.
- Stationary purple-bolt shooters never enter from the viewer. Reveal them continuously from supported ground,
  ceiling or wall fixtures with credible mounting and an appropriate animation. Include authored ceiling shooters
  for high coverage; preserve difficulty population limits and firing cooldowns.
- Clarify surprising, broad interpretations with Sean before applying them across the game.
- Keep creatures animated throughout transit. Attacks and contact begin only after arrival on the playable plane;
  arrivals still consume population limits. Camera movement must not expose a teleport or unfinished spawn.
- Unless Sean explicitly requests an exception, monsters animate while walking, running, flying and charging attacks.
  Trials inherit this requirement; a static sprite translated across the screen is not a movement animation.
- Gnatastrophe's weapon formations retain individual fly motion. Morphs preserve fly identity and continuous positions;
  all living phases deal contact damage, including outer weapon-form flies. Keep shared HP and contact damage amount.
- Purple energy bolts have no time or distance limit. Retire them after physical impact or when their entire rendered
  sprite leaves the current viewport. Pause, retry and scene teardown still follow their normal lifecycle rules.
- Check motion in the running build. A single frame or a headless animation-state assertion is not visual acceptance.

## 2.5D water and object support

- Use artwork suited to the 2.5D view; coordinate replacements with Art when existing assets are unsuitable.
- Fixed objects must visibly extend below the waterline or have credible structural supports. Do not leave
  solid props resting like flat cutouts on the water. Only intentionally buoyant objects may float.
- Verify submerged geometry, waterline occlusion and support from every supported camera angle.
- Treat the approved Level 2.1 proof as the visual baseline for the ride: broad water coverage, restrained banks,
  shaped props with visible thickness, and consistent materials. A textured flat plate is not a raised cap.
- Physical contact height and shape must match visible surfaces, including raised discs and recessed surrounds;
  do not hide a mismatch by applying a global rider offset.
- Compare actual running views with the approved reference and inspect travel in motion. Frozen screenshots alone
  cannot validate environmental scrolling or the relationship between moving scenery and the rider.

## Visual acceptance and physical plausibility

- Judge the rendered result at normal gameplay size before consulting implementation details. Having a mesh,
  thickness value, passing physics test or technically connected support does not establish visual acceptance.
- For each object, identify what it is, what supports it, how its parts join, what material it reads as, and how
  it interacts with water and the rider. If those answers require explaining invisible geometry, reject the view.
- Reject unsupported water patches, floating sheets, texture-painted depth, paper-thin heavy objects, ambiguous
  water/metal materials, stretched textures, implausible joints, abrupt pose changes and unreadable black pits.
- Compare against the approved reference side by side at similar framing. Inspect silhouettes, side faces,
  attachment points, waterlines, contact shadows, proportions and material contrast at both supported angles.
- Audit each encounter individually, including approach, interaction and departure in motion. Keep observed defects,
  corrected items and unreviewed coverage distinct in the existing delivery record. Representative captures cannot
  establish full-route visual approval. Automated tests establish technical behavior only.
- Engineering owns final acceptance. Obtain independent Art critique of changed constructions and their final
  rendered views; do not count agreement about code or a narrow seam check as approval of the complete scene.
- Preserve evidence of rejected results and the concrete rejection reason. Do not tell Sean graphics are ready
  while known glaring defects remain; report remaining gaps plainly. QA captures for bug fixes stay outside the
  storybook.

## Ramp and slope contact

- A supported rider and board must follow the actual ramp/surface angle, rather than remain horizontal while
  their center rises. Use the rigid board’s underside contact points to determine elevation and pitch.
- Prevent visible penetration or hovering at the rear, middle and front of the board. Blend entry/exit contact
  continuously and preserve correct jump takeoff, airborne motion and landing alignment.
- Apply this rule to every ramp and sloped riding surface, including isolated prototypes and alternate cameras.
  Camera-facing sprites must not override the physics pose. Verify both heroes and relevant camera angles with
  contact tests and actual screenshots before claiming the visual result is correct.

## Pit and hole fall threshold

- A rim touch must not trigger a fall. Require at least 65% of the hero’s ground/contact footprint over the
  actual opening before a pit or hole becomes lethal. Use footprint area, including corners and curved openings.
- Section 1.2 explicitly uses 90% overlap, as requested after the first-pit playtest. Other levels retain their
  existing thresholds. Check the drawn ledge against the collision opening as well as the numerical threshold.
- Preserve jump clearance, swept crossing checks and frame-rate independence; apply the same pit-overlap threshold on
  landing. Scripted transitions remain distinct from accidental pit falls.

## Development storybook

The storybook records meaningful milestones in the game's graphics and capabilities: new features, significant
new artwork, new bosses, new levels, and comparable major updates.

- For milestone deliveries, capture actual screenshots of the running build before replacing it.
- Routine bug fixes, tuning and minor corrections do not require storybook entries, captures or capture-backlog items.
  Visual verification may still be needed for testing; it does not create a storybook obligation.
- Save original PNG or JPEG captures in `storybook/NNN-short-title/`, using the next three-digit iteration number.
- Keep earlier captures and entries intact; never overwrite an earlier iteration with newer artwork.
- Include a representative gameplay view and additional views when needed to show a new feature or milestone.
- Append a dated entry to `storybook/README.md` with embedded screenshots, a short narrative, new capabilities,
  and what is still placeholder or incomplete. Use the user's America/Los_Angeles date.
- Record the game version and, when available, the source commit or build identifier.
- Capture only the game window, avoiding unrelated desktop content. Use the approved computer-use screenshot tool.
- Keep the storybook in the project, outside ignored build/scratch folders, and exclude it from Godot game imports.
- If capture is blocked, record the gap honestly and preserve the build for later capture; do not fabricate screenshots.

### Making-of book curation

- Storyboarding owns ongoing editorial curation of the development storybook, coordinating with Engineering.
- Collect generous early, middle, and late development material for an eventual making-of book: milestone
  screenshots, before/after comparisons, character/menu/environment evolution, funny failures, and design pivots.
- Preserve earlier chapters and originals. Label concept art, rejected ideas, and actual gameplay captures distinctly.
- Engineering preserves builds and supplies actual screenshots under the existing permission rules. This standing
  collection request does not authorize opening or foregrounding the game without permission.
- Maintain a capture backlog for missing milestones so they can be photographed during an approved session.
- Timestamp every new storybook capture and making-of artifact with `YYYYmmdd-HHMMSS` in the filename and
  its entry/metadata, using `America/Los_Angeles` (for example, `20261016-233045-title-screen.png`).
- Record the timezone and UTC offset in metadata to disambiguate daylight-saving transitions. Distinguish actual
  capture/creation time from later archival/import time; add a suffix if filenames would collide within one second.
- Preserve historical originals. Backfill exact timestamps only from trustworthy capture records; retain known
  dates and mark exact times unknown when unavailable. File copy/modification time is not proof of capture time.

## Bestiary maintenance

- Keep `bestiary/bestiary.html` current when adding or revising a monster, its artwork, or implementation status.
- Give every creature a name, description, one gallery portrait, and links to game sprites and animation information.
- Maintain separate pixel-art game sprites and hyperrealistic marketing portraits for each creature.
- Store marketing portraits in `bestiary/<creature>/` with versioned filenames and preserve exact generation prompts.
- Name creature folders after the monster using lowercase hyphenated names. Each contains `monster.json`.
- Treat `monster.json` as the source for names, descriptions, and backstories; synchronize the gallery and catalog.
- Keep stable creature IDs when renaming. Metadata asset paths are relative to the project root.
- Leave backstory text empty with status `pending` until the storyboarding agent supplies it.
- Preserve earlier artwork. Keep `assets/bestiary/catalog.json` aligned with the gallery and current asset paths.
- Distinguish animation source artwork from validated runtime animations and playable enemies from planned creatures.
- Keep marketing assets excluded from Godot imports with `bestiary/.gdignore`; record actual image dimensions.

## Audio auditions and retention

- Whenever sounds are created, replaced, remapped, or otherwise changed, update `audio/sound-registry.json` and rerun
  `python3 tools/build_sound_auditions.py` before delivering the work. For changed runtime mappings, first run it with
  `--refresh`. Include the regenerated `audio/drain-damage-sound-auditions.html` in the same delivery.
- Keep all audition audio, including rejected candidates and repeated demonstrations, in the repository unless Sean
  explicitly says otherwise. Preserve previous files before replacement; use versioned paths, never overwrite originals.
- Register every audition under its permanent sound-slot ID with the next unused `.1`, `.2`, etc. suffix. Preserve
  IDs, source/license metadata and generation prompts. Never delete or renumber candidates to reuse their suffixes.
- Follow `audio/SOUND-AUDITIONS.md`. Run `python3 tools/build_sound_auditions.py --check` before delivery; it rejects
  stale mappings, missing candidate files and HTML that does not reflect current audio bytes.

## Combat metadata maintenance

- Every canonical creature profile, including bosses and mini-bosses, must define both hit and death audio references.
  Preserve source/license provenance and validate referenced assets before export. Planned creatures need profile-ready
  cues and an honest unimplemented status; asset coverage does not establish playable integration.
- Successful nonlethal damage plays the hit cue; lethal damage plays death only once. Keep voices bounded, throttle hit
  spam per enemy, and preserve pause, mute and reset/disposal behavior. Validate complete catalog/profile coverage
  so new creatures cannot silently omit either cue.

- Give every new monster a `health` object in its `monster.json`, including positive maximum and spawn HP,
  progression placement, health-bar visibility, balance rationale, and weapon hit-count comparisons.
- Follow `assets/bestiary/balance-policy.json`; compare both plumbers' available exclusive weapons.
- Mirror health summaries in `assets/bestiary/catalog.json` and the gallery. Keep design and runtime values distinct.
- Keep weapon mechanics in `weapons/<weapon-id>/weapon.json` and register each weapon in `weapons/catalog.json`.
- Bestiary owns each weapon's `game-art.json`; Marketing owns its `marketing-art.json`. Preserve versioned originals,
  exact generation prompts, dimensions, and implementation status. Store game art under `assets/weapons/`.

## Writing Style: Avoid Formulaic AI Copy

Avoid the repetitive use of paired sentence fragments,
especially in marketing copy, dialogue, descriptions,
headlines, and other creative writing.

Examples of constructions to avoid:

- "Two plumbers. One impossible job."
- "No tools. No backup. No problem."
- "One hero. A thousand enemies."
- "Teeth in the bathroom. Wings in the basement."
- "Small town. Big secrets."

These constructions rely on short, parallel fragments
placed next to each other for dramatic effect.

This style is overused in AI-generated writing and
quickly becomes repetitive and artificial.

Guidelines:

1. Prefer natural, varied sentence structures.
2. Use complete sentences where appropriate.
3. Vary sentence length and rhythm.
4. Avoid formulaic contrasts between two short phrases.
5. Do not default to movie-trailer or advertising-tagline
   language when writing promotional material.
6. Favor specific, original observations over generic
   dramatic constructions.
7. Paired fragments are not prohibited, but should be
   rare and used only when genuinely effective.
8. Before finalizing creative text, review it for
   repetitive rhetorical patterns and rewrite them.

The goal is natural, distinctive writing that does not
sound like generic AI-generated marketing copy.
