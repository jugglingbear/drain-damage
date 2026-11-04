# Compact ownership handoff

Use this procedure when Sean authorizes replacing a project role's chat. A compact handoff transfers current work
and responsibility without requiring a transcript review. Consider it at task boundaries when context grows or
settled decisions are repeatedly rediscovered; this is a judgment call, not a credit measurement or automatic trigger.

## Prepare the transfer

1. Obtain Sean's authorization before creating a replacement chat. Keep the selected model and reasoning settings
   unless he requests a change. Creating this documentation does not authorize future chat creation.
2. Verify the repository path, branch, commit and working-tree status. Identify the owner of each uncommitted change,
   active task and pending delivery. Preserve unrelated work and agree file ownership before any parallel edits.
3. Read current authoritative records: the roadmap, relevant canonical metadata and delivery records, and relevant
   storybook backlog entries. Link evidence instead of copying history. Open historical material only to answer a
   specific unresolved question; do not require archive imports or predecessor interviews.
4. Prepare the compact handoff below. Distinguish approved work, proposals, holds, completed work and remaining gaps.
   State which test results are inherited, which were newly run, and which acceptance checks remain incomplete.
5. Create the authorized replacement with the handoff. Record its actual returned chat ID; never infer identity from
   a similar title. Resolve collaborators by current Drain Damage project membership and role.

## Accept ownership and update routing

1. The replacement reads current `AGENTS.md`, relevant supporting standards and task-specific requirements, then
   verifies the handoff against the working tree and relevant current records. It reports material discrepancies.
2. The replacement explicitly accepts ownership and states the current priorities and holds. The predecessor stops
   development and duplicate monitoring once ownership transfers. Preserve historical records.
3. The replacement notifies the other current-project role chats that ownership has changed. Verify recipients against
   project membership immediately before sending; exclude retired and old-project chats. Include the new role title,
   exact chat ID, project ID and superseded chat ID. Tell recipients to route future handoffs to the replacement.
   A renamed chat does not redirect messages addressed to its former owner's saved ID.
4. Verify that routing notices were sent successfully and report any failures. Avoid acknowledgment-only replies,
   duplicate status requests or requiring every recipient to respond before work can continue.
5. Update affected current ownership references in existing records where necessary. Keep the roadmap aligned when
   task scope or status changes. Do not create a separate reporting layer or rewrite historical ownership records.
6. Give Sean one concise completion: ownership accepted, routing notifications sent, current priorities and blockers.
   Continue only within the authorized scope. A handoff does not lift a hold or renew expired launch permissions.

Current-project coordination is covered by the standing authorization in [the project instructions](../AGENTS.md).
Contact outside that project still requires explicit user instruction. Resolve current IDs at transfer time instead
of treating this document as a permanent roster.

## Handoff template

Fill only applicable fields and keep the result concise. Prefer links to current records over copied detail.

```text
Role and ownership: <role; outgoing chat ID; replacement accepts ownership explicitly>
Authorization: <Sean's instruction; scope; any hold or initial-turn restriction>
Project and repository: <current project ID; checkout path; branch; commit>
Working tree: <modified/untracked paths, owners and work to preserve>
Current objectives: <approved tasks, priority, accountable owners and next actions>
Decisions and constraints: <settled decisions; unresolved questions; permission boundaries>
Evidence: <current canonical records; build/version; validation evidence and remaining gaps>
Validation provenance: <inherited results versus newly run checks; no unsupported acceptance claims>
Dependencies: <concrete contributions needed; resolve collaborators by current project membership>
Completed work: <brief references; do not reopen as pending tasks>
Transfer: <predecessor stops duplicate work; replacement verifies and accepts>
Routing: <replacement notifies other current-project roles with its verified title and exact chat ID>
```

## Routing notice template

```text
Ownership update: <role> is now owned by <new title>, chat <new ID>, in project <project ID>.
Send future <role> handoffs and integration requests to that chat.
<old title>, chat <old ID>, is the superseded owner; do not use its saved ID for new work.
Existing task holds and permission boundaries remain in force. No acknowledgment-only reply is needed.
```

The replacement uses targeted checks to establish ownership; unchanged release artifacts need not be rebuilt merely
to accept a handoff. Runtime changes still require the usual build, testing, Art and visual acceptance gates.
