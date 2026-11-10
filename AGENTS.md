# Project instructions

## Agent consultation scope

- Engineering is owned by chat `01a1af5b-36f9-7a61-91a5-c5fad5d51eeb`. Sean prohibits contacting, prompting,
  consulting or waking Engineering1 (`01a19e0e-c1b7-74f1-998f-952dcc81d673`) under any circumstance.
  Do not retrieve its transcript; route Engineering work to the current owner.

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

- Standing authorization from Sean, November 4, 2026: agents may open needed test windows without asking again
  unless he revokes that permission. Continue using small windows for agent-only testing. This supersedes the
  per-session approval requirements below for those tests.

- Before opening or foregrounding the game for Sean to playtest or inspect anything, ask permission and wait
  for an explicit yes. Explain what needs checking before asking. A general development request is not permission
  to interrupt him with a game window. An explicit request to launch or playtest counts as permission.
- After Sean approves, use a large, maximized window for his playtest.
- Keep agent-only checks headless or in the background when possible. If a visual test would steal focus,
  interrupt Sean, or require foregrounding the game, ask first; a small window is not an exception.
- When opening the game for agent-only testing or screenshots, use a small window; no user interaction is expected.
- Use a temporary launch override for agent testing so normal user launches remain large.
- Do not leave an agent test running in a large window unless explicitly handing it over for Sean's playtest.

- Before presenting visual game changes as ready, capture the running build and inspect the screenshot yourself.
  Check framing, lighting, proportions and contact at relevant camera angles; headless tests are not visual acceptance.
  Follow the launch permission rules above and record any blocked capture honestly.

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

## Makefile conventions

Read [.github/instructions/makefile.instructions.md](.github/instructions/makefile.instructions.md)
before creating or editing Makefiles. These reusable conventions were brought over from Kandra:
self-documenting default help, source-order sections, orange headers, white target names, real tabs,
inline descriptions, and emoji progress. Preserve the Godot toolchain used by this game.

## Task-specific requirements

Before relevant work, read the matching sections of [task-specific requirements](docs/agent-task-requirements.md):

- Gameplay: health/lives HUD, monster motion/projectiles, water/object support, visual acceptance, ramp contact
  and 65% pit overlap.
- Visual changes: physical plausibility and independent Art review; screenshots and motion remain required.
- Windows: export and native verification requirements.
- Milestones: storybook and making-of curation; routine fixes do not need storybook entries.
- Creatures/weapons/audio: bestiary, combat metadata, audition regeneration and original-asset retention.
- Creative writing: natural prose and avoidance of formulaic paired fragments.

## Context and credit discipline

- Keep the user-selected model; do not downgrade it to save credits without explicit instruction.
- Read only relevant current records and standards sections. Reuse guidance already read during the task.
- Exclude `agent-context-archive/` and archive/recovered-history/succession handoffs from routine searches.
  Open a specific historical record only for a named unresolved question; never bulk-import predecessor context.
- Bound search output and line length, especially for JSON. Prefer structured field extraction over dumping files.
- One owner coordinates delivery. Avoid acknowledgment-only messages and polling unchanged status.
- Run checks appropriate to changed behavior and required delivery gates; repeat only for new evidence or changes.
- At task boundaries, consider a compact handoff if summaries grow or settled decisions are repeatedly rediscovered.
  This is a heuristic, not credit telemetry. Do not create replacement chats without user authorization.
- A replacement gets current objectives, working-tree state, decisions, evidence and blockers, not the full transcript.
  Transfer ownership explicitly and stop duplicate work in the predecessor. Preserve historical records.
- Follow [the compact ownership handoff procedure](docs/compact-ownership-handoff.md) when replacing an owner,
  including notifying other current-project agents of the replacement's verified chat ID.
