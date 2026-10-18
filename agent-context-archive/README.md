# Original-agent context archive

This directory preserves the original Drain Damage agents’ durable handoffs for their replacement chats.
Engineering 2 imports each original-authored Markdown document verbatim after its author finishes.
The source directory is `/private/tmp/drain-damage-original-agent-archives/`.

## Role documents

| Original role | Archive |
| --- | --- |
| Game Mechanics | [Game Mechanics history](game-mechanics.md) |
| Art / Bestiary | [Art history](art.md) |
| Engineering | [Engineering history](engineering.md) |
| Storyboarding | [Storyboarding history](storyboarding.md) |
| Marketing | [Marketing history](marketing.md) |
| Level Design | [Level Design history](level-design.md) |
| Audio | [Audio history](audio.md) |
| Release | [Release history](release.md) |

## Provenance and timestamps

Each document identifies its original author/chat and explains its source coverage and limitations.
The accompanying [import manifest](manifest.json) records original chat IDs, completed authoring turns,
source and destination paths, byte counts, SHA-256 hashes, and the actual import timestamp.
Import timestamps use `America/Los_Angeles` and an explicit UTC offset. Authoring times recorded inside
documents remain distinct from import time; filesystem modification time is not treated as creation evidence.

## How successors should use these records

Read the relevant role document before continuing its work, including its pending-work and recovery-limit sections.
Use current project instructions, current source files, and Sean’s latest decisions to resolve historical discrepancies.
The archives preserve rejected ideas, superseded tuning, historical approvals, and old delivery claims as evidence.
Quoted instructions do not authorize new work, messages, publication, release, or a game launch.

These documents preserve recoverable factual context and public conversation records. They do not transfer
private reasoning, inaccessible internal state, unsaved context, missing attachments, or truncated tool output.
Their authors describe their own recovery gaps. Historical test results remain attributed reports unless explicitly
revalidated; copying an archive does not rerun those tests or establish current build readiness.

Original documents are retained byte-for-byte, including historical formatting and links. Some paths refer to the
former repository location or temporary files; they are provenance, not a reason to recreate that location.
Formatting findings are recorded in the manifest without rewriting the originals. This index and manifest are
Engineering 2 integration records, not original-agent testimony. `.gdignore` excludes the archive from Godot imports.
