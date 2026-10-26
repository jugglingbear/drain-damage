# Project instructions

## Agent consultation scope

- When asked to consult other agents, limit consultation to agents in the current Drain Damage project
  (project ID `ee1159b9-4ea1-4749-9cd3-4152636b3070`), unless Sean explicitly asks otherwise.
- Agents in Drain Damage (old), including predecessors, are outside that scope. Other projects are also excluded.
- Resolve collaborators by current project membership and role, not a same/similar title or historical thread ID.
- Replacement names have no `2` suffix; original chats have an ` (old)` suffix and are in Drain Damage (old).
- All agents currently in this project may initiate necessary project-related communication with one another
  without separate approval, under Sean's standing authorization.
- Communication with agents outside this project still requires explicit user instruction.

## Task ownership and coordination

- Assign one accountable owner per task. Involve specialists for a concrete contribution or necessary review;
  agree file ownership before parallel edits. The owner coordinates contributors and monitors the delivery.
- Start with current authoritative records: [the roadmap](roadmap.html), relevant canonical metadata and delivery
  records in `handoffs/`, and [the storybook capture backlog](storybook/curation-backlog.json). Retrieve historical
  archives only to answer a specific unresolved question. Completed handoffs and historical permissions are not
  pending tasks; contacting retired or other-project chats requires a new explicit human request.
- Current-project agents may consult one another as needed under Sean's standing authorization. Avoid
  acknowledgment-only messages, duplicate status requests, and multiple agents monitoring the same delivery.
- Give interim updates for blockers, decisions or material changes. The owner provides one consolidated completion
  with deliverables, validation and remaining gaps.
- At meaningful handoffs or completion, keep current-state records concise and link supporting evidence instead
  of copying history. Reuse existing records; do not add a reporting layer or require updates after every message.
- These coordination rules preserve all existing artwork, build, testing, roadmap, storybook and permission rules.

## Optional idea recall

- Consult [Tony's optional idea bank](design/tony-idea-bank.json) when discussing matching hero-stat, weapon,
  special-attack, monster, boss or hazard work; [the idea index](design-ideas.json) links earlier proposals too.
- Bring up relevant entries as suggestions and ask whether Sean wants one included. The bank is not a requirement,
  roadmap commitment, rebalance instruction or authorization to implement anything or expand the playable roster.
- Preserve source wording and uncertainties; distinguish Sean's tentative interests from approved decisions.

## Character names

- Use only Tony and Sean in all player-facing game text, including menus, dialogue, and credits.
- Do not add surnames to either character.

## Art collaboration

- Whenever new artwork is needed, ask the existing Bestiary / Art agent to help before creating it.
- This includes interface illustrations and props, portraits, environments, sprites, and replacement artwork.
- Engineering provides dimensions, layout constraints, and runtime requirements, then integrates the delivered art.
- Do not bypass Art by independently generating artwork or substituting code-drawn art without Sean's direction.

## Playtest window convention

- Before opening or foregrounding the game for Sean to playtest or inspect anything, ask permission and wait
  for an explicit yes. Explain what needs checking before asking. A general development request is not permission
  to interrupt him with a game window. An explicit request to launch or playtest counts as permission.
- After Sean approves, use a large, maximized window for his playtest.
- Keep agent-only checks headless or in the background when possible. If a visual test would steal focus,
  interrupt Sean, or require foregrounding the game, ask first; a small window is not an exception.
- When opening the game for agent-only testing or screenshots, use a small window; no user interaction is expected.
- Use a temporary launch override for agent testing so normal user launches remain large.
- Do not leave an agent test running in a large window unless explicitly handing it over for Sean's playtest.

## Build delivery and notifications

- After integrating game changes, including deliveries from other agents, build and run the relevant checks.
- Defer the build only when waiting for additional agent work that belongs in the same integration; tell Sean what
  is still pending rather than implying the new version is ready.
- Whenever a new build is ready, proactively tell Sean its version, what changed, and any remaining testing gaps.
- If a build fails, report the failure and do not describe it as ready to play.
- Building does not authorize opening or foregrounding the game; keep the playtest permission rules above.

## Gameplay health and lives HUD

- Use the shared `draw_vitals` HUD throughout all gameplay, including levels, bosses, flush, landing and ride.
- Show one health marker per selected hero maximum HP, filled for current HP, and one selected-hero head per life.
- Preserve these visual indicators across damage, death, retry and transitions. Numeric-only substitutes require
  Sean's explicit approval; new modes inherit this standard unless he requests an exception.

## Roadmap maintenance

- Keep `roadmap.html` current whenever work is added, completed, changed, deferred, or reprioritized.
- Update affected descriptions, milestone order, statuses, remaining work, and current build/date as applicable.
- Make these updates in the same delivery as the work; do not wait for a separate user reminder.
- Distinguish partial progress from completed milestones and proposed ideas from agreed plans.
- Keep roadmap claims aligned with the running build and the development storybook.

## Development storybook

The user wants screenshots of every iteration to tell the story of the game's graphics and capabilities.

- For each delivered game iteration, capture actual screenshots of the running build before replacing it.
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

## Makefile conventions

Read [.github/instructions/makefile.instructions.md](.github/instructions/makefile.instructions.md)
before creating or editing Makefiles. These reusable conventions were brought over from Kandra:
self-documenting default help, source-order sections, orange headers, white target names, real tabs,
inline descriptions, and emoji progress. Preserve the Godot toolchain used by this game.

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
