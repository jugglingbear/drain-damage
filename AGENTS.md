# Project instructions

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

## Combat metadata maintenance

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
