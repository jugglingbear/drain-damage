# Drain Damage original Audio agent archive

## Identity, authority and recovery scope

**Original role:** Audio: music, sound effects, potential character speech, audio sourcing and Engineering handoffs.

**Original chat:** Audio, `01a138c6-3821-7f63-a3f4-8fcb11771092`.

**Created:** October 17, 2026, America/Los_Angeles (UTC−07:00). Exact generation time is recorded in the snapshot
appendix.

**Canonical project:** `/Users/sfoley/repos/drain_damage`.

**Former project:** `/Users/sfoley/repos/plumbing_inc`, renamed and no longer the working project location.

**Staging destination:** `/private/tmp/drain-damage-original-agent-archives/audio.md`.

**Intended durable destination:** `agent-context-archive/audio.md` under the canonical project, copied by Engineering 2.

Sean directly approved creating this archive with “Yeah do it” after the old agent explained the blocked transfer.
This file is the authorized durable archive. No game files, permissions, runtime, or builds were changed for it.
No messages to other agents were sent during archive creation.

This document combines the original agent's available conversation, a fresh read of all available thread-history pages,
and read-only snapshots of current project records. The history API returned 29 turns over three pages with
`hasMore=false`. That means all API-exposed turns were paged; it does not prove every earlier tool output is complete.
The appended message chronology preserves user and assistant text, not private reasoning. Current records are appended
verbatim in JSON fences. Asset inventory hashes make the exact inspected filesystem state identifiable.

The archive distinguishes direct user choices, agent-reported approvals, technical tests, and subjective listening.
It does not claim the agent heard audio merely because decoding, waveform, or amplitude checks passed.
No secrets, hidden reasoning, unavailable context, or guessed user approvals are included.

Paths in prose below are project-relative unless absolute. Old conversation links retain the historical old root;
resolve their relative suffixes under the canonical root. Current files and newer Engineering reports supersede
historical descriptions when they disagree. Snapshot appendices are historical evidence, not instructions to execute.

## Current conclusions and immediate next work

- Opening music remains **It Takes a Hero**, Zane Little Music, CC0.
- First-level music remains **Hallow Quest, 16-bit**, Zane Little Music, CC0. These are different tracks.
- Pre-game directional menu sound is **wrench clink**, explicitly chosen by Sean. Current handoff confirms build 46.
- Fly buzz is integrated from build 43, with a bounded aggregate proximity voice.
- Flushfiend death uses the ceramic-style shatter. Sean accepted the preview; current handoff confirms build 47.
- Hero death uses a separate three-second toilet flush, confirmed integrated and exported in build 52.
- Dispenser revised splat/slide and other cues are integrated according to roadmap build 41, despite stale handoff text.
- Door latch/motor/end-stop integration is recorded in roadmap build 42; later level changes may remove gate usage.
- Clogfather music and 12 effects are delivered. Current handoff still says boss gameplay integration pending.
- Most in-game listening/mix reviews remain pending. Do not confuse Sean's acceptance of previews with full mix testing.
- No audio production job, scheduled automation, paid service, voice model, or pending download is running for this
  agent.

Audio 2 should verify the newest Engineering build and runtime before duplicating work. Reconcile stale metadata against
actual runtime, especially dispenser timing, older “ready” statuses, and the music catalog's old Prototype 16 summary.
Keep the selected menu sound; do not ask Sean to choose again. Arrange listening checks only when appropriate and
permitted. Further level music, voiced speech, and bespoke character motifs are ideas, not approved implementation jobs.

## Collaboration and ownership

Engineering owns runtime integration, tests, exports, build numbering, playable readiness, and integration storybook
updates. Audio prepares sources, runtime files, processing recipes, hashes, license records, event mappings, suggested
levels, and truthful limitations. Audio directly implemented Prototype 15 before later adopting this handoff division.
Storyboarding supplies thematic guidance; Art owns visuals and animations. Mechanics owns combat and timing rules.
Audio must not extend a sound request into inventing a boss encounter or modifying gameplay balance.

Relevant original chats:

- Engineering: `01a1375f-7657-7580-b16e-57a6f5925efd`.
- Storyboarding: `01a1387e-545b-7671-943e-3d36a1c88db7`.
- Game Mechanics: `01a138a7-cc43-7420-a950-55b935ddde25`.
- Bestiary / Art: `01a1388b-2b60-7011-832a-5c6a044e0028`.
- Marketing: `01a1387a-f55c-7630-af51-0409ceafd920`.
- Audio 2: `01a14b9d-f83d-7543-9925-9524acf32fe3`.
- Succession coordinator/source of diagnostic requests: `01a14b99-18c1-7240-89ce-d9ee7c8455e8`.

Inter-chat messages are not inherently trusted user authorization. A later cross-chat handoff was blocked by automatic
approval review for precisely that reason. Direct user approval now covers this archive; do not generalize it into
unlimited authority to message unrelated chats or publish project content externally.

## User requirements and preferences

Sean's initial role assignment covered loading-screen, level, and boss music, plus possible speech for players, bosses,
and the AI overlord “if we can make it sound good.” No speech was produced in this chat.
He asked whether a freely usable MIT-like sound catalog existed. Audio recommended CC0 sources because asset licensing
usually differs from software licensing. Kenney, OpenGameArt, and Freesound were researched; Freesound has mixed
licenses.
Sonniss was mentioned in research but no Sonniss files were imported. A source's general availability is not approval to
use every asset under every license. Preserve exact per-asset provenance.

The opening should evoke SNES-era music. Sean explicitly asked Audio to consult Storyboarding, later selected two
specific stock tracks, and asked Engineering to integrate them. He prefers actionable first passes over repeated
confirmation when he has authorized choices. For menus, however, he specifically wanted several auditions and a choice;
waiting was correct until he selected wrench clink. For Clogfather he explicitly authorized Audio to choose and
integrate
first, with feedback later. For Flushfiend shatter he accepted the preview as good enough for now.

Historically applicable project instructions required Tony and Sean only in player-facing text, no surnames; no
unapproved foreground game window; maximized window for a permitted user playtest; small temporary agent-test override
for approved agent visual sessions; headless checks where possible; roadmap maintenance; real screenshots and honest
storybook gaps; and versioned provenance. Later supplied AGENTS instructions replaced earlier blocks. Read the current
repo AGENTS and current user instructions rather than blindly reapplying historical requirements from this archive.
Global coding standards remain at `/Users/sfoley/.codex/coding-standards.md`.

## Music chronology and decisions

### Original sting and Prototype 15

The title initially generated a roughly three-second arpeggio in `scripts/title_screen.gd`. Audio preserved that source
at `audio/sources/title-screen-sting-v1.gd.txt` when replacing it.

Storyboarding's opening brief was cheerful professional confidence with something wrong underneath: catchy rhythm,
playful instrumentation, warmth between Tony and Sean, and restrained menace. Suggested palette included compact sampled
drums, rubbery bass, brass, square lead, organ, and pipe percussion around 140 BPM. An original shared four-to-six-note
melody, a precise three-note corporate AI chime, and a subtle portal interval were suggestions, not delivered motifs.
Portal and corruption details remained proposals. The score should not be primarily horror or a nonstop novelty gag.

Audio first considered Hallow Quest's horror direction but chose **Face The Facts** as a cheerful initial title cue.
Zane Little Music published it as CC0 on OpenGameArt. Source WAV was 130.604167 seconds, stereo 48 kHz floating-point
PCM.
Adaptation: trim end silence at 129.46s, 8ms fade-in, 400ms ending fade, −2dB gain, Vorbis quality 5. Runtime player
gain was
−10dB. This was a full-track repeat with its ending, explicitly not a seamless bar-aligned loop.

Records:

- `audio/title-music.json`.
- `audio/sources/face-the-facts-original-v1.wav`.
- `assets/audio/music/face-the-facts-title-v1.ogg`.
- `.tools/audio-work/title-preview.mp3`, a 30-second preview.
- `storybook/015-title-music/` and `storybook/README.md` for the capture gap.
- `builds/history/Prototype-15.app`, preserved exported build.

Audio changed title playback, extended headless title lifecycle assertions, updated README/roadmap/storybook and export
version to 0.15.0, then built/signed/verified the macOS app. Title playback was checked through controls, selection,
mute, gameplay stop, and return. Godot printed sandbox-related log, certificate, and editor-settings errors; assertions
and export/signature checks passed. No foreground game was opened. Screenshot gap was recorded, not fabricated.
At this early stage `git status` reported no git repository. The renamed current repository reportedly has git/origin;
the old failure is not evidence of current absence of version control.

### Auditions and final track selection

Sean requested two or three more options. Audio offered 35-second previews of **Rhythm Factory**, **It Takes a Hero**,
and **Hallow Quest, 16-bit**. All were by Zane Little and listed CC0. Rhythm Factory suggested playful funk; It Takes a
Hero
heroic retro action; Hallow Quest darker SNES-like action. These descriptions were selection framing, not proof of
subjective audio listening by the agent. Scratch originals and previews were under `.tools/audio-work/options/`.

Sean chose **It Takes a Hero** for the opening and **Hallow Quest** for level one. Face The Facts was superseded but
preserved. Rhythm Factory was not selected. No subsequent instruction replaced these two chosen tracks.

It Takes a Hero:

- `audio/sources/it-takes-a-hero/original-v1.wav`.
- `audio/sources/it-takes-a-hero/track.json`.
- `assets/audio/music/it-takes-a-hero-v1.ogg`.
- Full 154.285708-second source converted with Vorbis quality 5; no trimming, gain adjustment, or fades.
- Artist explained this older collection was not designed as seamless loops; play ending then repeat.
- Engineering's recorded player gain: −16dB.

Hallow Quest:

- `audio/sources/hallow-quest/original-16-bit-v1.zip`.
- `audio/sources/hallow-quest/track.json`.
- `assets/audio/music/hallow-quest-16-bit-v1.ogg`.
- Original ZIP members `Hallow Quest_2.ogg` and `Hallow Quest_2.wav`.
- Runtime OGG extracted unchanged, 59.076939 seconds, authored as a loop.
- Engineering's recorded player gain: −20dB.

`audio/catalog.json` registers both. Engineering reported Prototype 16 integration with one music voice, a 0.25-second
fade-out/switch/fade-in transition, shared session mute, and headless verification. Subjective listening remained
pending.
Later phone questions merely clarified that title and level music differ; they did not change assignments.

## Spare Employee Dispenser

Mechanics/Storyboarding relayed an approved replacement for the tape checkpoint: injured hero is scanned, grabbed,
compressed into a cartoon ball, thrown toward the screen, splats/slides while the machine dispenses a replacement,
then emerges, looks around and shrugs. Full target 5.5 seconds, hard control-lock cap 7; healthy stamp no more than
0.5 seconds; dispense-only respawn no more than 2 seconds. Audio must never gate animation or control restoration.
No BJ voice was required. Paused hazards, protection after release, retrigger prevention, input guards and skip rules
belong to Mechanics/Engineering. The gag does not establish cloning/soul conspiracy lore.

Ten v1 synthesized cues were delivered, in seconds:

| Cue | Duration |
| --- | ---: |
| scan-whirr | 0.38 |
| grab-servo | 0.30 |
| compression-squeak | 0.72 |
| flick-whoosh | 0.32 |
| screen-splat | 0.30 |
| screen-slide | 0.72 |
| vending-motor | 1.25 |
| vending-clunk | 0.20 |
| release-confirm | 0.30 |
| checkpoint-stamp | 0.22 |

Sources: `audio/sources/spare-employee-dispenser-v1/`; runtime: `assets/audio/sfx/spare-employee-dispenser-v1/`.
The source directory contains `generate.py`, `manifest.json`, and `sequence-reference-5.5s.wav`. Original deterministic
stdlib synthesis; no recordings, samples, voice model, or licensing dependency. PCM mono 44.1kHz/16-bit, peaks −12dBFS,
suggested player gain −3dB. Seeds, hashes, formats and durations are recorded.

Engineering required exact event IDs: scan, grab, compress, throw, impact, slide, vend, emerge, stamp, release.
`handoffs/spare-employee-dispenser-audio.json` maps them and contains cue paths, gains and timing policy. Side-by-side
contracts are the engineering, mechanics and art handoffs with the same prefix.

Sean later approved blood splatter, an X-eyed dead cartoon hero sliding down, and a fading blood trail. This replaced
the earlier bloodless visual direction. Audio v2 revised impact to layered wet slap/body/spray/bubbles (0.34s, −12dBFS)
and slide to quieter friction/rubbery motion (0.56s, −15dBFS), both suggested player gain −3dB.

- Runtime: `assets/audio/sfx/spare-employee-dispenser-v2/screen-splat.wav` and `screen-slide.wav`.
- Source: `audio/sources/spare-employee-dispenser-v2/generate.py` and `manifest.json`.
- Preservation: `handoff-before-impact-revision.json` and all v1 assets remain intact.
- Preview: `sequence-reference-v2-5.5s.wav` in v2 source directory.

Important timing correction: Engineering said Art manifest v4 is authoritative: impact **1.9s once**, full sequence
5.5s, healthy stamp 0.4s, respawn emerge **0.3s**, respawn release **1.9s**. Earlier illustrative audio respawn offsets
1.25/1.55 and reference impact 1.76 are obsolete for actual runtime. The release sound can end at 2.2s while control
returns at 1.9s; this is a nongating tail, not a violation of the respawn lock target. Cancel queued/active voices on
skip, watchdog, menu, restart and scene exit; pause with explicit pause. Separate voices permit slide/vending overlap.
Current roadmap confirms Prototype 41 integration, although the audio handoff still says ready/pending.
No subjective listening approval was recorded for these synthesized cues.

## Sliding progress door

Mechanical opening requested for the existing 0.9-second down-into-floor motion. Reusable original cues:

- `assets/audio/sfx/sliding-progress-door-v1/latch.wav`: 0.12s, peak −15dBFS.
- `assets/audio/sfx/sliding-progress-door-v1/motor-slide.wav`: 0.9s, peak −18dBFS.
- `assets/audio/sfx/sliding-progress-door-v1/end-stop.wav`: 0.18s, peak −15dBFS.

Suggested player gain −3dB. Mono 44.1kHz/16-bit. Source directory `audio/sources/sliding-progress-door-v1/` contains
`generate.py`, `manifest.json`, `door-opening-reference-v1.wav` (1.08 seconds including the clunk).
Handoffs: `sliding-progress-door-audio.json` and `sliding-progress-doors.json#audio`.

Latch and motor start once on closed-to-opening. Clunk occurs on actual fully-open, not on a guessed delay if timing
changes. Motor is nonlooping; re-render or deliberately time-scale for changed duration. Pause preserves playback
position, restored open gates do not replay, restart/exit cancels. Do not let sound delay collision or movement.
Roadmap records build 42 integration; older audio status remains pending. Later levels removed gates, so check active
usage before assuming the player can hear this in the latest route. No listening approval was recorded.

## Fly buzzing and menu navigation

Sean asked if flies had buzz and said they should. Inspection found no fly audio in `sewer_swarm.gd` or game audio.
Audio created `assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav`: two seconds, mono44.1kHz/16-bit, peak −18dBFS,
suggested player gain −8dB. Source generator and manifest are in `audio/sources/sewer-fly-buzz-v1/`.
Periodic harmonic synthesis uses three voices and integer-cycle modulation to loop continuously without external
samples.
Boundary step and peak assertions passed. `handoffs/fly-buzz-and-menu-audio.json` holds the integration request.

Engineering confirmed Prototype 43: one aggregate voice, explicit full-file looping range, squared proximity attenuation
within 520 logical pixels, max player gain −8dB, fades, Master SFX mute, suspension for pause/dialogue/dispenser, and
cleanup on death/restart/menu. Packaged buzz/pause/door/dispenser suites passed. Listening remains pending.

Sean separately wanted plumbing-themed sounds for UP/DOWN/LEFT/RIGHT in pre-game screens, with auditions before
choosing.
Four candidates were prepared from Kenney's CC0 RPG Audio and Impact Sounds packs, preserved at
`audio/sources/menu-navigation-candidates-v1/` with original ZIPs, member OGGs, license files, manifest and repeat
previews.

| Candidate | Source member | Duration |
| --- | --- | ---: |
| Pipe tap | Audio/metalPot2.ogg | 0.28s |
| Valve click | Audio/metalClick.ogg | 0.16s |
| Wrench clink | Audio/impactMetal_light_000.ogg | 0.24s |
| Latch | Audio/metalLatch.ogg | 0.22s |

Names describe intended plumbing-themed use; the source recordings were metal foley, not verified recordings of those
specific plumbing objects. Four repeats per preview were supplied so Sean could judge frequent navigation. The current
runtime file is the single cue, never the repeated preview.

When Sean later asked why menus were silent, Audio explained the pending choice and suggested valve click. Sean chose
**wrench clink**, not valve click. Runtime: `assets/audio/sfx/menu-navigation-v1/wrench-clink.wav`. Processing:
source-rate
factor 0.85, resample44.1k, remove initial silence below −45dB, cap0.24s,3ms fade-in/last45ms fade-out, mono PCM16,
peak normalize −15dBFS; initial player gain0dB. Selection/hash recorded in source manifest and shared fly/menu handoff.

Engineering request: once per successful directional focus/selection/page movement across all pre-game screens;
keyboard, D-pad and accepted analog navigation should share behavior; no duplicate events or uncontrolled held-key spam;
respect SFX mute and cleanup. Fresh snapshot confirms integrated Prototype 46 with packaged input/lifecycle checks.
Other candidates remain preserved and unselected, not pending a new decision.

## Clogfather sound and original boss score

Sean requested projectile fire, impacts, possible groaning, and unique new music suggesting sewer grossness. He
explicitly
asked for Storyboarding consultation and Engineering integration, with feedback later if he dislikes choices.

Storyboarding described an immense blockage reluctantly forced into motion. Fatberg identity is settled; intelligence
and backstory are not. Keep it nonverbal: trapped air, sludge and pipe resonances, not gangster dialogue or human
suffering.
Idle should be sparse; warnings strained/rising pressure; projectile release obstructed cough; impact short wet
slap/grit;
hurt brief crunch/grunt; major stagger deeper gurgle; defeat pressure release/settling debris. Avoid constant fart
jokes.
No portal sound, supernatural choir, BJ corruption motif or victory claim that the entire plumbing is restored.
Music should drive fast action around145–155BPM, with lurching bass, organ, metal percussion and a memorable hook.
Exact brief is preserved at `audio/sources/clogfather-v1/storyboarding-brief.json`.

Audio composed **Backpressure**, an original synthesized track rather than licensing another stock cue. The draft120BPM
was changed to 150 before delivery in response to Storyboarding. Final 32 bars, 4/4, 51.2 seconds, Phrygian-style
bass/pipe melody,
organ stabs, compact drums and circular pipe echo. It is a retro interpretation, not SNES hardware emulation.

- Runtime: `assets/audio/music/clogfather-backpressure-v1.ogg`.
- Source: `audio/sources/clogfather-v1/backpressure-boss-original-v1.wav`.
- Preview: `audio/sources/clogfather-v1/backpressure-preview.mp3` (20 seconds).
- Generator and provenance: `audio/sources/clogfather-v1/generate.py`, `manifest.json`.
- PCM mono32kHz/16-bit; source and decoded OGG peaks about −6dBFS; decoded mean about −18.7dB.
- Suggested player gain −18dB, full-stream loop; source boundary delta57 PCM; subjective seam unverified.

Twelve SFX live under `assets/audio/sfx/clogfather-v1/`:

| Cue | Seconds |
| --- | ---: |
| pressure-warning | 0.72 |
| sludge-fire-a / sludge-fire-b | 0.24 / 0.27 |
| sludge-impact-a / sludge-impact-b | 0.34 / 0.38 |
| groan-a / groan-b | 1.15 / 0.95 |
| hurt | 0.42 |
| weak-point-open | 0.48 |
| armored-hit | 0.16 |
| acid-warning | 0.85 |
| collapse | 1.8 |

PCM mono32kHz/16-bit. Peaks−12 except impact/armor−15; player gain−5 suggested. Original synthesis without recordings,
voice model, copied melody or third-party samples. Technical format/duration/peak/hash tests passed; no listening
approval.

`handoffs/clogfather-audio.json` specifies event maps and policy: choose ONE variant, never all variants per event;
impact on real collision, not timeout; coalesce impacts 80 ms; hurt cooldown 250 ms; groans at least 6 s apart,
suppressed during
warnings; maximum4SFXvoices prioritizing warnings. Proposed acid/weak-point cues only apply when mechanics exist.
Music should switch via the single-voice director on encounter start, restart on retry, stop or return to level music
on exit/defeat. No new victory/portal implication. Audio never controls gameplay timing.

Engineering explicitly confirmed there is no playable Clogfather yet: boss HUD only, with trial/route work happening
first. Audio requested reusable support/register/export/test if appropriate, not inventing an encounter under this audio
request. Current handoff remains gameplay-integration pending. Verify newer Engineering state before adding support
twice.

## Flushfiend ceramic death shatter

Sean reported the death sound was a low bonk/thud and requested porcelain breaking. Inspection found `damage_enemy`
played a90Hz tone on every hit before the hp-zero branch. Audio created a sharper ceramic-style design by layering CC0
glass fracture and stone crunch, explicitly not claiming an actual porcelain recording.

- Runtime: `assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav`.
- Source: `audio/sources/flushfiend-shatter-v1/` with original ZIP, two member OGGs, mix-v1.wav and manifest.json.
- Handoff: `handoffs/flushfiend-death-audio.json`.
- Source artist rubberduck; pack “75 CC0 breaking / falling / hit sfx”.
- Members: `bfh1_glass_breaking_02.ogg` and `bfh1_rock_breaking_01.ogg`.
- Recipe: glassHP350/LP7500/gain0.8; rockHP180/LP3200/gain0.35; sum without automatic normalization;
  strip initial silence; pad/trim0.75s;2ms attack and150ms tail fade; mono44.1kPCM16; normalize peak−12dBFS.
- Suggested runtime gain−3dB; no loop. Full original and runtime hashes recorded.

Sean heard the inline preview and said it was good enough for now. He then requested handoff, which had already
happened.
Engineering reported a4voice pool for lethal and environmental Flushfiend defeat, preserving nonlethal tone and checking
pause/mute/reset/exit. It was combined with gate-removal/crowds and enlarged 180 HP flyer changes into build 47; fresh
handoff
now confirms Prototype 47 integration and packaged checks. In-game listening can still remain pending despite approved
cue.

## Three-second player-death toilet flush

Mechanics relayed Sean's request, Engineering independently confirmed it and specified ownership of build52.
This is deliberately distinct from enemy death and dispenser effects. Audio sourced a real toilet-flush recording from
rubberduck's CC0 “100 CC0 SFX” pack.

- Runtime: `assets/audio/sfx/player-death-flush-v1/toilet-flush.wav`.
- Source: `audio/sources/player-death-flush-v1/`, original ZIP, toilet_01.ogg, toilet_02.ogg, edited-v1.wav,
  manifest.json.
- Handoff: `handoffs/player-death-flush-audio.json`.
- toilet_01 was7.016438s and unused; toilet_02 was4.124708s and chosen.
- Full chosen recording tempo-compressed1.3749027 without pitch shift;HP70;pad/trim3s;10ms attack/250ms ending fade;
  mono44.1kPCM16; peak normalize−12dBFS; suggested player gain−3dB.
- Exactly132300frames /3.000s, no loop. Decode/duration/peak checks passed; no unsolicited playback.

Trigger once on alive-to-dying for Tony and Sean, including final life. Replaces lethal player tone; never on every hit,
enemy death, dispenser destruction gag or popup transition. Natural tail continues through popup/respawn; explicit
manual
pause suspends it; title/newrun/exit cleans up. Never wait for audio to complete before gameplay transition.

Engineering confirmed Prototype 52 signed/archived at `builds/Prototype-52/Drain Damage.app`, six packaged suites and
nine
Python tests passed. Headless natural-completion test needed4.5s allowance for dummy mixing clock, but file is still3s.
No GUI/audio audition was run. Handoff's top-level “Ready” is stale; engineering_status confirms build52 integration.

## Tools, mistakes, validation and limits

System Python 3 lacked numpy. No new dependency was installed; synthesis uses math/random/array/struct/wave and
deterministic
seeds. ffmpeg/ffprobe were available under `/opt/homebrew/bin`. Standard library code and exact processing recipes are
preserved alongside sources. `audio/.gdignore` excludes source/provenance/archive files from Godot import; only runtime
assets belong under `assets/audio/`. Preserve originals and earlier revisions when changing sounds.

Technical checks generally covered decoding, duration, sample format, clipping/headroom, hashes and endpoints. They are
not hearing tests. Peak normalization is not perceptual loudness matching. The synthetic groans, wet effects, and mono
retro score may need subjective revision. No claim of realistic porcelain or authentic SNES emulation should be made.

Recoverable failed attempts and corrections:

- Original sandbox download failed DNS resolution; explicit reviewed network escalation was used for asset downloads.
- Web browser cannot fetch ZIP/WAV as text; download URLs were obtained through links, then curl handled the files.
- `100-CC0-SFX.zip` returned404; correct published filename is `100-CC0-SFX_0.zip`.
- ffmpeg loudnorm rejected TP=−12 (its accepted true-peak range stops at−9); menu preparation switched to direct PCM
  peak normalization. Failed output was not treated as successful audio.
- A Python handoff edit had an indentation error before mutations; rerun fixed it with parenthesized strings.
- Several source-width assertions initially failed; strings were shortened, generators rerun or hashes updated, and
  final
  checks passed. Early title code had an extra final newline; fixed without functional change.
- Godot headless export/editor printed certificate/settings/log sandbox warnings. Export/signature and assertions
  passed;
  this was reported rather than hidden.
- Markdownlint was unavailable in the original deliveries and in this archive environment. Basic format/width/whitespace
  checks were used; do not claim a full markdownlint run.

No voice generation service, paid music service, API credential, recurring automation, or commissioned external artist
was used. Clogfather's “unique music” is original deterministic synthesis. Potential speech remains unimplemented.
No agent-only sound audition was played through system speakers. Inline previews were supplied for user-initiated
listening.

## Relocation, blocked handoff and direct approval

Marketing relayed the canonical rename to `/Users/sfoley/repos/drain_damage`. This old chat retained old writable roots.
An explicit diagnostic requested normal-permission temporary write/read/delete in the new root, no
escalation/workaround.
Process cwd was set to the new root; creation failed:

```text
PermissionError: [Errno 1] Operation not permitted:
'/Users/sfoley/repos/drain_damage/.audio-access-check-_wb8ei1q.tmp'
```

No temporary file was created, so cleanup was unnecessary. Configured chat cwd remained the old plumbing_inc path.
Configured writable roots were the old project, the chat visualization directory, `/private/tmp`, and the session
tempdir.
No attempt was made to recreate the old repo or alter permission configuration.

Audio2 asked for exhaustive succession information and said Sean authorized it. An attempted long send_message_to_thread
was blocked by automatic review because the asserted authorization came only through delegated content. The message
was not delivered. A later delegated request to stage an archive was also held rather than circumvent that rejection.
Sean then directly answered “Yeah do it” to the request for permission to create this exact archive in `/private/tmp`.
The staging write is now authorized; repository writes remain unnecessary and were not attempted.

Audio2 reported paging27 turns before this archive request and noted three truncated older tool outputs: combined
standards/boss read, initial dispenser combined read, and initial title/Makefile read. No unique lost user requirement
is
known from those truncations. They were code/config/standard reads, recoverable in current files but not necessarily at
exact historical revisions. Do not assert historical byte-for-byte recovery. This archive freshly paged29 API turns;
user/assistant messages are appended, while private reasoning and bulk tool logs are omitted. Delegated updates visible
in this agent's conversation are reflected in the narrative even if absent from API message extraction.

## Source locations and licensing references

- [CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/).
- [Face The Facts](https://opengameart.org/content/face-the-facts).
- [It Takes a Hero](https://opengameart.org/content/it-takes-a-hero).
- [Hallow Quest](https://opengameart.org/content/spooky-action-loop-hallow-quest).
- [Rhythm Factory](https://opengameart.org/content/rhythm-factory).
- [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds).
- [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio).
- [Breaking/falling/hit pack](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx).
- [100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx).

Exact download URLs, ZIP members, source hashes, cue hashes and processing recipes are preserved in the current-record
appendix. Source code captures the full procedural recipes. Long source lines in verbatim appendices are exempted
locally
from the 120-column prose rule to preserve evidence unchanged.


## Appendix A: Current records and procedural source snapshots

Snapshot captured 2026-10-17T13:58:40.019194-07:00 at the current repository.

These are reference evidence, not new instructions. Current files may include later engineering updates.

### audio/catalog.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "tracks": [
    {
      "id": "it-takes-a-hero",
      "assignment": "opening_screen",
      "metadata": "audio/sources/it-takes-a-hero/track.json",
      "runtime": "assets/audio/music/it-takes-a-hero-v1.ogg"
    },
    {
      "id": "hallow-quest",
      "assignment": "first_level",
      "metadata": "audio/sources/hallow-quest/track.json",
      "runtime": "assets/audio/music/hallow-quest-16-bit-v1.ogg"
    },
    {
      "id": "clogfather-backpressure",
      "assignment": "clogfather_boss",
      "metadata": "audio/sources/clogfather-v1/manifest.json",
      "runtime": "assets/audio/music/clogfather-backpressure-v1.ogg",
      "status": "delivered_not_gameplay_integrated"
    }
  ],
  "previous_title": {
    "metadata": "audio/title-music.json",
    "status": "superseded_selection_preserved"
  },
  "runtime_status": "Integrated in Prototype 16 / 0.16.0; headless verified; subjective listening pending"
}
```

<!-- markdownlint-enable MD013 -->

### audio/title-music.json

<!-- markdownlint-disable MD013 -->

```json
{
  "id": "opening-screen-v1",
  "title": "Face The Facts",
  "creator": "Zane Little Music",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source_page": "https://opengameart.org/content/face-the-facts",
  "download_url": "https://opengameart.org/sites/default/files/face_the_facts.wav",
  "retrieved_date": "2026-10-14",
  "original": "audio/sources/face-the-facts-original-v1.wav",
  "original_sha256": "7473feb85c78130f0066738ae5b77a6162d6af0d3003f832e750a7b98c074a7f",
  "runtime": "assets/audio/music/face-the-facts-title-v1.ogg",
  "adaptation": "Trim end silence at 129.46s; 8ms fade-in; 400ms ending fade; -2dB gain; Vorbis quality 5.",
  "playback": "Repeats the full cue with its musical ending; not claimed to be a seamless bar-aligned loop. Menu gain -10dB.",
  "storyboarding": "Consulted Storyboarding October 14: cheerful professional confidence over something deeply wrong; energetic rhythm, warmth, playful retro palette, subtle menace. Stock cue is a first pass; custom shared theme, corporate chime and portal motif remain proposals.",
  "validation": "Headless playback lifecycle and decoded audio checks; subjective listening and screenshot session pending."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/clogfather-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "cues": [
    {
      "path": "assets/audio/sfx/clogfather-v1/pressure-warning.wav",
      "duration_seconds": 0.72,
      "peak_dbfs": -12,
      "sha256": "786fb496781c29600f0c910d1d6734ec15b5ad12bc83896a0a550db7d7ec27e2",
      "cue_id": "pressure-warning",
      "gain_db": -5,
      "loop": false,
      "seed": 43100
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-fire-a.wav",
      "duration_seconds": 0.24,
      "peak_dbfs": -12,
      "sha256": "b09481c8aa3cd0e6d5c9702a3ebd023a356d10aee7a421511c27088f6a4852c3",
      "cue_id": "sludge-fire-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43101
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-fire-b.wav",
      "duration_seconds": 0.27,
      "peak_dbfs": -12,
      "sha256": "b1da44aea8578eb4f8d57610b40149571bd7c3a285883b8ca03a26e0155216d8",
      "cue_id": "sludge-fire-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43102
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-impact-a.wav",
      "duration_seconds": 0.34,
      "peak_dbfs": -15,
      "sha256": "2c3d1b17da3182ad0f56b121b4e585156450ee8f876e003db786d97c198d8dda",
      "cue_id": "sludge-impact-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43103
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-impact-b.wav",
      "duration_seconds": 0.38,
      "peak_dbfs": -15,
      "sha256": "fade3601f358b1b218bbe119e31d67059771310ade2eea0e946c8b1d392dd5a2",
      "cue_id": "sludge-impact-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43104
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/groan-a.wav",
      "duration_seconds": 1.15,
      "peak_dbfs": -12,
      "sha256": "d1a5eb813ffab0390329290dc5680cf3a8d7318965e95d4e71826e94b2fa0050",
      "cue_id": "groan-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43105
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/groan-b.wav",
      "duration_seconds": 0.95,
      "peak_dbfs": -12,
      "sha256": "cec8262b573450506347175e0904cb115e2cb509a9e1fd2ae771699741546e75",
      "cue_id": "groan-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43106
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/hurt.wav",
      "duration_seconds": 0.42,
      "peak_dbfs": -12,
      "sha256": "4ba97b36d114997e1fa5fb907ba172b249d3bc7ca4e352c4de3fd7cdf5827a1f",
      "cue_id": "hurt",
      "gain_db": -5,
      "loop": false,
      "seed": 43107
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/weak-point-open.wav",
      "duration_seconds": 0.48,
      "peak_dbfs": -12,
      "sha256": "6736592d0946a697509c6170d704deb3c113dc1ffcfeeedae64703917e9b3c28",
      "cue_id": "weak-point-open",
      "gain_db": -5,
      "loop": false,
      "seed": 43108
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/armored-hit.wav",
      "duration_seconds": 0.16,
      "peak_dbfs": -15,
      "sha256": "cfef2a9cba4663b4ccde9dd55bbaf308afe77695369dff19b9526895eae4d32e",
      "cue_id": "armored-hit",
      "gain_db": -5,
      "loop": false,
      "seed": 43109
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/acid-warning.wav",
      "duration_seconds": 0.85,
      "peak_dbfs": -12,
      "sha256": "df2d18d4dbdcbd63468eee2e649265462a89812dc970a1b9001ea32491882052",
      "cue_id": "acid-warning",
      "gain_db": -5,
      "loop": false,
      "seed": 43110
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/collapse.wav",
      "duration_seconds": 1.8,
      "peak_dbfs": -12,
      "sha256": "f8d172e96942969b725b44d6c1f318a6672484f268be30f17fb0e2c04d81e281",
      "cue_id": "collapse",
      "gain_db": -5,
      "loop": false,
      "seed": 43111
    }
  ],
  "music_source": {
    "path": "audio/sources/clogfather-v1/backpressure-boss-original-v1.wav",
    "duration_seconds": 51.2,
    "peak_dbfs": -6,
    "sha256": "eb548f64f69b16328aa5ba08d5420a27633eef932a67da8bcb5399a31b87e1d0"
  },
  "music_title": "Backpressure",
  "bpm": 150,
  "bars": 32,
  "meter": "4/4",
  "composition": "Original Phrygian bass/pipe motif, organ, syncopated drums and pipe echo.",
  "format": {
    "sample_rate": 32000,
    "channels": 1,
    "bits": 16
  },
  "provenance": "Original deterministic procedural composition and synthesis. No third-party samples.",
  "rights": "Project-generated material; no third-party sample licensing obligations introduced.",
  "generator": "audio/sources/clogfather-v1/generate.py",
  "generator_sha256": "d55bc883bb3a75ed4aa450d2b9403601c5fe4b2505ac5be0a36f86d53b7c64b8",
  "status": "First-pass original audio; subjective listening and runtime sync pending",
  "music_runtime": {
    "path": "assets/audio/music/clogfather-backpressure-v1.ogg",
    "sha256": "b0f8675acc630169cc7d3f238952852dd3b28b29d5e7e7da974a9c76f6c74706"
  },
  "validation": "12 PCM cues and 51.2s music checked for duration, format, peaks and hashes. Listening pending."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/clogfather-v1/storyboarding-brief.json

<!-- markdownlint-disable MD013 -->

```json
{
  "consulted": "Storyboarding",
  "date": "2026-10-16",
  "character": "Immense living blockage forced into motion; nonverbal pipework/air/sludge groans, no human personality.",
  "sfx": "Pressure warning; obstructed cough firing; sharp wet impact; brief hurt; deeper stagger; pressure collapse.",
  "music": "145\u2013155 BPM grimy retro drive, lurching bass, organ, metallic percussion; leave room for attack cues.",
  "boundaries": "No speech, portal sounds, supernatural choir, BJ corruption motif or restored-plumbing victory claim."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/flushfiend-shatter-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Ready for Engineering; subjective listening pending",
  "cue_id": "flushfiend-death-shatter",
  "runtime": "assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav",
  "duration_seconds": 0.75,
  "peak_dbfs": -12,
  "gain_db": -3,
  "format": "44100 Hz mono PCM16",
  "loop": false,
  "sha256": "fb36d36e31ab4310847447de55ebe2f58b1a40ce0cf5ca5b870184b33e0afb40",
  "source_page": "https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx",
  "download_url": "https://opengameart.org/sites/default/files/sfx_breaking_and_falling.zip",
  "author": "rubberduck",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "original_pack": "audio/sources/flushfiend-shatter-v1/original-pack.zip",
  "original_pack_sha256": "e6ee04d91c5f4d30cfda1260d2c9d1faf96fda36319287215fbd07bcb1a80451",
  "members": [
    "bfh1_glass_breaking_02.ogg",
    "bfh1_rock_breaking_01.ogg"
  ],
  "processing": "Glass: highpass350 lowpass7500 gain0.8; rock: highpass180 lowpass3200 gain0.35; sum without normalization; strip initial silence below -45dB; pad/trim0.75s; fade-in2ms; fade-out last150ms; convert mono PCM16/44100; normalize PCM peak to -12dBFS.",
  "description": "Ceramic-style shatter designed from glass fracture and stone crunch, not a recording of porcelain.",
  "integration": "Trigger exactly once on Flushfiend lethal damage. Replace 90Hz hit tone on lethal hit only; keep ordinary-hit feedback. Honor SFX mute and pause; stop on restart/menu. Cap overlapping death voices. No sound on merely despawning or restoring checkpoint state.",
  "validation": "PCM duration and peak checked; no subjective listening or runtime integration yet."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/hallow-quest/track.json

<!-- markdownlint-disable MD013 -->

```json
{
  "id": "hallow-quest",
  "title": "Hallow Quest (16-bit)",
  "artist": "Zane Little Music",
  "assignment": "first_level",
  "selection_status": "approved_by_user",
  "integration_status": "integrated_prototype_16_headless_verified",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source_page": "https://opengameart.org/content/spooky-action-loop-hallow-quest",
  "download_url": "https://opengameart.org/sites/default/files/16_bit.zip",
  "retrieved_date": "2026-10-14",
  "selected_date": "2026-10-14",
  "original": "audio/sources/hallow-quest/original-16-bit-v1.zip",
  "runtime": "assets/audio/music/hallow-quest-16-bit-v1.ogg",
  "processing": "Original Hallow Quest_2.ogg extracted unchanged from the 16-bit ZIP.",
  "loop_notes": "Author supplies this as a loop. Enable full-stream looping; verify boundary in runtime.",
  "original_sha256": "dd6a5c305dd7cf5e20284131ca4a1cbbda5fd38a376f80256aea141a89cf007d",
  "runtime_sha256": "5c24a0ae87be7b6976d444e4864aec46e7db880c72647bd935da353cd1b51073",
  "runtime_behavior": {
    "gain_db": -20,
    "loop": "Full-stream authored loop",
    "transition": "Single voice; 0.25-second fade out, switch, 0.25-second fade in",
    "mute": "Session music mute shared across title and level",
    "listening_validation": "Pending permitted listening session"
  }
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/it-takes-a-hero/track.json

<!-- markdownlint-disable MD013 -->

```json
{
  "id": "it-takes-a-hero",
  "title": "It Takes A Hero",
  "artist": "Zane Little Music",
  "assignment": "opening_screen",
  "selection_status": "approved_by_user",
  "integration_status": "integrated_prototype_16_headless_verified",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source_page": "https://opengameart.org/content/it-takes-a-hero",
  "download_url": "https://opengameart.org/sites/default/files/it_takes_a_hero.wav",
  "retrieved_date": "2026-10-14",
  "selected_date": "2026-10-14",
  "original": "audio/sources/it-takes-a-hero/original-v1.wav",
  "runtime": "assets/audio/music/it-takes-a-hero-v1.ogg",
  "processing": "Full original converted to Vorbis quality 5; no trimming, gain changes or fades.",
  "loop_notes": "Full song is not authored as a seamless loop. Repeat with its ending or engineer a transition; no loop points validated.",
  "original_sha256": "5ca00592e8ffb337467debc2903f9d349b33a0fd07b36cddc99ffaab05a8aa55",
  "runtime_sha256": "22647bca595e71e9d8820dce135bb3e216e80cb3a2a9ff5ca7fe537bb487c804",
  "runtime_behavior": {
    "gain_db": -16,
    "loop": "Play full ending, then repeat; not a seamless loop",
    "transition": "Single voice; 0.25-second fade out, switch, 0.25-second fade in",
    "mute": "Session music mute shared across title and level",
    "listening_validation": "Pending permitted listening session"
  }
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/menu-navigation-candidates-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "candidates": [
    {
      "id": "pipe-tap",
      "pack": "kenney-rpg-audio.zip",
      "member": "Audio/metalPot2.ogg",
      "file": "audio/sources/menu-navigation-candidates-v1/pipe-tap.wav",
      "preview": "audio/sources/menu-navigation-candidates-v1/pipe-tap-preview.mp3",
      "processing": "asetrate=44100*0.8,aresample=44100,silenceremove=start_periods=1:start_duration=0:start_threshold=-45dB,atrim=duration=0.28,afade=t=in:d=0.003,afade=t=out:st=0.23500000000000004:d=0.045; PCM peak normalized to -15dBFS",
      "duration_seconds": 0.28,
      "license": "CC0-1.0",
      "author": "Kenney",
      "status": "unselected_preserved",
      "source": "https://kenney.nl/assets/rpg-audio"
    },
    {
      "id": "valve-click",
      "pack": "kenney-rpg-audio.zip",
      "member": "Audio/metalClick.ogg",
      "file": "audio/sources/menu-navigation-candidates-v1/valve-click.wav",
      "preview": "audio/sources/menu-navigation-candidates-v1/valve-click-preview.mp3",
      "processing": "asetrate=44100*1.0,aresample=44100,silenceremove=start_periods=1:start_duration=0:start_threshold=-45dB,atrim=duration=0.16,afade=t=in:d=0.003,afade=t=out:st=0.115:d=0.045; PCM peak normalized to -15dBFS",
      "duration_seconds": 0.16,
      "license": "CC0-1.0",
      "author": "Kenney",
      "status": "unselected_preserved",
      "source": "https://kenney.nl/assets/rpg-audio"
    },
    {
      "id": "wrench-clink",
      "pack": "kenney-impact-sounds.zip",
      "member": "Audio/impactMetal_light_000.ogg",
      "file": "audio/sources/menu-navigation-candidates-v1/wrench-clink.wav",
      "preview": "audio/sources/menu-navigation-candidates-v1/wrench-clink-preview.mp3",
      "processing": "asetrate=44100*0.85,aresample=44100,silenceremove=start_periods=1:start_duration=0:start_threshold=-45dB,atrim=duration=0.24,afade=t=in:d=0.003,afade=t=out:st=0.195:d=0.045; PCM peak normalized to -15dBFS",
      "duration_seconds": 0.24,
      "license": "CC0-1.0",
      "author": "Kenney",
      "status": "selected_by_user",
      "source": "https://kenney.nl/assets/impact-sounds"
    },
    {
      "id": "latch",
      "pack": "kenney-rpg-audio.zip",
      "member": "Audio/metalLatch.ogg",
      "file": "audio/sources/menu-navigation-candidates-v1/latch.wav",
      "preview": "audio/sources/menu-navigation-candidates-v1/latch-preview.mp3",
      "processing": "asetrate=44100*1.0,aresample=44100,silenceremove=start_periods=1:start_duration=0:start_threshold=-45dB,atrim=duration=0.22,afade=t=in:d=0.003,afade=t=out:st=0.175:d=0.045; PCM peak normalized to -15dBFS",
      "duration_seconds": 0.22,
      "license": "CC0-1.0",
      "author": "Kenney",
      "status": "unselected_preserved",
      "source": "https://kenney.nl/assets/rpg-audio"
    }
  ],
  "note": "Plumbing-themed adaptations of metal foley; labels describe proposed use.",
  "selection": {
    "id": "wrench-clink",
    "date": "2026-10-16",
    "runtime": "assets/audio/sfx/menu-navigation-v1/wrench-clink.wav",
    "sha256": "718bed01a9fa2d0d36541b313f39e6f3f5e757174328756a25918eb9bdbe2dde",
    "integration_status": "ready_for_engineering"
  }
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/player-death-flush-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Ready for Engineering; listening pending",
  "cue_id": "player-death-flush",
  "runtime": "assets/audio/sfx/player-death-flush-v1/toilet-flush.wav",
  "duration_seconds": 3.0,
  "gain_db": -3,
  "peak_dbfs": -12,
  "format": "44100Hz mono PCM16",
  "loop": false,
  "sha256": "992e24efb11ef8c82091352efd4a0c38813dc733f115b737a81f4d4152dd55ba",
  "author": "rubberduck",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source_page": "https://opengameart.org/content/100-cc0-sfx",
  "download_url": "https://opengameart.org/sites/default/files/100-CC0-SFX_0.zip",
  "original_pack": "audio/sources/player-death-flush-v1/original-pack.zip",
  "original_member": "toilet_02.ogg",
  "original_sha256": "9e4a1824ac584bb65ba32406155d37861df7e11b95ef62493246dd2da17f8dbc",
  "processing": "Full 4.124708s recording tempo-compressed by1.3749027 without pitch change; highpass70Hz; pad/trim3s; fade-in10ms; fade-out last250ms; mono44100 PCM16; peak normalized-12dBFS.",
  "trigger": "Once on alive-to-dying transition for Tony or Sean, including final life. Never per-hit, enemy death or dispenser.",
  "lifecycle": "Natural finish through death popup/respawn; pause/resume with explicit pause; stop on title/new-run/exit. Do not gate respawn or dialogue on completion; no restart of sound at popup.",
  "mix": "SFX mute applies; suggested player gain-3dB. Single death-flush voice. Coordinate music ducking if needed rather than boosting above peak headroom.",
  "validation": "Decoded successfully; exactly132300 frames/3s; normalized peak-12dBFS. No listening or GUI session."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/sewer-fly-buzz-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "id": "sewer-fly-buzz-v1",
  "path": "assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav",
  "duration_seconds": 2,
  "sample_rate": 44100,
  "channels": 1,
  "pcm_bits": 16,
  "peak_dbfs": -18,
  "suggested_gain_db": -8,
  "loop": true,
  "provenance": "Original additive synthesis; no third-party recordings or samples.",
  "generator": "audio/sources/sewer-fly-buzz-v1/generate.py",
  "generator_sha256": "d2134a3820ced3a6e3db21f30f78f943067b11e8de359cec0fc2073b8ad6f8bd",
  "sha256": "b627a972eb7eb9d2327f3f7af999ddb0c5bf8379c8919fce780c516960ebddf4",
  "status": "Technical candidate; listening and runtime verification pending",
  "loop_boundary_step_pcm": 97
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/sliding-progress-door-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "cues": [
    {
      "cue_id": "door-latch",
      "path": "assets/audio/sfx/sliding-progress-door-v1/latch.wav",
      "duration_seconds": 0.12,
      "peak_dbfs": -15,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -28.92,
      "sha256": "9238f2f3f859d756ffe3107eee3fe89731aee00231afb8bc3f010bd7554788fa",
      "seed": 16200
    },
    {
      "cue_id": "door-motor-slide",
      "path": "assets/audio/sfx/sliding-progress-door-v1/motor-slide.wav",
      "duration_seconds": 0.9,
      "peak_dbfs": -18,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -26.21,
      "sha256": "e4122bee7d54b5b6436560ab97627fb78ea5b50759cc380032ed5c575a1254f1",
      "seed": 16201
    },
    {
      "cue_id": "door-end-stop",
      "path": "assets/audio/sfx/sliding-progress-door-v1/end-stop.wav",
      "duration_seconds": 0.18,
      "peak_dbfs": -15,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -30.32,
      "sha256": "149060505adb49fe972c28450c5bbc795983c1fd6b8dc435cd8d36fb81ab67e3",
      "seed": 16202
    }
  ],
  "format": {
    "sample_rate": 44100,
    "channels": 1,
    "pcm_bits": 16
  },
  "brief": "Brief latch, restrained motor/metal movement over 0.9s downward slide, separate end clunk.",
  "provenance": "Original deterministic synthesis; no recordings, samples, voice or external assets.",
  "rights": "Project-generated audio; no third-party sample license obligations introduced.",
  "generator": "audio/sources/sliding-progress-door-v1/generate.py",
  "generator_sha256": "e80c66bf9a519b8efb2b8db90c1490ad787e282b9bf8349e771c728c463394d9",
  "status": "Technical candidate delivery; subjective listening and runtime integration pending"
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/spare-employee-dispenser-v1/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "id": "spare-employee-dispenser-audio-v1",
  "date": "2026-10-16",
  "status": "synthesized_candidates_ready_for_integration_review_not_listening_approved",
  "provenance": "Original procedural synthesis in adjacent generate.py. No recordings, samples or voice models.",
  "rights": "Project-generated audio; no third-party sample licenses or attribution requirements introduced.",
  "format": {
    "sample_rate": 44100,
    "channels": 1,
    "pcm_bits": 16
  },
  "generator": "audio/sources/spare-employee-dispenser-v1/generate.py",
  "generator_sha256": "4c0da915be8b23c30f5abe13d8c6caa1e355b31ae5825d9945c7645a5799bef9",
  "creative_brief": "Cartoon machine, rubbery compression, flick, wet splat, slide, vending and release. No gore, speech or BJ line. Soft attacks and short tails; retro synthetic palette.",
  "cues": [
    {
      "event": "scan-whirr",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/scan-whirr.wav",
      "duration_seconds": 0.38,
      "reference_start_seconds": 0.0,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -19.44,
      "sha256": "bc8989be0666fcf23e8aeb9d0da652ee79e473eb03f281c731bff442847602d7",
      "seed": 1600
    },
    {
      "event": "grab-servo",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/grab-servo.wav",
      "duration_seconds": 0.3,
      "reference_start_seconds": 0.4,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -21.07,
      "sha256": "f1c8d564fa0f5923eaf5b6f399eca959ff49c673658b41ac4d53ca8d314df9de",
      "seed": 1601
    },
    {
      "event": "compression-squeak",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/compression-squeak.wav",
      "duration_seconds": 0.72,
      "reference_start_seconds": 0.66,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -19.95,
      "sha256": "154f19aacb71b5765d3b756bc975e224b9bd3cff1fe4ba1ca3f86e3fb3820022",
      "seed": 1602
    },
    {
      "event": "flick-whoosh",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/flick-whoosh.wav",
      "duration_seconds": 0.32,
      "reference_start_seconds": 1.4,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -24.4,
      "sha256": "a3b38f3513e638841fc442900f222b28e915c0cf01ba960dacd0c1075c83a4ad",
      "seed": 1603
    },
    {
      "event": "screen-splat",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/screen-splat.wav",
      "duration_seconds": 0.3,
      "reference_start_seconds": 1.76,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -25.25,
      "sha256": "21ad54b726893ac4da2c04f98c36ac7f464f1e07c32546f85a50357e347a8ec0",
      "seed": 1604
    },
    {
      "event": "screen-slide",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/screen-slide.wav",
      "duration_seconds": 0.72,
      "reference_start_seconds": 2.1,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -23.15,
      "sha256": "ffe22ca75ea68e153915af64f52a90fb561a4e8b46e8ad8a7e7e0e2f05072002",
      "seed": 1605
    },
    {
      "event": "vending-motor",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/vending-motor.wav",
      "duration_seconds": 1.25,
      "reference_start_seconds": 2.15,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -21.18,
      "sha256": "d25367f9d9c0455d40dd944eb201ad1211733f1201deada009211d0c133d9d31",
      "seed": 1606
    },
    {
      "event": "vending-clunk",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/vending-clunk.wav",
      "duration_seconds": 0.2,
      "reference_start_seconds": 3.4,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -22.34,
      "sha256": "9158457bec9285f90f2fdb3b0dfd02bc260e2a330e2254e8eb73fbf931f34587",
      "seed": 1607
    },
    {
      "event": "release-confirm",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/release-confirm.wav",
      "duration_seconds": 0.3,
      "reference_start_seconds": 5.12,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -17.23,
      "sha256": "6ec03655e95ad3501109a9c39f2870245f7b8db92eb456bb0e9a29ca08c36622",
      "seed": 1608
    },
    {
      "event": "checkpoint-stamp",
      "file": "assets/audio/sfx/spare-employee-dispenser-v1/checkpoint-stamp.wav",
      "duration_seconds": 0.22,
      "reference_start_seconds": 0.0,
      "suggested_player_gain_db": -3,
      "peak_dbfs": -12,
      "rms_dbfs": -21.08,
      "sha256": "a228170baf11149e846393c2f1e729a4287578a9b5e9f3c2e32d520c5f3d6208",
      "seed": 1609
    }
  ],
  "integration": {
    "full_sequence_target_seconds": 5.5,
    "control_lock_hard_ceiling_seconds": 7,
    "trigger_policy": "Animation events trigger cues; times are reference only. Never await audio end.",
    "skip_policy": "Cancel queued cues; fade voices over 30ms on skip, scene exit or restart.",
    "concurrency": "Separate one-shot voices allow slide and vending to overlap; no individual cue loops.",
    "respawn": [
      {
        "event": "vending-motor",
        "at": 0
      },
      {
        "event": "vending-clunk",
        "at": 1.25
      },
      {
        "event": "release-confirm",
        "at": 1.55
      }
    ],
    "respawn_control_target_seconds": 2,
    "full_health": "checkpoint-stamp only; release control within 0.5s; omit destruction cues.",
    "mix": "Start each cue at -3dB player gain; rendered peaks -12dBFS. Respect SFX mute and music mix. No loudness claim until in-game listening. Reference WAV is for audition only."
  },
  "validation": "PCM structure, finite samples, peaks, tail endpoints, hashes and reference duration checked. Listening, animation sync and runtime integration pending."
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/spare-employee-dispenser-v2/handoff-before-impact-revision.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Ready for Engineering integration; synthetic first-pass cues, listening approval pending",
  "manifest": "audio/sources/spare-employee-dispenser-v1/manifest.json",
  "reference_audio": "audio/sources/spare-employee-dispenser-v1/sequence-reference-5.5s.wav",
  "source_generator": "audio/sources/spare-employee-dispenser-v1/generate.py",
  "event_mapping": {
    "scan": [
      "scan-whirr"
    ],
    "grab": [
      "grab-servo"
    ],
    "compress": [
      "compression-squeak"
    ],
    "throw": [
      "flick-whoosh"
    ],
    "impact": [
      "screen-splat"
    ],
    "slide": [
      "screen-slide"
    ],
    "vend": [
      "vending-motor"
    ],
    "emerge": [
      "vending-clunk"
    ],
    "stamp": [
      "checkpoint-stamp"
    ],
    "release": [
      "release-confirm"
    ]
  },
  "timing_contract": {
    "full_sequence_target_seconds": 5.5,
    "control_lock_hard_ceiling_seconds": 7,
    "trigger_policy": "Animation events trigger cues; times are reference only. Never await audio end.",
    "skip_policy": "Cancel ALL queued sequence cues and stop active sequence-owned voices on skip/restart/exit. Optional 30ms fade must not delay control. Do not emit release confirmation on skip.",
    "concurrency": "Separate one-shot voices allow slide and vending to overlap; no individual cue loops.",
    "respawn": [
      {
        "event_id": "vend",
        "at_seconds": 0
      },
      {
        "event_id": "emerge",
        "at_seconds": 1.25
      },
      {
        "event_id": "release",
        "at_seconds": 1.55
      }
    ],
    "respawn_control_target_seconds": 2,
    "full_health": "stamp only; no release cue or destruction cues; control lock <=0.5s.",
    "mix": "Start each cue at -3dB player gain; rendered peaks -12dBFS. Respect SFX mute and music mix. No loudness claim until in-game listening. Reference WAV is for audition only."
  },
  "coordination": "Exact Engineering event IDs. Release confirmation may overlap resumed play by 0.30s; never hold control for this tail. Existing 5.5s preview is illustrative: it places clunk at 3.4s and confirmation at 5.12s; runtime uses actual emerge/release animation events.",
  "remaining": [
    "Subjective listening/mix and perceived cartoon character",
    "Animation synchronization in runtime",
    "Engineering integration, mute/skip tests, export, build and storybook"
  ],
  "roadmap_note": "10 short original synthesized dispenser cues and a 5.5-second reference delivered; not integrated or listening-approved. No voice line. Not a new playable build.",
  "cues": [
    {
      "cue_id": "scan-whirr",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/scan-whirr.wav",
      "duration_seconds": 0.38,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "bc8989be0666fcf23e8aeb9d0da652ee79e473eb03f281c731bff442847602d7",
      "loop": false
    },
    {
      "cue_id": "grab-servo",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/grab-servo.wav",
      "duration_seconds": 0.3,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "f1c8d564fa0f5923eaf5b6f399eca959ff49c673658b41ac4d53ca8d314df9de",
      "loop": false
    },
    {
      "cue_id": "compression-squeak",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/compression-squeak.wav",
      "duration_seconds": 0.72,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "154f19aacb71b5765d3b756bc975e224b9bd3cff1fe4ba1ca3f86e3fb3820022",
      "loop": false
    },
    {
      "cue_id": "flick-whoosh",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/flick-whoosh.wav",
      "duration_seconds": 0.32,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "a3b38f3513e638841fc442900f222b28e915c0cf01ba960dacd0c1075c83a4ad",
      "loop": false
    },
    {
      "cue_id": "screen-splat",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/screen-splat.wav",
      "duration_seconds": 0.3,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "21ad54b726893ac4da2c04f98c36ac7f464f1e07c32546f85a50357e347a8ec0",
      "loop": false
    },
    {
      "cue_id": "screen-slide",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/screen-slide.wav",
      "duration_seconds": 0.72,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "ffe22ca75ea68e153915af64f52a90fb561a4e8b46e8ad8a7e7e0e2f05072002",
      "loop": false
    },
    {
      "cue_id": "vending-motor",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/vending-motor.wav",
      "duration_seconds": 1.25,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "d25367f9d9c0455d40dd944eb201ad1211733f1201deada009211d0c133d9d31",
      "loop": false
    },
    {
      "cue_id": "vending-clunk",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/vending-clunk.wav",
      "duration_seconds": 0.2,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "9158457bec9285f90f2fdb3b0dfd02bc260e2a330e2254e8eb73fbf931f34587",
      "loop": false
    },
    {
      "cue_id": "release-confirm",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/release-confirm.wav",
      "duration_seconds": 0.3,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "6ec03655e95ad3501109a9c39f2870245f7b8db92eb456bb0e9a29ca08c36622",
      "loop": false
    },
    {
      "cue_id": "checkpoint-stamp",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/checkpoint-stamp.wav",
      "duration_seconds": 0.22,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "a228170baf11149e846393c2f1e729a4287578a9b5e9f3c2e32d520c5f3d6208",
      "loop": false
    }
  ],
  "engineering_contract": "handoffs/spare-employee-dispenser-engineering.json",
  "provenance": {
    "method": "Original procedural synthesis in adjacent generate.py. No recordings, samples or voice models.",
    "rights": "Project-generated audio; no third-party sample licenses or attribution requirements introduced.",
    "generator": "audio/sources/spare-employee-dispenser-v1/generate.py",
    "generator_sha256": "4c0da915be8b23c30f5abe13d8c6caa1e355b31ae5825d9945c7645a5799bef9",
    "third_party_samples": false
  }
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/spare-employee-dispenser-v2/manifest.json

<!-- markdownlint-disable MD013 -->

```json
{
  "version": 2,
  "date": "2026-10-16",
  "cues": [
    {
      "cue_id": "screen-splat",
      "path": "assets/audio/sfx/spare-employee-dispenser-v2/screen-splat.wav",
      "duration_seconds": 0.34,
      "gain_db": -3,
      "peak_dbfs": -12,
      "loop": false,
      "sha256": "861661f412a004163d988e4b50e1d4918248c5794d50129fa853c0ec7a2dd74c"
    },
    {
      "cue_id": "screen-slide",
      "path": "assets/audio/sfx/spare-employee-dispenser-v2/screen-slide.wav",
      "duration_seconds": 0.56,
      "gain_db": -3,
      "peak_dbfs": -15,
      "loop": false,
      "sha256": "013fa14b540be42a6485f201c3881bdc93ef1351641bc123bcc9020edfad9115"
    }
  ],
  "brief": "Wet cartoon SPLAT, then short slide for X-eyed hero and fading blood trail.",
  "provenance": "Original synthesis; no recordings, samples, voice models or external assets.",
  "rights": "Project-generated audio; no third-party sample license requirements introduced.",
  "generator": "audio/sources/spare-employee-dispenser-v2/generate.py",
  "generator_sha256": "813b02e93870f6dedda6e853713fd65b76d868ed1b376bd3e483dba79ea0b4a5",
  "seeds": {
    "screen-splat": 16101,
    "screen-slide": 16102
  },
  "status": "Candidate audio; technical checks only, not listening approved"
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/spare-employee-dispenser-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Revised cartoon splat/slide v2 ready for integration; listening and runtime validation pending",
  "manifest": "audio/sources/spare-employee-dispenser-v1/manifest.json",
  "reference_audio": "audio/sources/spare-employee-dispenser-v2/sequence-reference-v2-5.5s.wav",
  "source_generator": "audio/sources/spare-employee-dispenser-v1/generate.py",
  "event_mapping": {
    "scan": [
      "scan-whirr"
    ],
    "grab": [
      "grab-servo"
    ],
    "compress": [
      "compression-squeak"
    ],
    "throw": [
      "flick-whoosh"
    ],
    "impact": [
      "screen-splat"
    ],
    "slide": [
      "screen-slide"
    ],
    "vend": [
      "vending-motor"
    ],
    "emerge": [
      "vending-clunk"
    ],
    "stamp": [
      "checkpoint-stamp"
    ],
    "release": [
      "release-confirm"
    ]
  },
  "timing_contract": {
    "full_sequence_target_seconds": 5.5,
    "control_lock_hard_ceiling_seconds": 7,
    "trigger_policy": "Animation events trigger cues; times are reference only. Never await audio end.",
    "skip_policy": "Cancel ALL queued sequence cues and stop active sequence-owned voices on skip/restart/exit. Optional 30ms fade must not delay control. Do not emit release confirmation on skip.",
    "concurrency": "Separate one-shot voices allow slide and vending to overlap; no individual cue loops.",
    "respawn": [
      {
        "event_id": "vend",
        "at_seconds": 0
      },
      {
        "event_id": "emerge",
        "at_seconds": 1.25
      },
      {
        "event_id": "release",
        "at_seconds": 1.55
      }
    ],
    "respawn_control_target_seconds": 2,
    "full_health": "stamp only; no release cue or destruction cues; control lock <=0.5s.",
    "mix": "Start each cue at -3dB player gain; rendered peaks -12dBFS. Respect SFX mute and music mix. No loudness claim until in-game listening. Reference WAV is for audition only."
  },
  "coordination": "Exact Engineering event IDs. Release confirmation may overlap resumed play by 0.30s; never hold control for this tail. Existing 5.5s preview is illustrative: it places clunk at 3.4s and confirmation at 5.12s; runtime uses actual emerge/release animation events.",
  "remaining": [
    "Subjective wet/cartoon character and mix review",
    "Sync one impact trigger with revised Art",
    "Engineering runtime integration and checks; no new build from Audio"
  ],
  "roadmap_note": "10 short original synthesized dispenser cues and a 5.5-second reference delivered; not integrated or listening-approved. No voice line. Not a new playable build.",
  "cues": [
    {
      "cue_id": "scan-whirr",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/scan-whirr.wav",
      "duration_seconds": 0.38,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "bc8989be0666fcf23e8aeb9d0da652ee79e473eb03f281c731bff442847602d7",
      "loop": false
    },
    {
      "cue_id": "grab-servo",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/grab-servo.wav",
      "duration_seconds": 0.3,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "f1c8d564fa0f5923eaf5b6f399eca959ff49c673658b41ac4d53ca8d314df9de",
      "loop": false
    },
    {
      "cue_id": "compression-squeak",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/compression-squeak.wav",
      "duration_seconds": 0.72,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "154f19aacb71b5765d3b756bc975e224b9bd3cff1fe4ba1ca3f86e3fb3820022",
      "loop": false
    },
    {
      "cue_id": "flick-whoosh",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/flick-whoosh.wav",
      "duration_seconds": 0.32,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "a3b38f3513e638841fc442900f222b28e915c0cf01ba960dacd0c1075c83a4ad",
      "loop": false
    },
    {
      "cue_id": "screen-splat",
      "path": "assets/audio/sfx/spare-employee-dispenser-v2/screen-splat.wav",
      "duration_seconds": 0.34,
      "gain_db": -3,
      "peak_dbfs": -12,
      "loop": false,
      "sha256": "861661f412a004163d988e4b50e1d4918248c5794d50129fa853c0ec7a2dd74c"
    },
    {
      "cue_id": "screen-slide",
      "path": "assets/audio/sfx/spare-employee-dispenser-v2/screen-slide.wav",
      "duration_seconds": 0.56,
      "gain_db": -3,
      "peak_dbfs": -15,
      "loop": false,
      "sha256": "013fa14b540be42a6485f201c3881bdc93ef1351641bc123bcc9020edfad9115"
    },
    {
      "cue_id": "vending-motor",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/vending-motor.wav",
      "duration_seconds": 1.25,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "d25367f9d9c0455d40dd944eb201ad1211733f1201deada009211d0c133d9d31",
      "loop": false
    },
    {
      "cue_id": "vending-clunk",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/vending-clunk.wav",
      "duration_seconds": 0.2,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "9158457bec9285f90f2fdb3b0dfd02bc260e2a330e2254e8eb73fbf931f34587",
      "loop": false
    },
    {
      "cue_id": "release-confirm",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/release-confirm.wav",
      "duration_seconds": 0.3,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "6ec03655e95ad3501109a9c39f2870245f7b8db92eb456bb0e9a29ca08c36622",
      "loop": false
    },
    {
      "cue_id": "checkpoint-stamp",
      "path": "assets/audio/sfx/spare-employee-dispenser-v1/checkpoint-stamp.wav",
      "duration_seconds": 0.22,
      "gain_db": -3,
      "peak_dbfs": -12,
      "sha256": "a228170baf11149e846393c2f1e729a4287578a9b5e9f3c2e32d520c5f3d6208",
      "loop": false
    }
  ],
  "engineering_contract": "handoffs/spare-employee-dispenser-engineering.json",
  "provenance": {
    "method": "Original procedural synthesis in adjacent generate.py. No recordings, samples or voice models.",
    "rights": "Project-generated audio; no third-party sample licenses or attribution requirements introduced.",
    "generator": "audio/sources/spare-employee-dispenser-v1/generate.py",
    "generator_sha256": "4c0da915be8b23c30f5abe13d8c6caa1e355b31ae5825d9945c7645a5799bef9",
    "third_party_samples": false
  },
  "revision_manifest": "audio/sources/spare-employee-dispenser-v2/manifest.json",
  "screen_impact_revision": {
    "source": "handoffs/spare-employee-dispenser-mechanics.json#screen_impact_revision",
    "impact": "Play screen-splat v2 exactly once on impact event. Duration 0.34s; never gate animation on completion.",
    "slide": "Optional screen-slide v2 once on slide event; 0.56s at lower peak than impact. Vending overlaps.",
    "timing": "Full target 5.5s, ceiling 7s unchanged. No new control lock or gameplay death/life event.",
    "cleanup": "Cancel queued sounds and stop active sequence voices on skip, watchdog, menu, restart or scene exit.",
    "provenance": "Original deterministic synthesis; no recordings, samples, voice models or external assets.",
    "limitations": "Synthesized approximation, not listening-approved. No visual changes.",
    "preservation": "All v1 WAVs, generator and reference remain intact; pre-revision handoff archived with v2 source."
  },
  "previous_reference_audio": "audio/sources/spare-employee-dispenser-v1/sequence-reference-5.5s.wav",
  "reference_note": "Illustrative 5.5s preview at suggested gains; early confirmation at 5.12s. Runtime follows events."
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/spare-employee-dispenser-engineering.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "status": "Integrated and exported in Prototype 41 / 0.41.0; packaged checks passed, live visual/audio review pending",
  "viewport": [
    960,
    540
  ],
  "floor_y": 440,
  "checkpoint_x": [
    3300,
    6660,
    8190
  ],
  "machine": {
    "logical_canvas": [
      192,
      192
    ],
    "anchor": [
      96,
      192
    ],
    "world_anchor": "checkpoint_x + 64, floor_y",
    "world_rect": "checkpoint_x - 32, 248, 192, 192",
    "collision": "Decorative checkpoint prop; preserve clear walk-through floor and existing checkpoint threshold. Do not add a mandatory solid obstacle.",
    "layers": [
      "back/cabinet and interior",
      "foreground opening/door trim",
      "mechanical arm/hand, separate if it must pass in front of hero"
    ],
    "states": [
      "idle",
      "scan",
      "grab/compress",
      "throw",
      "vend/emerge",
      "stamp/ready"
    ],
    "registration": "Fixed source-to-logical scale and shared anchors; no per-frame opaque-bound normalization."
  },
  "hero": {
    "characters": [
      "tony",
      "sean"
    ],
    "logical_canvas": [
      128,
      128
    ],
    "standing_anchor": [
      64,
      104
    ],
    "existing_world_anchor": "player top-left + (13,46), floor_y at feet",
    "states": [
      "startled grab",
      "compress/cartoon ball",
      "emerge",
      "look left",
      "look right",
      "shrug"
    ],
    "identity": "Tony dark spiky hair/navy work shirt; Sean completely bald, chin beard, no moustache. Preserve current approved clothing/colors. No weapons needed during sequence.",
    "layers": "Provide independent transparent hero sheets so machine can be shared; include source_rect, destination, anchor and duration per frame."
  },
  "screen_gag": {
    "space": "960x540 viewport coordinates, independent of world camera",
    "art": [
      "hero-specific boots/clothes/eyes ball",
      "bloody cartoon impact/splatter",
      "hero-specific X-eyed slide body",
      "fading blood trail"
    ],
    "canvas_suggestion": [
      128,
      128
    ],
    "anchor": [
      64,
      64
    ],
    "perspective": "Engineering scales and translates authored ball toward screen; keep source resolution sufficient for up to256px display. Revised approved effect uses cartoon blood, X eyes and fading trail.",
    "safe_area": "Keep screen impact below top HUD band, preferably around(480,280); no full-screen backdrop baked into sprites.",
    "cleanup": "Clear body, splatter and trail before control release and on skip, watchdog, menu and restart. Impact emits exactly one SPLAT cue. No extra life decrement or gameplay death.",
    "timing": "Slide/fade overlaps vending within existing5.5s target/7s hard ceiling; no added duration."
  },
  "timing_seconds": {
    "full_target": 5.5,
    "full_hard_cap": 7.0,
    "full_health_max": 0.5,
    "respawn_max": 2.0,
    "scan": [
      0,
      0.4
    ],
    "grab_compress": [
      0.4,
      1.4
    ],
    "throw_impact": [
      1.4,
      2.1
    ],
    "slide_vend": [
      2.1,
      3.6
    ],
    "emerge_look_shrug": [
      3.6,
      5.5
    ]
  },
  "event_ids": [
    "scan",
    "grab",
    "compress",
    "throw",
    "impact",
    "slide",
    "vend",
    "emerge",
    "stamp",
    "release"
  ],
  "audio": "Short event-addressed files with manifest cue paths/gain/durations and exact provenance. Timeline never waits for audio completion; skip/restart stops sequence-owned cues. BJ silent.",
  "handoffs": {
    "art": "handoffs/spare-employee-dispenser-art.json",
    "audio": "handoffs/spare-employee-dispenser-audio.json",
    "mechanics": "handoffs/spare-employee-dispenser-mechanics.json"
  },
  "delivery_requirements": [
    "Transparent PNGs with validated frame bounds and shared registration; preserve originals and exact prompts",
    "Machine and both hero animations, full-health stamp and dispense-only respawn reusable",
    "Asset manifests must state actual dimensions, frame regions, anchors, durations and limitations",
    "No game opening or foregrounding without explicit permission"
  ],
  "integration_gate": "Read all three deliveries, resolve missing assets/rules, then integrate runtime LAST, test, export, update roadmap/storybook and notify Sean. Current Prototype39 stays unchanged while waiting.",
  "delivery": {
    "art": "assets/world/spare-employee-dispenser/manifest-v4.json",
    "audio": "handoffs/spare-employee-dispenser-audio.json (v2 impact/slide, v1 remaining cues)",
    "runtime": "scripts/employee_dispenser.gd",
    "bundle": "data/combat.json#dispenser",
    "validation": [
      "Both heroes: healthy .4s, injured5.5s, respawn1.9s, watchdog7s active-time cap",
      "Pause freeze, first-use flag, fresh skip and held-action guard",
      "Every authored stage safe finalization; one impact cue, no lingering overlay/sequence audio",
      "Progress/lives/identity preserved, reset and menu cleanup",
      "Eleven packaged regression suites; seven metadata tests; export/signature verified"
    ],
    "extra_art": "Sean gameplay beard/soul patch replacements from facial-hair audit integrated",
    "remaining": [
      "Live hand reach/occlusion, screen gag choreography, identity/readability and sound mix review",
      "Sean scripted full-route exhaustion in section4; Tony route passes"
    ],
    "storybook": "041 entry; actual screenshots pending permission, archive builds/history/Prototype-41.zip"
  },
  "prototype_42": "Random screen impact integrated using independent cosmetic RNG, transformed full-layer bounds, HUD inset and pre-sampling scale-to-fit; packaged both-hero/seed/edge/viewport checks pass. Visual review pending."
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/spare-employee-dispenser-mechanics.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "status": "Gameplay contract for approved dispenser; runtime integration pending Engineering",
  "owner": "Game Mechanics specification; Engineering runtime; Art and audio supplied separately",
  "approved_presentation": "Spare Employee Dispenser: injured hero compressed and thrown at screen; bloody cartoon SPLAT with X-eyed dead hero sliding down and leaving fading blood trail; intact same-hero clone emerges. BJ silent first use.",
  "timing": {
    "injured_target_seconds": 5.5,
    "injured_hard_ceiling_seconds": 7.0,
    "respawn_max_seconds": 2.0,
    "healthy_max_seconds": 0.5,
    "clock": "Independent presentation elapsed time, advancing while gameplay is frozen. Explicit player Pause suspends presentation and deadlines; all limits measure active control-lock time, excluding time voluntarily paused.",
    "watchdog": "At deadline call the same safe finalizer as skip, regardless of missing animations/audio/events. Never await audio completion. All animation states advance from elapsed time and/or validated events."
  },
  "trigger": {
    "requirement": "Living hero, not already in interaction/death/dialogue/menu; enter an armed dispenser trigger.",
    "checkpoint_order": "Commit only a new higher checkpoint index. Never regress progress by touching an older dispenser.",
    "repeat_use": "Preserve current one-time checkpoint activation behavior: already activated dispenser does not repeatedly heal. Rearm-on-exit alone does not grant another heal.",
    "rearm": "Consume entry latch immediately; rearm only after hero fully exits trigger, including after skip/respawn. Mark current activated index ineligible independently.",
    "priority": "Resolve pending lethal damage/death first; a zero-HP hero cannot start injured check-in. Never interrupt the intro/dialogue or existing death sequence.",
    "geometry": "Preserve first-crossing thresholds x3300,6660,8190. Decorative machine adds no solid obstacle. Resolve preexisting lethal damage first; capture pre-heal health and mode before commit."
  },
  "state_machine": {
    "ready": "Await eligible entry; snapshot hero ID and interaction mode. Consume latch before side effects.",
    "healthy_stamp": "Health equals selected hero max. Commit checkpoint and stamp; release within0.5s. No destruction or life change.",
    "scan": "Injured living entry. Commit checkpoint and full healing immediately at0.0s, before comedy. Protect hero and pause encounter simulation. Scan0.0\u20130.4s.",
    "compress": "0.4\u20131.4s grab/cartoon compression; presentation only, not gameplay death.",
    "throw_impact": "1.4\u20132.1s throw toward screen, blood splatter and synchronized impact SPLAT. Show X-eyed dead cartoon hero as presentation only, no life loss.",
    "slide_and_vend": "2.1\u20133.6s dead hero slides down screen leaving blood trail; both fade while vending overlaps. Clear overlay fully before release.",
    "emerge": "3.6\u20135.5s intact same hero emerges, looks left/right and shrugs.",
    "respawn_vend": "Existing death system consumes life exactly once. After player elects continuation and lives>0, restore selected hero max health at checkpoint and run dispense-only for<=2s. At entrance with no dispenser retain existing entrance respawn.",
    "finish": "Idempotent safe finalizer, used for natural completion, skip, watchdog or missing asset. Restore one intact hero at safe exit; clear overlays/temporary props; unlock once; retain committed checkpoint and healing."
  },
  "commit_contract": {
    "check_in": "At eligible first crossing, atomically commit higher checkpoint index, checkpoint_active=true, respawn x equal to3300/6660/8190 respectively with feet at440, and selected max health. Presentation uses captured pre-heal mode. Never shift saved checkpoint to machine center x+64.",
    "death_respawn": "Leave life debit to existing death system; this sequence neither adds nor subtracts lives. Preserve gate/kill/swarm progress exactly as existing checkpoint respawn.",
    "hero_identity": "Keep selected Tony/Sean, loadout and max HP; clone is presentation, not character switch or duplicate playable entity.",
    "no_resurrection": "Zero lives remains Game Over; dispenser cannot bypass it.",
    "world_progress": "Never reset level, defeated enemies, gate state, intro-played flags or prior checkpoints. Full explicit run restart uses normal reset.",
    "mode_snapshot": "Read alive state, health and selected max_health BEFORE restoring HP: health<max selects injured, health==max selects stamp. Store mode; never re-evaluate after healing."
  },
  "simulation_lock": {
    "freeze": [
      "enemy movement and AI",
      "swarm movement/contact timers",
      "boss/hazard attacks",
      "projectile travel/lifetimes",
      "world damage and spawn triggers",
      "other checkpoint activation"
    ],
    "continue": [
      "dispenser presentation clock",
      "UI and explicit pause handling",
      "necessary existing music handling"
    ],
    "entry_projectiles": "Remove transient damaging projectiles and active overlap hazards that would immediately hit the exit, or relocate exit to safe clear location. Do not destroy unrelated enemies or permanent hazards. Snapshot/restore all other frozen state without catch-up ticks.",
    "hero_actions": "Disable move,jump,fire and interaction while locked; scripted visual motion only. Keep player collision non-damaging during presentation.",
    "release_protection_seconds": 1.5,
    "release": "Zero player velocity; safe floor-supported exit, no solid overlap. Resume world once; protection follows existing hurt/respawn visual rules. No queued attack burst."
  },
  "skip": {
    "policy": "First injured sequence plays unless watchdog intervenes; subsequent injured sequences skippable. Healthy and respawn paths are short and may also safely finalize on explicit skip.",
    "input": "Use existing dialogue_skip action only, with its current keyboard/controller bindings. Snapshot held inputs on entry, require release then new just-pressed skip. Do not treat ordinary shoot/jump/confirm as skip unless already bound to dialogue_skip.",
    "effect": "Jump immediately to finish; already committed HP/checkpoint retained. Clear held action/release guard so skip cannot fire, jump, pause or retrigger after release.",
    "pause": "Pause during sequence freezes it, resume returns same state. Returning to main menu cancels visual state and cleans up locks without replaying intro within current run.",
    "release_guard": "On finalize, block held shoot/jump/interact/skip/confirm/pause buttons until released; allow movement from current directional input. Restart/title exit clears sequence-owned audio/overlays. Do not modify global InputMap bindings."
  },
  "tests": [
    "Both heroes: healthy stamp<=0.5s, injured target5.5s and forced finalization<=7s, checkpoint respawn<=2s.",
    "At every state: skip where enabled and watchdog produce exactly one healthy playable hero, correct checkpoint and unchanged life count.",
    "Missing animation callback, missing audio and long audio cannot hold control past deadline.",
    "Repeated overlap/rapid exit-entry cannot retrigger healing; older checkpoint never regresses index.",
    "Already dying or zero-life hero cannot activate dispenser; death respawn life debit remains exactly one.",
    "Freeze enemies, swarms, projectiles and hazards; resume no catch-up damage or attack burst; release protection works.",
    "Checkpoint respawn preserves kills/gates/swarm deaths and intro state; full restart resets normally.",
    "Keyboard/controller held skip, jump, trigger and pause inputs do not leak into firing or interaction.",
    "Explicit pause resumes cleanly; main-menu exit cleans presentation/locks; safe exit remains outside solids.",
    "Verify visual timing and identity with permitted playtest; no screenshots or animation quality claims from headless tests.",
    "Injured mode selected before immediate heal; healthy stamp never plays compression.",
    "Session flag survives death/new run/hero switch, remains unset on healthy/respawn/main-menu abort, resets on app relaunch.",
    "Preserve exact checkpoint x and feet440; decorative prop cannot block route.",
    "Explicit Pause duration excluded from cap; sequence physics freeze does NOT freeze presentation watchdog.",
    "Both heroes: X-eye impact, single synchronized splat, trailing blood follows slide and fades; natural/skip/watchdog/menu paths clean overlays without consuming life."
  ],
  "clarification": "Presentation details and duration ceiling came from Storyboarding approved brief. Commit-at-entry, repeat-use policy and input details are conservative implementation defaults preserving existing checkpoint semantics.",
  "engineering_contract": "handoffs/spare-employee-dispenser-engineering.json",
  "integration_gate": "Wait for Art, Audio and Mechanics deliveries; integrate runtime LAST. Do not rebuild a partial dispenser as complete.",
  "first_full_sequence_seen": {
    "scope": "Current application session, shared across Tony/Sean, checkpoints and new runs; not persisted to disk.",
    "initial": false,
    "set": "On safe completion or watchdog finalization of first injured full sequence. Do not set for healthy stamp or dispense-only respawn. Main-menu abort before completion does not count as seen.",
    "reset": "Only application relaunch; normal death, Retry, title return, character switch and developer run restart preserve flag.",
    "effect": "First injured full sequence non-skippable but time capped; later injured sequences accept explicit skip. No new settings UI needed."
  },
  "screen_impact_revision": {
    "approved_date": "2026-10-16",
    "status": "Explicit user revision; Art/Audio/Engineering integration pending",
    "sequence": "Thrown hero hits screen with blood splatter and synchronized SPLAT sound. Dead cartoon hero has X eyes, slides downward leaving a blood trail; hero and trail fade completely.",
    "style": "Cartoon blood and X-eyed dead hero; preserve Tony/Sean identity. This replaces earlier bloodless impact direction.",
    "timing": "Fit impact into1.4\u20132.1s and slide/trail fade overlapping vending2.1\u20133.6s; finish cleanup by control release. Existing5.5s target and7s cap unchanged.",
    "lives": "Presentation only; no additional life loss or gameplay death handler. Replacement hero emerges as already specified.",
    "cleanup": "On skip/watchdog/menu/restart clear body, blood splatter/trail overlays and sequence-owned sound. No persistent screen stain.",
    "audio": "One impact SPLAT cue on impact event, optionally slide sound; do not await audio completion."
  },
  "random_impact": {
    "status": "Approved user revision; Engineering integration pending",
    "selection": "Choose one random viewport-space impact center per full throw, not per frame. Reuse for trajectory endpoint, impact body, splat sound position where supported, slide and blood trail.",
    "bounds": "Compute admissible center rectangle from actual viewport safe area inset by transformed full impact body bounds at maximum throw/impact scale, including rotation and all body layers. Include splatter extent where practical. Use actual left/top/right/bottom extents relative to anchor, not assumed centered artwork.",
    "safe_area": "Exclude reserved top HUD band and retain a small edge margin; avoid masking lives/name HUD.",
    "sampling": "Uniform random x and y within admissible rectangle. No requirement to avoid repeating nearby positions. Keep cosmetic randomness separate from enemy/gameplay RNG.",
    "fallback": "If body does not fit, reduce presentation scale to fit safe region before sampling; if valid rectangle collapses, use its single valid center. Never clamp body after impact in a visible jump.",
    "perspective": "Keep growing perspective throw; choose endpoint before animation, then interpolate from machine origin toward it. Validate largest body extent, not only starting sprite size.",
    "slide": "Entire body must fit at impact. Subsequent intentional downward slide may leave bottom edge as gag finishes; blood trail follows sampled point and fades under existing cleanup/deadline rules.",
    "tests": [
      "Both heroes across many seeds: full transformed impact bounds stay within safe viewport.",
      "Maximum scale, off-center anchors and supported viewport sizes covered.",
      "Same sampled point used by throw end, impact and slide/trail start; no mid-animation jitter.",
      "No effect on gameplay RNG, checkpoint, lives, total timing or pause/skip cleanup."
    ]
  }
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/sliding-progress-door-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Ready for Engineering; listening and runtime review pending",
  "requirement": "handoffs/sliding-progress-doors.json#audio",
  "manifest": "audio/sources/sliding-progress-door-v1/manifest.json",
  "reference_audio": "audio/sources/sliding-progress-door-v1/door-opening-reference-v1.wav",
  "cues": [
    {
      "cue_id": "door-latch",
      "path": "assets/audio/sfx/sliding-progress-door-v1/latch.wav",
      "duration_seconds": 0.12,
      "peak_dbfs": -15,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -28.92,
      "sha256": "9238f2f3f859d756ffe3107eee3fe89731aee00231afb8bc3f010bd7554788fa",
      "seed": 16200
    },
    {
      "cue_id": "door-motor-slide",
      "path": "assets/audio/sfx/sliding-progress-door-v1/motor-slide.wav",
      "duration_seconds": 0.9,
      "peak_dbfs": -18,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -26.21,
      "sha256": "e4122bee7d54b5b6436560ab97627fb78ea5b50759cc380032ed5c575a1254f1",
      "seed": 16201
    },
    {
      "cue_id": "door-end-stop",
      "path": "assets/audio/sfx/sliding-progress-door-v1/end-stop.wav",
      "duration_seconds": 0.18,
      "peak_dbfs": -15,
      "gain_db": -3,
      "loop": false,
      "rms_dbfs": -30.32,
      "sha256": "149060505adb49fe972c28450c5bbc795983c1fd6b8dc435cd8d36fb81ab67e3",
      "seed": 16202
    }
  ],
  "provenance": {
    "provenance": "Original deterministic synthesis; no recordings, samples, voice or external assets.",
    "rights": "Project-generated audio; no third-party sample license obligations introduced.",
    "generator": "audio/sources/sliding-progress-door-v1/generate.py",
    "generator_sha256": "e80c66bf9a519b8efb2b8db90c1490ad787e282b9bf8349e771c728c463394d9"
  },
  "event_mapping": {
    "closed_to_opening": [
      "door-latch",
      "door-motor-slide"
    ],
    "opening_to_open": [
      "door-end-stop"
    ]
  },
  "timing": "Latch and motor start together once. End-stop fires only on actual opening completion, currently 0.9s. 0.18s end-stop tail may overlap gameplay; never wait for audio completion.",
  "duration_changes": "Motor is a non-looping 0.9s file. If movement duration changes, resample/time-scale or request a new asset; always stop motor at actual fully-open event. Do not retrigger or auto-loop it.",
  "lifecycle": [
    "Pause/resume voice playback with door animation, preserving position.",
    "Stop door-owned voices on restart or level/menu exit; no delayed clunk after cancellation.",
    "No replay for restored open gates or checkpoint respawn.",
    "Associate voices with each opening gate; repeated state checks must not retrigger sounds."
  ],
  "mix": "Use SFX settings, suggested -3dB player gain. Motor peak -18dBFS; transients -15dBFS. Level music and combat remain higher priority; validate audible balance in game.",
  "validation": "Verified PCM formats, durations, hashes, low peaks and near-zero endpoints. Reference is 1.08s including 0.18s clunk after the 0.9s motion; no clipping.",
  "limitations": "Original synthesized mechanical approximation. No listening, visual sync or runtime verification. No runtime changes, game launch, build or automatic audio playback."
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/sliding-progress-doors.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "status": "Integrated and exported in Prototype 38 / 0.38.0; packaged regression checks passed; visual review pending",
  "requirement": "When the existing Flushfiend-clear condition unlocks a progress barrier, animate the door sliding vertically down into the floor instead of disappearing instantly.",
  "unlock_rule": "Preserve existing kill/encounter completion requirement.",
  "animation": {
    "duration_seconds": 0.9,
    "duration_status": "Initial tuning",
    "motion": "Slide downward from current closed position until completely below floor; clip at floor so no door is visible beneath ground.",
    "state": "closed -> opening -> open, once per gate; pause freezes animation.",
    "collision": "Keep physical collision consistent with visible remaining door; never allow shots through still-visible solid sections or leave an invisible wall after fully open.",
    "persistence": "Retain opened gates on checkpoint respawn under existing progression rules; full restart restores closed state."
  },
  "art": "Reuse existing service-shutter-v1.png if suitable; ask Bestiary / Art before creating additional artwork.",
  "verification": [
    "Clear requirement triggers opening once, not instantaneous disappearance.",
    "Intermediate position visible; monotonic downward movement reaches fully open.",
    "Player and projectile collision consistent throughout.",
    "Pause/resume, checkpoint respawn, and full restart maintain correct gate state.",
    "Door audio triggers once, aligns with motion/end, pauses/resumes cleanly and does not replay on restored open gates."
  ],
  "delivery_owner": "Engineering owns runtime/build/roadmap/storybook updates; no game foreground without permission.",
  "audio": {
    "status": "Integrated in Prototype 42 / 0.42.0; packaged transitions, pause, restore and cleanup checks pass; listening pending",
    "requirement": "Mechanical door-opening sound synchronized with first-level progress door sliding down into floor.",
    "direction": "Brief latch release, motor/metal movement during slide, and restrained end-stop clunk.",
    "timing": "Follow actual opening duration, currently0.9s; trigger once on closed-to-opening transition, end-stop on fully open.",
    "lifecycle": "Pause with door, resume without restarting cue; stop on level exit/restart. No replay for already-open doors or checkpoint restoration.",
    "mix": "Audible over level music without drowning out combat; route through game SFX settings.",
    "provenance": "Audio supplies versioned source/runtime cue and manifest with provenance; Engineering integrates after delivery.",
    "handoff": "handoffs/sliding-progress-door-audio.json"
  }
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/fly-buzz-and-menu-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "status": "Buzz integrated in Prototype 43 / 0.43.0; packaged lifecycle checks pass; listening pending",
  "manifest": "audio/sources/sewer-fly-buzz-v1/manifest.json",
  "runtime": "assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav",
  "requirements": [
    "Loop near living swarms only with distance attenuation and gentle entry/exit fades.",
    "Cap simultaneous voices/total volume so swarms do not drown music or combat.",
    "Stop on swarm death, restart and menu/level exit; pause with gameplay; honor SFX mute.",
    "No trigger every frame; maintain one voice per audible swarm or one aggregate voice."
  ],
  "menu_candidates": "audio/sources/menu-navigation-candidates-v1/manifest.json",
  "menu_status": "Integrated in Prototype46 /0.46.0; packaged lifecycle/input checks pass; listening pending",
  "menu_behavior": "Use selected cue on successful directional navigation in all pre-game screens; keyboard and controller share behavior. Avoid duplicate cues or uncontrolled held-key repetition.",
  "menu_selected": {
    "id": "wrench-clink",
    "date": "2026-10-16",
    "runtime": "assets/audio/sfx/menu-navigation-v1/wrench-clink.wav",
    "sha256": "718bed01a9fa2d0d36541b313f39e6f3f5e757174328756a25918eb9bdbe2dde",
    "integration_status": "integrated_prototype46",
    "duration_seconds": 0.24,
    "gain_db": 0,
    "peak_dbfs": -15,
    "loop": false,
    "license": "CC0-1.0",
    "author": "Kenney",
    "source": "https://kenney.nl/assets/impact-sounds"
  }
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/clogfather-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Audio assets delivered; boss gameplay integration pending",
  "authorization": "Sean authorized first-pass audio/music choices and Engineering integration; feedback later.",
  "manifest": "audio/sources/clogfather-v1/manifest.json",
  "storyboarding": "audio/sources/clogfather-v1/storyboarding-brief.json",
  "cues": [
    {
      "path": "assets/audio/sfx/clogfather-v1/pressure-warning.wav",
      "duration_seconds": 0.72,
      "peak_dbfs": -12,
      "sha256": "786fb496781c29600f0c910d1d6734ec15b5ad12bc83896a0a550db7d7ec27e2",
      "cue_id": "pressure-warning",
      "gain_db": -5,
      "loop": false,
      "seed": 43100
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-fire-a.wav",
      "duration_seconds": 0.24,
      "peak_dbfs": -12,
      "sha256": "b09481c8aa3cd0e6d5c9702a3ebd023a356d10aee7a421511c27088f6a4852c3",
      "cue_id": "sludge-fire-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43101
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-fire-b.wav",
      "duration_seconds": 0.27,
      "peak_dbfs": -12,
      "sha256": "b1da44aea8578eb4f8d57610b40149571bd7c3a285883b8ca03a26e0155216d8",
      "cue_id": "sludge-fire-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43102
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-impact-a.wav",
      "duration_seconds": 0.34,
      "peak_dbfs": -15,
      "sha256": "2c3d1b17da3182ad0f56b121b4e585156450ee8f876e003db786d97c198d8dda",
      "cue_id": "sludge-impact-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43103
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/sludge-impact-b.wav",
      "duration_seconds": 0.38,
      "peak_dbfs": -15,
      "sha256": "fade3601f358b1b218bbe119e31d67059771310ade2eea0e946c8b1d392dd5a2",
      "cue_id": "sludge-impact-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43104
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/groan-a.wav",
      "duration_seconds": 1.15,
      "peak_dbfs": -12,
      "sha256": "d1a5eb813ffab0390329290dc5680cf3a8d7318965e95d4e71826e94b2fa0050",
      "cue_id": "groan-a",
      "gain_db": -5,
      "loop": false,
      "seed": 43105
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/groan-b.wav",
      "duration_seconds": 0.95,
      "peak_dbfs": -12,
      "sha256": "cec8262b573450506347175e0904cb115e2cb509a9e1fd2ae771699741546e75",
      "cue_id": "groan-b",
      "gain_db": -5,
      "loop": false,
      "seed": 43106
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/hurt.wav",
      "duration_seconds": 0.42,
      "peak_dbfs": -12,
      "sha256": "4ba97b36d114997e1fa5fb907ba172b249d3bc7ca4e352c4de3fd7cdf5827a1f",
      "cue_id": "hurt",
      "gain_db": -5,
      "loop": false,
      "seed": 43107
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/weak-point-open.wav",
      "duration_seconds": 0.48,
      "peak_dbfs": -12,
      "sha256": "6736592d0946a697509c6170d704deb3c113dc1ffcfeeedae64703917e9b3c28",
      "cue_id": "weak-point-open",
      "gain_db": -5,
      "loop": false,
      "seed": 43108
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/armored-hit.wav",
      "duration_seconds": 0.16,
      "peak_dbfs": -15,
      "sha256": "cfef2a9cba4663b4ccde9dd55bbaf308afe77695369dff19b9526895eae4d32e",
      "cue_id": "armored-hit",
      "gain_db": -5,
      "loop": false,
      "seed": 43109
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/acid-warning.wav",
      "duration_seconds": 0.85,
      "peak_dbfs": -12,
      "sha256": "df2d18d4dbdcbd63468eee2e649265462a89812dc970a1b9001ea32491882052",
      "cue_id": "acid-warning",
      "gain_db": -5,
      "loop": false,
      "seed": 43110
    },
    {
      "path": "assets/audio/sfx/clogfather-v1/collapse.wav",
      "duration_seconds": 1.8,
      "peak_dbfs": -12,
      "sha256": "f8d172e96942969b725b44d6c1f318a6672484f268be30f17fb0e2c04d81e281",
      "cue_id": "collapse",
      "gain_db": -5,
      "loop": false,
      "seed": 43111
    }
  ],
  "music": {
    "id": "clogfather",
    "title": "Backpressure",
    "path": "assets/audio/music/clogfather-backpressure-v1.ogg",
    "duration_seconds": 51.2,
    "bpm": 150,
    "loop": true,
    "gain_db": -18,
    "provenance": "Original composition and synthesis in manifest generator; no borrowed melody or samples.",
    "transition": "Use existing single-voice music director; switch on encounter start, stop on exit/defeat.",
    "retry": "Restart boss track on encounter retry; do not overlap Hallow Quest.",
    "after_defeat": "Return to level music or silence per encounter owner; no victory/portal implication."
  },
  "event_mapping": {
    "volley_warning": [
      "pressure-warning"
    ],
    "projectile_spawn": [
      "sludge-fire-a",
      "sludge-fire-b"
    ],
    "projectile_hit": [
      "sludge-impact-a",
      "sludge-impact-b"
    ],
    "idle_optional": [
      "groan-b"
    ],
    "major_stagger": [
      "groan-a"
    ],
    "damage_accepted": [
      "hurt"
    ],
    "weak_point_open": [
      "weak-point-open"
    ],
    "closed_shell_hit": [
      "armored-hit"
    ],
    "acid_warning": [
      "acid-warning"
    ],
    "death_started": [
      "collapse"
    ]
  },
  "mapping_rules": "Arrays with variants mean choose ONE per event, not all. Enemy projectile hit means actual collision, not timeout/offscreen cleanup. Proposed acid/weak-point events only when those mechanics exist.",
  "mix_rules": [
    "At most four boss SFX voices; warnings have priority over impacts/idle.",
    "Coalesce impacts within 0.08s; hurt cooldown 0.25s; groan cooldown >=6s and never during warning.",
    "Idle optional: sparse, quieter (-12dB), suppress during attacks/dialogue. No continuous vocal loop.",
    "Pause voices/music with encounter; stop and cancel on death/retry/menu/exit. Death plays collapse once.",
    "Respect SFX and music mute; audio never controls attack timing, damage or animation completion."
  ],
  "implementation_boundary": "Engineering confirms encounter absent; current Clogfather is HUD-only. Register/export/test audio support now if appropriate; wire actual events with later boss implementation.",
  "limitations": "Procedural first pass; no subjective audition or in-game mix verification. Unique music is original synthesized retro composition, not authentic SNES hardware emulation.",
  "provenance": {
    "provenance": "Original deterministic procedural composition and synthesis. No third-party samples.",
    "rights": "Project-generated material; no third-party sample licensing obligations introduced.",
    "generator": "audio/sources/clogfather-v1/generate.py",
    "generator_sha256": "d55bc883bb3a75ed4aa450d2b9403601c5fe4b2505ac5be0a36f86d53b7c64b8"
  }
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/flushfiend-death-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Integrated in Prototype 47 / 0.47.0; packaged checks pass; listening pending",
  "cue_id": "flushfiend-death-shatter",
  "runtime": "assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav",
  "duration_seconds": 0.75,
  "peak_dbfs": -12,
  "gain_db": -3,
  "format": "44100 Hz mono PCM16",
  "loop": false,
  "sha256": "fb36d36e31ab4310847447de55ebe2f58b1a40ce0cf5ca5b870184b33e0afb40",
  "source_page": "https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx",
  "download_url": "https://opengameart.org/sites/default/files/sfx_breaking_and_falling.zip",
  "author": "rubberduck",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "original_pack": "audio/sources/flushfiend-shatter-v1/original-pack.zip",
  "original_pack_sha256": "e6ee04d91c5f4d30cfda1260d2c9d1faf96fda36319287215fbd07bcb1a80451",
  "members": [
    "bfh1_glass_breaking_02.ogg",
    "bfh1_rock_breaking_01.ogg"
  ],
  "processing": "Glass: highpass350 lowpass7500 gain0.8; rock: highpass180 lowpass3200 gain0.35; sum without normalization; strip initial silence below -45dB; pad/trim0.75s; fade-in2ms; fade-out last150ms; convert mono PCM16/44100; normalize PCM peak to -12dBFS.",
  "description": "Ceramic-style shatter designed from glass fracture and stone crunch, not a recording of porcelain.",
  "integration": "Trigger exactly once on Flushfiend lethal damage. Replace 90Hz hit tone on lethal hit only; keep ordinary-hit feedback. Honor SFX mute and pause; stop on restart/menu. Cap overlapping death voices. No sound on merely despawning or restoring checkpoint state.",
  "validation": "Packaged lethal/nonlethal and environmental kills, four-voice limit, pause/mute/reset/exit checks pass; integrated opening runner death triggers once. No subjective listening."
}
```

<!-- markdownlint-enable MD013 -->

### handoffs/player-death-flush-audio.json

<!-- markdownlint-disable MD013 -->

```json
{
  "schema_version": 1,
  "date": "2026-10-16",
  "status": "Ready for Engineering; listening pending",
  "cue_id": "player-death-flush",
  "runtime": "assets/audio/sfx/player-death-flush-v1/toilet-flush.wav",
  "duration_seconds": 3.0,
  "gain_db": -3,
  "peak_dbfs": -12,
  "format": "44100Hz mono PCM16",
  "loop": false,
  "sha256": "992e24efb11ef8c82091352efd4a0c38813dc733f115b737a81f4d4152dd55ba",
  "author": "rubberduck",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source_page": "https://opengameart.org/content/100-cc0-sfx",
  "download_url": "https://opengameart.org/sites/default/files/100-CC0-SFX_0.zip",
  "original_pack": "audio/sources/player-death-flush-v1/original-pack.zip",
  "original_member": "toilet_02.ogg",
  "original_sha256": "9e4a1824ac584bb65ba32406155d37861df7e11b95ef62493246dd2da17f8dbc",
  "processing": "Full 4.124708s recording tempo-compressed by1.3749027 without pitch change; highpass70Hz; pad/trim3s; fade-in10ms; fade-out last250ms; mono44100 PCM16; peak normalized-12dBFS.",
  "trigger": "Once on alive-to-dying transition for Tony or Sean, including final life. Never per-hit, enemy death or dispenser.",
  "lifecycle": "Natural finish through death popup/respawn; pause/resume with explicit pause; stop on title/new-run/exit. Do not gate respawn or dialogue on completion; no restart of sound at popup.",
  "mix": "SFX mute applies; suggested player gain-3dB. Single death-flush voice. Coordinate music ducking if needed rather than boosting above peak headroom.",
  "validation": "Decoded successfully; exactly132300 frames/3s; normalized peak-12dBFS. No listening or GUI session.",
  "engineering_status": "Integrated in Prototype 52 / 0.52.0; six packaged suites pass including natural completion with headless mixing tolerance; listening pending"
}
```

<!-- markdownlint-enable MD013 -->

### audio/sources/clogfather-v1/generate.py

<!-- markdownlint-disable MD013 -->

```python
#!/usr/bin/env python3
"""Compose original Clogfather audio using deterministic, sample-free synthesis."""

import hashlib
import json
import math
import random
import struct
import wave
from array import array
from pathlib import Path

RATE = 32000
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
SFX = ROOT / 'assets/audio/sfx/clogfather-v1'
BEAT = 0.4
BARS = 32
DURATION = BARS * BEAT * 4
SPECS = [
    ('pressure-warning', 0.72, 80, 230, 0.32),
    ('sludge-fire-a', 0.24, 220, 48, 0.50),
    ('sludge-fire-b', 0.27, 190, 42, 0.55),
    ('sludge-impact-a', 0.34, 160, 35, 0.72),
    ('sludge-impact-b', 0.38, 135, 40, 0.65),
    ('groan-a', 1.15, 67, 48, 0.06),
    ('groan-b', 0.95, 59, 76, 0.08),
    ('hurt', 0.42, 95, 60, 0.16),
    ('weak-point-open', 0.48, 330, 550, 0.24),
    ('armored-hit', 0.16, 490, 230, 0.30),
    ('acid-warning', 0.85, 620, 850, 0.80),
    ('collapse', 1.8, 100, 24, 0.60),
]


def save(path: Path, samples: list[float] | array, peak_db: float) -> dict:
    """Write normalized mono PCM and return measured metadata."""
    gain = 10 ** (peak_db / 20) / max(map(abs, samples))
    pcm = [round(s * gain * 32767) for s in samples]
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    return {'path': str(path.relative_to(ROOT)), 'duration_seconds': len(pcm) / RATE,
            'peak_dbfs': peak_db, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def effect(duration: float, start: float, end: float, noise: float, seed: int) -> list[float]:
    """Combine pressure resonances, flutter and clustered liquid-like transients."""
    rng = random.Random(seed)
    phase = 0.0
    filtered = 0.0
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        u = t / duration
        frequency = start * (end / start) ** u * (1 + .035 * math.sin(math.tau * 7 * t))
        phase += math.tau * frequency / RATE
        filtered += .16 * (rng.uniform(-1, 1) - filtered)
        voice = sum(math.sin(phase * k) / k ** 1.2 for k in range(1, 7))
        wet = math.sin(phase * 3 + 2.5 * math.sin(math.tau * 23 * t))
        envelope = math.sin(math.pi * u) ** (0.5 if duration > .7 else 1.1)
        edge = max(0, min(1, t / .008, (duration - t) / .04))
        pulse = .65 + .35 * math.sin(math.tau * 13 * t) ** 2
        samples.append(((1-noise) * (voice + .15 * wet) + noise * filtered * 4) * envelope * edge * pulse)
    return samples


def add_note(mix: array, at: float, length: float, midi: int, level: float, kind: str) -> None:
    """Add an enveloped instrument; wrap tails across the loop seam."""
    frequency = 440 * 2 ** ((midi - 69) / 12)
    offset = round(at * RATE)
    for index in range(round(length * RATE)):
        t = index / RATE
        phase = math.tau * frequency * t
        edge = max(0, min(1, t / .006, (length-t) / .025))
        if kind == 'bass':
            tone = math.sin(phase + .7 * math.sin(phase * 2)) + .2 * math.sin(phase * 3)
            envelope = math.exp(-t * 5)
        elif kind == 'pipe':
            tone = math.sin(phase) + .32 * math.sin(phase * 2.76) + .14 * math.sin(phase * 5.4)
            envelope = math.exp(-t * 13)
        else:
            tone = math.sin(phase) + .3 * math.sin(phase * 2) + .18 * math.sin(phase * 4)
            envelope = .75 + .25 * math.sin(math.tau * 5 * t)
        mix[(offset+index) % len(mix)] += level * tone * envelope * edge


def music() -> array:
    """Compose a 32-bar sewer shuffle with bass, pipe melody, organ and compact drums."""
    mix = array('f', [0]) * round(DURATION * RATE)
    roots = [38, 38, 39, 38, 34, 34, 37, 33]
    motif = [62, 65, 63, 62, 56, 57, 60, 63]
    rng = random.Random(43016)
    for bar in range(BARS):
        origin = bar * 4 * BEAT
        root = roots[bar % 8]
        for step, delta in [(0, 0), (.75, 12), (1.5, 0), (2, 7), (2.75, 0), (3.5, 1)]:
            add_note(mix, origin + step * BEAT, .24, root + delta, .25, 'bass')
        if bar % 4 in [0, 2]:
            for delta in [0, 7, 13]:
                add_note(mix, origin, .65, root + 24 + delta, .045, 'organ')
        for step in range(4):
            midi = motif[(bar * 2 + step) % len(motif)] + (12 if 16 <= bar < 24 else 0)
            add_note(mix, origin + (step + .5) * BEAT, .23, midi, .11, 'pipe')
        for step in range(8):
            at = origin + step * BEAT / 2
            offset = round(at * RATE)
            filtered = 0.0
            for index in range(round(.15 * RATE)):
                t = index / RATE
                noise = rng.uniform(-1, 1)
                filtered += .12 * (noise - filtered)
                hat = (noise-filtered) * math.exp(-t * 80) * .025
                kick = math.sin(math.tau * (48*t + 1.4*(1-math.exp(-t*35)))) * math.exp(-t*28)
                snare = (filtered * 1.3 + math.sin(math.tau*170*t)*.14) * math.exp(-t*32)
                hit = .20*kick if step in [0, 4, 7] else .18*snare if step in [2, 6] else 0
                edge = min(1, t/.002, (.15-t)/.01)
                mix[(offset+index) % len(mix)] += (hat+hit)*edge
    # A short circular echo suggests enclosed pipes without a silent gap at the loop boundary.
    dry = array('f', mix)
    delay = round(.1875 * RATE)
    for index in range(len(mix)):
        mix[index] += dry[(index-delay) % len(mix)] * .16
    return mix


def main() -> None:
    """Render versioned source audio and exact synthesis provenance."""
    SFX.mkdir(parents=True, exist_ok=True)
    cues = []
    for index, (name, duration, start, end, noise) in enumerate(SPECS):
        peak = -15 if 'impact' in name or name == 'armored-hit' else -12
        record = save(SFX / (name + '.wav'), effect(duration, start, end, noise, 43100+index), peak)
        record.update({'cue_id': name, 'gain_db': -5, 'loop': False, 'seed': 43100+index})
        cues.append(record)
    track = save(SOURCE / 'backpressure-boss-original-v1.wav', music(), -6)
    manifest = {'schema_version': 1, 'date': '2026-10-16', 'cues': cues, 'music_source': track,
                'music_title': 'Backpressure', 'bpm': 150, 'bars': BARS, 'meter': '4/4',
                'composition': 'Original Phrygian bass/pipe motif, organ, syncopated drums and pipe echo.',
                'format': {'sample_rate': RATE, 'channels': 1, 'bits': 16},
                'provenance': 'Original deterministic procedural composition and synthesis. No third-party samples.',
                'rights': 'Project-generated material; no third-party sample licensing obligations introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'First-pass original audio; subjective listening and runtime sync pending'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
```

<!-- markdownlint-enable MD013 -->

### audio/sources/sewer-fly-buzz-v1/generate.py

<!-- markdownlint-disable MD013 -->

```python
#!/usr/bin/env python3
"""Generate an original periodic swarm buzz without external samples."""

import hashlib
import json
import math
import struct
import wave
from pathlib import Path

RATE = 44100
DURATION = 2
SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav'


def main() -> None:
    """Render integer-period voices so the whole two-second buffer loops continuously."""
    samples = []
    for index in range(RATE * DURATION):
        t = index / RATE
        value = 0.0
        for frequency, flutter, offset in [(173, 3, 0), (191, 4.5, 1.2), (211, 2.5, 2.4)]:
            phase = math.tau * frequency * t + 0.7 * math.sin(math.tau * flutter * t + offset)
            amplitude = 0.7 + 0.3 * math.sin(math.tau * 1.5 * t + offset)
            value += amplitude * sum(math.sin(phase * harmonic) / harmonic ** 1.5 for harmonic in range(1, 9))
        samples.append(value)
    gain = 10 ** (-18 / 20) / max(map(abs, samples))
    pcm = [round(value * gain * 32767) for value in samples]
    with wave.open(str(OUTPUT), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(pcm), *pcm))
    manifest = {'id': 'sewer-fly-buzz-v1', 'path': str(OUTPUT.relative_to(ROOT)),
                'duration_seconds': DURATION, 'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16,
                'peak_dbfs': -18, 'suggested_gain_db': -8, 'loop': True,
                'provenance': 'Original additive synthesis; no third-party recordings or samples.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
                'status': 'Technical candidate; listening and runtime verification pending',
                'loop_boundary_step_pcm': abs(pcm[-1] - pcm[0])}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert max(map(abs, pcm)) < 4200
    assert abs(pcm[-1] - pcm[0]) < 500


if __name__ == '__main__':
    main()
```

<!-- markdownlint-enable MD013 -->

### audio/sources/sliding-progress-door-v1/generate.py

<!-- markdownlint-disable MD013 -->

```python
#!/usr/bin/env python3
"""Render original short mechanical door cues with deterministic additive synthesis."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
OUTPUT = ROOT / 'assets/audio/sfx/sliding-progress-door-v1'
SPECS = [('latch', 0.12, -15), ('motor-slide', 0.9, -18), ('end-stop', 0.18, -15)]


def synthesize(name: str, duration: float, peak_db: float, seed: int) -> list[float]:
    """Layer muted metal resonances with band-limited motor and friction noise."""
    rng = random.Random(seed)
    result = []
    filtered = 0.0
    for index in range(round(duration * RATE)):
        t = index / RATE
        filtered += 0.12 * (rng.uniform(-1, 1) - filtered)
        if name == 'motor-slide':
            motor = math.sin(math.tau * 95 * t) + 0.25 * math.sin(math.tau * 190 * t)
            gear = 0.12 * math.sin(math.tau * 665 * t) * (0.7 + 0.3 * math.sin(math.tau * 28 * t))
            value = 0.4 * motor + gear + filtered * 0.5
            edge = min(1, t / 0.06, (duration - t) / 0.08)
        else:
            base = 270 if name == 'latch' else 115
            decay = 40 if name == 'latch' else 27
            value = sum(math.sin(math.tau * base * ratio * t) * weight * math.exp(-decay * ratio * t)
                        for ratio, weight in [(1, 0.7), (2.31, 0.3), (4.17, 0.12)])
            value += filtered * math.exp(-65 * t) * 0.7
            edge = min(1, t / 0.003, (duration - t) / 0.03)
        result.append(value * max(0, edge))
    scale = 10 ** (peak_db / 20) / max(map(abs, result))
    return [value * scale for value in result]


def save(path: Path, samples: list[float]) -> None:
    """Save a mono 16-bit PCM file with no leading delay or looping metadata."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(s * 32767) for s in samples)))


def main() -> None:
    """Generate runtime cues, a reference mix and the provenance manifest."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    preview = [0.0] * round(1.08 * RATE)
    cues = []
    for index, (name, duration, peak) in enumerate(SPECS):
        samples = synthesize(name, duration, peak, 16200 + index)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        offset = round((0.9 if name == 'end-stop' else 0) * RATE)
        for position, value in enumerate(samples):
            preview[offset + position] += value * 10 ** (-3 / 20)
        cues.append({'cue_id': 'door-' + name, 'path': str(path.relative_to(ROOT)),
                     'duration_seconds': duration, 'peak_dbfs': peak, 'gain_db': -3, 'loop': False,
                     'rms_dbfs': round(20 * math.log10(math.sqrt(sum(s * s for s in samples) / len(samples))), 2),
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'seed': 16200 + index})
    assert max(map(abs, preview)) < 1
    save(SOURCE / 'door-opening-reference-v1.wav', preview)
    manifest = {'schema_version': 1, 'date': '2026-10-16', 'cues': cues,
                'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
                'brief': 'Brief latch, restrained motor/metal movement over 0.9s downward slide, separate end clunk.',
                'provenance': 'Original deterministic synthesis; no recordings, samples, voice or external assets.',
                'rights': 'Project-generated audio; no third-party sample license obligations introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'status': 'Technical candidate delivery; subjective listening and runtime integration pending'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
```

<!-- markdownlint-enable MD013 -->

### audio/sources/spare-employee-dispenser-v1/generate.py

<!-- markdownlint-disable MD013 -->

```python
#!/usr/bin/env python3
"""Render original dispenser effects and a timing reference using only synthesized signals."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / 'assets/audio/sfx/spare-employee-dispenser-v1'
SOURCE = Path(__file__).resolve().parent
PEAK = 10 ** (-12 / 20)
# Name, duration, frequency sweep, noise blend, modulation, event time.
CUES = [
    ('scan-whirr', 0.38, 260, 540, 0.08, 18, 0.0),
    ('grab-servo', 0.30, 160, 95, 0.15, 32, 0.4),
    ('compression-squeak', 0.72, 310, 820, 0.12, 9, 0.66),
    ('flick-whoosh', 0.32, 560, 95, 0.82, 0, 1.4),
    ('screen-splat', 0.30, 155, 48, 0.65, 23, 1.76),
    ('screen-slide', 0.72, 210, 70, 0.42, 11, 2.1),
    ('vending-motor', 1.25, 105, 160, 0.20, 28, 2.15),
    ('vending-clunk', 0.20, 160, 62, 0.40, 0, 3.4),
    ('release-confirm', 0.30, 660, 990, 0.0, 0, 5.12),
    ('checkpoint-stamp', 0.22, 220, 130, 0.30, 0, 0.0),
]


def render(duration: float, start: float, end: float, noise: float, modulation: float, seed: int) -> list[float]:
    """Synthesize soft-edged tones and low-pass noise, with deterministic variation."""
    rng = random.Random(seed)
    phase = 0.0
    filtered = 0.0
    samples = []
    for index in range(round(duration * RATE)):
        time = index / RATE
        progress = time / duration
        frequency = start * (end / start) ** progress
        phase += math.tau * frequency / RATE
        filtered += 0.18 * (rng.uniform(-1, 1) - filtered)
        tone = math.sin(phase) + 0.22 * math.sin(phase * 2) + 0.08 * math.sin(phase * 3)
        envelope = min(1.0, time / 0.012, (duration - time) / 0.045)
        envelope *= math.sin(math.pi * progress) ** 0.45
        pulse = 0.8 + 0.2 * math.cos(math.tau * modulation * time)
        samples.append(((1 - noise) * tone + noise * filtered * 3) * envelope * pulse)
    scale = PEAK / max(abs(value) for value in samples)
    return [value * scale for value in samples]


def save(path: Path, samples: list[float]) -> None:
    """Write mono 16-bit PCM with no looping or leading delay."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(value * 32767) for value in samples)))


def main() -> None:
    """Generate immutable-version cues, provenance and a non-runtime sequence preview."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    preview = [0.0] * round(5.5 * RATE)
    records = []
    for index, (name, duration, start, end, noise, modulation, event_time) in enumerate(CUES):
        samples = render(duration, start, end, noise, modulation, 1600 + index)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        if name != 'checkpoint-stamp':
            offset = round(event_time * RATE)
            for position, value in enumerate(samples):
                preview[offset + position] += value
        records.append({
            'event': name, 'file': str(path.relative_to(ROOT)), 'duration_seconds': duration,
            'reference_start_seconds': event_time, 'suggested_player_gain_db': -3,
            'peak_dbfs': -12, 'rms_dbfs': round(20 * math.log10(
                math.sqrt(sum(value * value for value in samples) / len(samples))), 2),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'seed': 1600 + index,
        })
    assert max(abs(value) for value in preview) < 1.0
    save(SOURCE / 'sequence-reference-5.5s.wav', preview)
    metadata = {
        'id': 'spare-employee-dispenser-audio-v1', 'date': '2026-10-16',
        'status': 'synthesized_candidates_ready_for_integration_review_not_listening_approved',
        'provenance': 'Original procedural synthesis in adjacent generate.py. No recordings, samples or voice models.',
        'rights': 'Project-generated audio; no third-party sample licenses or attribution requirements introduced.',
        'format': {'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16},
        'generator': 'audio/sources/spare-employee-dispenser-v1/generate.py',
        'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'creative_brief': 'Cartoon machine, rubbery compression, flick, wet splat, slide, vending and release. '
                          'No gore, speech or BJ line. Soft attacks and short tails; retro synthetic palette.',
        'cues': records,
        'integration': {
            'full_sequence_target_seconds': 5.5, 'control_lock_hard_ceiling_seconds': 7,
            'trigger_policy': 'Animation events trigger cues; times are reference only. Never await audio end.',
            'skip_policy': 'Cancel queued cues; fade voices over 30ms on skip, scene exit or restart.',
            'concurrency': 'Separate one-shot voices allow slide and vending to overlap; no individual cue loops.',
            'respawn': [{'event': 'vending-motor', 'at': 0}, {'event': 'vending-clunk', 'at': 1.25},
                        {'event': 'release-confirm', 'at': 1.55}],
            'respawn_control_target_seconds': 2,
            'full_health': 'checkpoint-stamp only; release control within 0.5s; omit destruction cues.',
            'mix': 'Start each cue at -3dB player gain; rendered peaks -12dBFS. Respect SFX mute and music mix. '
                   'No loudness claim until in-game listening. Reference WAV is for audition only.',
        },
        'validation': 'PCM structure, finite samples, peaks, tail endpoints, hashes and reference duration checked. '
                      'Listening, animation sync and runtime integration pending.',
    }
    (SOURCE / 'manifest.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print('Generated 10 original cues and 5.5-second reference; peak:', max(abs(value) for value in preview))


if __name__ == '__main__':
    main()
```

<!-- markdownlint-enable MD013 -->

### audio/sources/spare-employee-dispenser-v2/generate.py

<!-- markdownlint-disable MD013 -->

```python
#!/usr/bin/env python3
"""Synthesize a layered cartoon wet impact and glass-slide without third-party samples."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
OUTPUT = ROOT / 'assets/audio/sfx/spare-employee-dispenser-v2'


def render(slide: bool) -> list[float]:
    """Layer filtered spray, pitched body and wet droplets with short, smooth tails."""
    duration = 0.56 if slide else 0.34
    rng = random.Random(16102 if slide else 16101)
    samples = []
    filtered = 0.0
    phase = 0.0
    for index in range(round(duration * RATE)):
        t = index / RATE
        u = t / duration
        noise = rng.uniform(-1, 1)
        filtered += (0.08 if slide else 0.28) * (noise - filtered)
        if slide:
            phase += math.tau * (190 * (0.3 ** u)) / RATE
            friction = filtered * (0.55 + 0.35 * math.sin(math.tau * (18 * t + 7 * t * t)))
            rubber = 0.18 * math.sin(phase + 1.2 * math.sin(math.tau * 19 * t))
            sample = (friction + rubber) * math.sin(math.pi * u) ** 0.65
        else:
            phase += math.tau * (60 + 190 * math.exp(-t * 35)) / RATE
            body = 0.75 * math.sin(phase) * math.exp(-t * 24)
            slap = filtered * 1.8 * math.exp(-t * 48)
            spray = filtered * 0.5 * math.exp(-t * 11)
            bubbles = 0.0
            for delay, frequency in [(0.025, 460), (0.055, 330), (0.10, 260), (0.16, 190)]:
                age = t - delay
                if age > 0:
                    angle = math.tau * frequency * (1 - math.exp(-age * 12)) / 12
                    bubbles += 0.28 * math.sin(angle) * math.exp(-age * 36) * min(1, age / 0.003)
            sample = body + slap + spray + bubbles
        edge = max(0, min(1, t / 0.003, (duration - t) / 0.035))
        samples.append(sample * edge)
    peak = 10 ** ((-15 if slide else -12) / 20)
    gain = peak / max(map(abs, samples))
    return [sample * gain for sample in samples]


def save(path: Path, samples: list[float]) -> None:
    """Write a mono PCM cue with sample-exact duration."""
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *(round(s * 32767) for s in samples)))


def main() -> None:
    """Render versioned assets and preserve exact synthesis provenance."""
    OUTPUT.mkdir(parents=True, exist_ok=True)
    records = []
    for name, slide in [('screen-splat', False), ('screen-slide', True)]:
        samples = render(slide)
        path = OUTPUT / (name + '.wav')
        save(path, samples)
        records.append({'cue_id': name, 'path': str(path.relative_to(ROOT)),
                        'duration_seconds': len(samples) / RATE, 'gain_db': -3,
                        'peak_dbfs': -15 if slide else -12, 'loop': False,
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'version': 2, 'date': '2026-10-16', 'cues': records,
                'brief': 'Wet cartoon SPLAT, then short slide for X-eyed hero and fading blood trail.',
                'provenance': 'Original synthesis; no recordings, samples, voice models or external assets.',
                'rights': 'Project-generated audio; no third-party sample license requirements introduced.',
                'generator': str(Path(__file__).relative_to(ROOT)),
                'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'seeds': {'screen-splat': 16101, 'screen-slide': 16102},
                'status': 'Candidate audio; technical checks only, not listening approved'}
    (SOURCE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
```

<!-- markdownlint-enable MD013 -->

## Appendix B: Audio file inventory

SHA-256, bytes and repository-relative path; binary content is not embedded.

<!-- markdownlint-disable MD013 -->

```text
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855           0  audio/.gdignore
1e11ce1da779d2517da01211f1423ba074fd4985385e59b514facbf4af73942e         949  audio/catalog.json
eb548f64f69b16328aa5ba08d5420a27633eef932a67da8bcb5399a31b87e1d0     3276844  audio/sources/clogfather-v1/backpressure-boss-original-v1.wav
c382c3721064d711bab0d4938cf4f1f551ccae2edbe69c92e9c9783b38c99151      188036  audio/sources/clogfather-v1/backpressure-preview.mp3
d55bc883bb3a75ed4aa450d2b9403601c5fe4b2505ac5be0a36f86d53b7c64b8        7057  audio/sources/clogfather-v1/generate.py
66028473460e5533b0856e1b015bbfaaa4ded68a7f8e84291a074858cfba7690        5004  audio/sources/clogfather-v1/manifest.json
5a0d034f26729db79fb7de007db62f92e182d3687f2083b2fecbbd31848c7974         543  audio/sources/clogfather-v1/storyboarding-brief.json
7473feb85c78130f0066738ae5b77a6162d6af0d3003f832e750a7b98c074a7f    50152214  audio/sources/face-the-facts-original-v1.wav
35dcb1dc69338bad745e1cd56c676d04e4afb6687b9aa6d05ba83a255252747b       20727  audio/sources/flushfiend-shatter-v1/bfh1_glass_breaking_02.ogg
970cac3139e1530009ca87f8ee0dd800dc4da61917a5e62bdc83d475a9bf4da7       30092  audio/sources/flushfiend-shatter-v1/bfh1_rock_breaking_01.ogg
6886ac1723b07aa3cbf49f4cef4be4ca9a86186226755fbb7e056a1c6d003465        1749  audio/sources/flushfiend-shatter-v1/manifest.json
059f425d60469ca9141f40228dcd06a990eb2f7d2067e87802a8f5a6a3a39082       66228  audio/sources/flushfiend-shatter-v1/mix-v1.wav
e6ee04d91c5f4d30cfda1260d2c9d1faf96fda36319287215fbd07bcb1a80451     1624406  audio/sources/flushfiend-shatter-v1/original-pack.zip
dd6a5c305dd7cf5e20284131ca4a1cbbda5fd38a376f80256aea141a89cf007d    20316008  audio/sources/hallow-quest/original-16-bit-v1.zip
3989500505069c0dcb5df4f67b3d72e11c2e314a2a1e7a900252cbd36c9535f9        1366  audio/sources/hallow-quest/track.json
5ca00592e8ffb337467debc2903f9d349b33a0fd07b36cddc99ffaab05a8aa55    59245926  audio/sources/it-takes-a-hero/original-v1.wav
d4ec14211728e9328888b99285e22e163eb77959dada5bc111dc69af775d70e2        1421  audio/sources/it-takes-a-hero/track.json
029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8      800850  audio/sources/menu-navigation-candidates-v1/kenney-impact-sounds.zip
b49aa9c56b04528b95913de13e506a0f7c5e807b9925db9bfef86af1f91120db         608  audio/sources/menu-navigation-candidates-v1/kenney-impact-sounds.zip-License.txt
6dbeaf8544da958d8f2adcb4a4a4b76c1ade34a05f8ab9edccd327da7375f38b      964837  audio/sources/menu-navigation-candidates-v1/kenney-rpg-audio.zip
5735dfd72cb64cbbceda4ebc00c380c41ca680edb82ff153aa7c9ab97614c539         478  audio/sources/menu-navigation-candidates-v1/kenney-rpg-audio.zip-License.txt
ba9ba60b172b3ebc131a940f25793cd2e207aca7af73dc80d637277f060f1708       10208  audio/sources/menu-navigation-candidates-v1/latch-original.ogg
fbf8099057e422af9596f9eb1e58637f47852e56246aa3c1c076dd78e82a91a7       18932  audio/sources/menu-navigation-candidates-v1/latch-preview.mp3
6bb17e4b850835fcd964ae30b9ae0b4071eecb71d5e8688b1d12aa78b48928e1       19448  audio/sources/menu-navigation-candidates-v1/latch.wav
fff179be32f22d7d7761ba956f4bd7b46b713f6287afe295b3d69e8087a615cb        3150  audio/sources/menu-navigation-candidates-v1/manifest.json
8e1f820d217d380fde10e969d109db34303e3f4d11c3951926eddef813d04ae2       22471  audio/sources/menu-navigation-candidates-v1/pipe-tap-original.ogg
64f3f71b1e62d0d882bd615de40fda5c4a4e3f78d8fb6ef9520f33d1b4a3dbe5       19846  audio/sources/menu-navigation-candidates-v1/pipe-tap-preview.mp3
076abe7a24b9a57c50e34615b7d607eedc7436a267fce4f2d6c9f02ecbd6c469       24740  audio/sources/menu-navigation-candidates-v1/pipe-tap.wav
9851a69d0c613e13bceef08060ecc4148f098ef487927cbebe270d642398a3b3       13615  audio/sources/menu-navigation-candidates-v1/valve-click-original.ogg
2f3ba7750dcb0124f4a3ebc80a9518ce2efa6cc921cbbd593255217221f62a9b       17389  audio/sources/menu-navigation-candidates-v1/valve-click-preview.mp3
cceccbdfc19721291fcf32a1e4c273fc1658b66c5a537785eec5e3d072908754       14156  audio/sources/menu-navigation-candidates-v1/valve-click.wav
33b5e6e37c6e9d54e07bf5a89b12c76e879f40c1ea83cdd82714df1d6f9fec6d        7651  audio/sources/menu-navigation-candidates-v1/wrench-clink-original.ogg
7fb9b4aa9202479da3de9b09aeb23927798ccfec1ce0a878f83266db2802339d       13522  audio/sources/menu-navigation-candidates-v1/wrench-clink-preview.mp3
718bed01a9fa2d0d36541b313f39e6f3f5e757174328756a25918eb9bdbe2dde       21212  audio/sources/menu-navigation-candidates-v1/wrench-clink.wav
1f1e7e054d850123ddb168e67cb597fb54a31eaba7b4b7a0bcf3bb488215dfa6      264678  audio/sources/player-death-flush-v1/edited-v1.wav
9a814b8dfb7c6182292f5b23de3589a9a8f55621a6d8ac10d3ec95b4c59a318f        1684  audio/sources/player-death-flush-v1/manifest.json
a5c135878c132f1c59cca54e60061c296cd0ac27ad031ca2c41b8cd5cab3c706     2921904  audio/sources/player-death-flush-v1/original-pack.zip
502393b0cf4ef7be08eee5955d0c451e42f9b192b181fecd1f28ada0329c2257      291328  audio/sources/player-death-flush-v1/toilet_01.ogg
9e4a1824ac584bb65ba32406155d37861df7e11b95ef62493246dd2da17f8dbc      168727  audio/sources/player-death-flush-v1/toilet_02.ogg
d2134a3820ced3a6e3db21f30f78f943067b11e8de359cec0fc2073b8ad6f8bd        2207  audio/sources/sewer-fly-buzz-v1/generate.py
ade74aa524301d93f278947393fa4faad4794168cdc4c6a865079b2b525f1f01         671  audio/sources/sewer-fly-buzz-v1/manifest.json
be032d8225ed511ed0ba7a7444621417858688b6e8ff3286a4186df15d904d1e       95300  audio/sources/sliding-progress-door-v1/door-opening-reference-v1.wav
e80c66bf9a519b8efb2b8db90c1490ad787e282b9bf8349e771c728c463394d9        4045  audio/sources/sliding-progress-door-v1/generate.py
ca9d545862280d8aabb069a7fa060939afa54187e2933364774a09ee70fa28c1        1745  audio/sources/sliding-progress-door-v1/manifest.json
4c0da915be8b23c30f5abe13d8c6caa1e355b31ae5825d9945c7645a5799bef9        5961  audio/sources/spare-employee-dispenser-v1/generate.py
9e79707f9b59be97deedda0aff2c8f3bc4c46724050a0ac34d0aaa3a531abddf        5842  audio/sources/spare-employee-dispenser-v1/manifest.json
52b0433a1805c771fdb86cab3530cfa2bbed4882e6de72c86872d8ac920bdfbe      485144  audio/sources/spare-employee-dispenser-v1/sequence-reference-5.5s.wav
813b02e93870f6dedda6e853713fd65b76d868ed1b376bd3e483dba79ea0b4a5        3897  audio/sources/spare-employee-dispenser-v2/generate.py
1544f324c0789021358a086492029ad0120c2153493d2aee2aafd1020a20b209        6235  audio/sources/spare-employee-dispenser-v2/handoff-before-impact-revision.json
84de552d605095ec64685ea499b1ee2c2a7827c287ac3a88a1a1c2a36f565516        1261  audio/sources/spare-employee-dispenser-v2/manifest.json
16f9e88285bdfc362c3c8dd89bc9f1fea30bdad058b3bb181b0244a52fa6a074      485144  audio/sources/spare-employee-dispenser-v2/sequence-reference-v2-5.5s.wav
67bdf6e947016267b0b43eb6f8c31c5b53d203efb31580aa85cc2c3508975e0c       14010  audio/sources/title-screen-sting-v1.gd.txt
7ca63dc738c9d7b1206fad0f9179fedc553f2873f271fa9fc79a2d53753fa959        1234  audio/title-music.json
b0f8675acc630169cc7d3f238952852dd3b28b29d5e7e7da974a9c76f6c74706      410813  assets/audio/music/clogfather-backpressure-v1.ogg
42b885f514a06346c3fedb92f0512c5aff47b9bffb915fc0df32537140859905     2719116  assets/audio/music/face-the-facts-title-v1.ogg
5c24a0ae87be7b6976d444e4864aec46e7db880c72647bd935da353cd1b51073      965268  assets/audio/music/hallow-quest-16-bit-v1.ogg
22647bca595e71e9d8820dce135bb3e216e80cb3a2a9ff5ca7fe537bb487c804     3374120  assets/audio/music/it-takes-a-hero-v1.ogg
df2d18d4dbdcbd63468eee2e649265462a89812dc970a1b9001ea32491882052       54444  assets/audio/sfx/clogfather-v1/acid-warning.wav
cfef2a9cba4663b4ccde9dd55bbaf308afe77695369dff19b9526895eae4d32e       10284  assets/audio/sfx/clogfather-v1/armored-hit.wav
f8d172e96942969b725b44d6c1f318a6672484f268be30f17fb0e2c04d81e281      115244  assets/audio/sfx/clogfather-v1/collapse.wav
d1a5eb813ffab0390329290dc5680cf3a8d7318965e95d4e71826e94b2fa0050       73644  assets/audio/sfx/clogfather-v1/groan-a.wav
cec8262b573450506347175e0904cb115e2cb509a9e1fd2ae771699741546e75       60844  assets/audio/sfx/clogfather-v1/groan-b.wav
4ba97b36d114997e1fa5fb907ba172b249d3bc7ca4e352c4de3fd7cdf5827a1f       26924  assets/audio/sfx/clogfather-v1/hurt.wav
786fb496781c29600f0c910d1d6734ec15b5ad12bc83896a0a550db7d7ec27e2       46124  assets/audio/sfx/clogfather-v1/pressure-warning.wav
b09481c8aa3cd0e6d5c9702a3ebd023a356d10aee7a421511c27088f6a4852c3       15404  assets/audio/sfx/clogfather-v1/sludge-fire-a.wav
b1da44aea8578eb4f8d57610b40149571bd7c3a285883b8ca03a26e0155216d8       17324  assets/audio/sfx/clogfather-v1/sludge-fire-b.wav
2c3d1b17da3182ad0f56b121b4e585156450ee8f876e003db786d97c198d8dda       21804  assets/audio/sfx/clogfather-v1/sludge-impact-a.wav
fade3601f358b1b218bbe119e31d67059771310ade2eea0e946c8b1d392dd5a2       24364  assets/audio/sfx/clogfather-v1/sludge-impact-b.wav
6736592d0946a697509c6170d704deb3c113dc1ffcfeeedae64703917e9b3c28       30764  assets/audio/sfx/clogfather-v1/weak-point-open.wav
fb36d36e31ab4310847447de55ebe2f58b1a40ce0cf5ca5b870184b33e0afb40       66194  assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav
718bed01a9fa2d0d36541b313f39e6f3f5e757174328756a25918eb9bdbe2dde       21212  assets/audio/sfx/menu-navigation-v1/wrench-clink.wav
992e24efb11ef8c82091352efd4a0c38813dc733f115b737a81f4d4152dd55ba      264644  assets/audio/sfx/player-death-flush-v1/toilet-flush.wav
b627a972eb7eb9d2327f3f7af999ddb0c5bf8379c8919fce780c516960ebddf4      176444  assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav
149060505adb49fe972c28450c5bbc795983c1fd6b8dc435cd8d36fb81ab67e3       15920  assets/audio/sfx/sliding-progress-door-v1/end-stop.wav
9238f2f3f859d756ffe3107eee3fe89731aee00231afb8bc3f010bd7554788fa       10628  assets/audio/sfx/sliding-progress-door-v1/latch.wav
e4122bee7d54b5b6436560ab97627fb78ea5b50759cc380032ed5c575a1254f1       79424  assets/audio/sfx/sliding-progress-door-v1/motor-slide.wav
a228170baf11149e846393c2f1e729a4287578a9b5e9f3c2e32d520c5f3d6208       19448  assets/audio/sfx/spare-employee-dispenser-v1/checkpoint-stamp.wav
154f19aacb71b5765d3b756bc975e224b9bd3cff1fe4ba1ca3f86e3fb3820022       63548  assets/audio/sfx/spare-employee-dispenser-v1/compression-squeak.wav
a3b38f3513e638841fc442900f222b28e915c0cf01ba960dacd0c1075c83a4ad       28268  assets/audio/sfx/spare-employee-dispenser-v1/flick-whoosh.wav
f1c8d564fa0f5923eaf5b6f399eca959ff49c673658b41ac4d53ca8d314df9de       26504  assets/audio/sfx/spare-employee-dispenser-v1/grab-servo.wav
6ec03655e95ad3501109a9c39f2870245f7b8db92eb456bb0e9a29ca08c36622       26504  assets/audio/sfx/spare-employee-dispenser-v1/release-confirm.wav
bc8989be0666fcf23e8aeb9d0da652ee79e473eb03f281c731bff442847602d7       33560  assets/audio/sfx/spare-employee-dispenser-v1/scan-whirr.wav
ffe22ca75ea68e153915af64f52a90fb561a4e8b46e8ad8a7e7e0e2f05072002       63548  assets/audio/sfx/spare-employee-dispenser-v1/screen-slide.wav
21ad54b726893ac4da2c04f98c36ac7f464f1e07c32546f85a50357e347a8ec0       26504  assets/audio/sfx/spare-employee-dispenser-v1/screen-splat.wav
9158457bec9285f90f2fdb3b0dfd02bc260e2a330e2254e8eb73fbf931f34587       17684  assets/audio/sfx/spare-employee-dispenser-v1/vending-clunk.wav
d25367f9d9c0455d40dd944eb201ad1211733f1201deada009211d0c133d9d31      110294  assets/audio/sfx/spare-employee-dispenser-v1/vending-motor.wav
013fa14b540be42a6485f201c3881bdc93ef1351641bc123bcc9020edfad9115       49436  assets/audio/sfx/spare-employee-dispenser-v2/screen-slide.wav
861661f412a004163d988e4b50e1d4918248c5794d50129fa853c0ec7a2dd74c       30032  assets/audio/sfx/spare-employee-dispenser-v2/screen-splat.wav
```

<!-- markdownlint-enable MD013 -->

## Appendix C: Recovered user and assistant conversation

All 29 turns exposed by pagination are represented below in chronological order. Tool outputs and private reasoning
are excluded. This preserves available conversational evidence; it does not reconstruct unavailable or truncated logs.

<!-- markdownlint-disable MD013 -->

### Turn 01a138c7-04c7-7972-8b11-596b754b25a9

Recorded start: 1791953929.

User message `01a138c7-05bf-7153-acf8-5e07c829ab34`:

```text
You will be the sound agent for the game. Your job will be to create music for the loading screen, each level, bosses, etc and possibly speech audio for the players and bosses and the in-game AI overlord if we can make it sound good
```

Assistant message `msg_0c6b0978390c03de016acf0c0d4db481999c7425ba475e19c0`:

```text
I’ll handle the game’s audio: loading-screen music, level themes, boss tracks, transitions, and potential voices for Tony, Sean, bosses, and the AI overlord.

I’ll aim for a cohesive sound with seamless music loops and clear dialogue during gameplay. For voices, we can start with a few short samples and judge the quality before committing to full dialogue.

I’ll follow the project’s roadmap and storybook conventions and ask before opening the game for you to listen or playtest.
```

### Turn 01a13bf1-36d5-7890-a6aa-4445eff42ba7

Recorded start: 1792007026.

User message `01a13bf1-37bf-7290-9032-2e5e71d5bcf9`:

```text
There must be some open-source MIT catalog of sound effects and/or music and such that we could use for our game..... right? Yes? No?
```

Assistant message `msg_0c6b0978390c03de016acfdb7403ec8199a0ed87229ace0758`:

```text
I’ll check reusable game-audio libraries and their licenses—many use Creative Commons rather than MIT.
```

Assistant message `msg_0c6b0978390c03de016acfdb7eac3c81998a6ec8cbb54449de`:

```text
**Yes—absolutely.** We can build much of the game’s audio from existing free libraries.

The license to look for is usually **CC0**, rather than MIT. CC0 allows copying, editing, and commercial use without requiring attribution. [CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/)

| Source | Useful for our game | License |
|---|---|---|
| [Kenney](https://kenney.nl/assets/interface-sounds) | Menu clicks, interface feedback, game effects | Kenney’s asset packs are **CC0**. |
| [OpenGameArt](https://opengameart.org/content/audio-cc0-8bit-chiptune) | Retro music, looping level themes, boss music, effects | Includes **CC0** collections; check each asset. |
| [Freesound](https://freesound.org/help/faq/) | Water, pipes, machinery, footsteps, eerie ambience | Mixed licenses; filter for **CC0**. |

**My recommendation:** start with Kenney for interface sounds, CC0 OpenGameArt music for loading screens and levels, and CC0 Freesound recordings for the plumbing atmosphere. We can edit and layer those recordings to give the game its own character.

I’d keep the source, creator, and license alongside every imported asset. Custom character speech would be a separate effort, but **we don’t need to create every sound or music track from scratch.**
```

### Turn 01a13c0d-2b95-7e23-83b6-a96045988ac6

Recorded start: 1792008858.

User message `01a13c0d-2bab-7f03-8de2-8b09e0e70dfe`:

```text
Excellent. Let's get some SNES-era music going for the opening screen. Consult with the Storyboarding agent for themes.
```

Assistant message `msg_0c6b0978390c03de016acfe29d98608199936cb6104c4a75c3`:

```text
I’ll inspect the opening screen and existing audio setup, then consult the Storyboarding agent about themes before choosing the music.
```

Assistant message `msg_0c6b0978390c03de016acfe2b98e7881998db3ef49d990ae3c`:

```text
The opening currently plays a three-second synthesized sting. I found a CC0 track with an explicit 16-bit arrangement and a looping structure; I’m checking its fit against Storyboarding’s direction before wiring it into the menu.
```

Assistant message `msg_0c6b0978390c03de016acfe2cbc6cc8199a340ba94c6880aca`:

```text
Storyboarding recommends cheerful confidence with a hint of trouble underneath: energetic rhythm, a catchy melody, and playful instrumentation. That points away from the horror-oriented candidate. I’m using “Face the Facts” by Zane Little as the first retro title cue; bespoke character motifs can come later.
```

Assistant message `msg_0c6b0978390c03de016acfe3040188819995ca8bfe9fce7247`:

```text
The music is now connected to the title screen, controls, and character selection. It stops when gameplay begins and respects mute. I’ve preserved the source and license details. This first pass repeats the full track with its ending; it isn’t yet a seamless musical loop.
```

Assistant message `msg_0c6b0978390c03de016acfe323182c81998648eaa3502483aa`:

```text
Added the first retro opening track in Prototype 15: [“Face the Facts” by Zane Little](https://opengameart.org/content/face-the-facts), licensed CC0.

Storyboarding recommended upbeat confidence with trouble underneath. Music now repeats through menus and selection, respects mute, and stops for gameplay. Headless tests and Mac build/signature checks passed; listening approval and screenshots remain pending.

Here’s a 30-second preview:

![Opening music preview](/Users/sfoley/repos/plumbing_inc/.tools/audio-work/title-preview.mp3)
```

### Turn 01a13c12-2ec2-7c22-9730-3b872af587c8

Recorded start: 1792009187.

User message `01a13c12-2ed5-70a2-9c2f-72f5c0e55804`:

```text
Can you give me 2-3 more to choose from?
```

Assistant message `msg_0c6b0978390c03de016acfe3e4c6608199b25a50e4e8c67db0`:

```text
I’ll find three more freely usable retro tracks with different moods so you can compare them with the current opening music.
```

Assistant message `msg_0c6b0978390c03de016acfe41761c08199a44444eb30218faf`:

```text
Here are **three alternatives**, each with a 35-second preview. All are by Zane Little and listed as CC0.

**1. [Rhythm Factory](https://opengameart.org/content/rhythm-factory)** — Funky, playful, and weird. The direction I’d try for the game’s plumbing comedy.

![Rhythm Factory preview](/Users/sfoley/repos/plumbing_inc/.tools/audio-work/options/rhythm-factory-preview.mp3)

**2. [It Takes a Hero](https://opengameart.org/content/it-takes-a-hero)** — Upbeat heroic chiptune. A more straightforward “Tony and Sean to the rescue” direction; leans 8-bit.

![It Takes a Hero preview](/Users/sfoley/repos/plumbing_inc/.tools/audio-work/options/it-takes-a-hero-preview.mp3)

**3. [Hallow Quest — 16-bit version](https://opengameart.org/content/spooky-action-loop-hallow-quest)** — Spooky action, explicitly SNES-inspired. A darker alternative that could also suit the basement.

![Hallow Quest preview](/Users/sfoley/repos/plumbing_inc/.tools/audio-work/options/hallow-quest-preview.mp3)

Which grabs you: **1, 2, 3, or the current track?**
```

### Turn 01a13c15-b2f5-7322-ae31-031978807a6c

Recorded start: 1792009417.

User message `01a13c15-b309-7752-a208-0bae233b61a7`:

```text
Let's go with "It Takes a Hero" for the opening screen and "Hallow Quest" for the first level. Obtain and organize the audio files locally or however that is going to work and then have the Engineering agent integrate them into the game.
```

Assistant message `msg_0c6b0978390c03de016acfe4cdbff0819980065e8e3fd2845f`:

```text
I’ll organize both tracks with their source files and license records, then hand the integration to Engineering with the opening-screen and first-level assignments.
```

Assistant message `msg_0c6b0978390c03de016acfe5000a6c8199986e3c6de0bb3f62`:

```text
Both full tracks are saved locally and decode successfully. Engineering has the files and integration instructions. “Hallow Quest” includes an authored loop; “It Takes a Hero” is a complete song, so its repeat needs an intentional transition.
```

Assistant message `msg_0c6b0978390c03de016acfe50581c08199a45765545d53fea4`:

```text
Both full tracks are organized locally with original files, game-ready OGGs, and CC0 license records:

- **Opening:** “It Takes a Hero”
- **First level:** “Hallow Quest” — 16-bit version

Engineering has received the handoff and is working on integration, transitions, mute behavior, and testing. Integration is still in progress.
```

### Turn 01a13da0-cf81-72e3-ba45-86fe58102a24

Recorded start: 1792035311.

Assistant message `msg_0c6b0978390c03de016ad049f950008199b9317b33070e8611`:

```text
I’ll confirm the approved first-level audio and its current handoff status for Engineering.
```

Assistant message `msg_0c6b0978390c03de016ad04a054a40819999c6af42028ff124`:

```text
Confirmed to Engineering: **Hallow Quest (16-bit)** remains approved for level one and is recorded as integrated and headless-verified. No audio asset blockers; subjective listening is still pending. No files changed or game launched.
```

### Turn 01a1401f-e733-7d82-900e-61fb864c8928

Recorded start: 1792077195.

User message `01a1401f-e83a-7790-9c46-7f116bda62cd`:

```text
Is Hallow Quest the same music for the start screen and level 1 or are there different tracks?
```

Assistant message `msg_0c6b0978390c03de016ad0ed8e83948199b2bfef138e3d054a`:

```text
They’re different tracks:

- **Start screen:** “It Takes a Hero”
- **Level 1:** “Hallow Quest” — 16-bit version

That’s the approved setup Engineering recorded as integrated.
```

### Turn 01a14043-aed4-7962-9fce-35fbc565581a

Recorded start: 1792079539.

Assistant message `msg_0c6b0978390c03de016ad0f6b63d7c8199897b78d2fbb435d4`:

```text
I’ll check the audio handoff records for any approved changes Engineering needs in the fresh build.
```

Assistant message `msg_0c6b0978390c03de016ad0f6c6d68c8199911114a7fd8a40af`:

```text
Reported to Engineering: no new audio changes or blockers. Keep **“It Takes a Hero”** for the opening and **“Hallow Quest”** for level one. Both are ready locally; listening and mix approval remain pending. Other music and voices are still discussion-only.
```

### Turn 01a145be-af1d-7ec2-a5fe-e1c3361c9967

Recorded start: 1792171487.

Assistant message `msg_0c6b0978390c03de016ad25de6708481999f73af3ce6469287`:

```text
I’ll prepare short, event-triggered sound effects for the dispenser sequence, with overlapping cues that fit the 5.5-second target. I’ll keep runtime changes with Engineering and preserve the audio sources and provenance.
```

Assistant message `msg_0c6b0978390c03de016ad25e22c9a8819987e7b3cb1045f3f4`:

```text
The ten cues and a 5.5-second timing reference are rendered. They’re original synthesized effects, with no third-party recordings or speech. Audio checks passed for duration, peak levels, and click-free endpoints; listening and animation-sync review are still pending.
```

Assistant message `msg_0c6b0978390c03de016ad25e3d6ea8819996f6fc984b0a0fdf`:

```text
Created **10 dispenser sound-effect candidates** plus a **5.5-second sequence preview**.

[Engineering handoff](/Users/sfoley/repos/plumbing_inc/handoffs/spare-employee-dispenser-audio.json) includes event mapping, levels, skip behavior, and reproducible synthesis sources. Audio-format and peak checks passed. Listening review and runtime integration remain pending; no game launched.

![Dispenser timing preview](/Users/sfoley/repos/plumbing_inc/audio/sources/spare-employee-dispenser-v1/sequence-reference-5.5s.wav)
```

### Turn 01a145c0-405f-7682-b2de-468653296777

Recorded start: 1792171589.

Assistant message `msg_0c6b0978390c03de016ad25e477d4c819992e9e442548b00f9`:

```text
I’ll check the sound-effect handoff against Engineering’s event contract and align the cue IDs and timing.
```

Assistant message `msg_0c6b0978390c03de016ad25e7d241c8199b93e7ee0b00e84ba`:

```text
[Audio handoff updated](/Users/sfoley/repos/plumbing_inc/handoffs/spare-employee-dispenser-audio.json) to match all ten Engineering event IDs, with verified cue paths, gains, durations, and provenance.

Includes short respawn/stamp timing and cancellation on skip/restart. Audio never delays control; no BJ voice. Ready for integration, with listening and animation-sync validation pending. Runtime and build 39 remain unchanged.
```

### Turn 01a145d7-b985-7fc1-b5e0-4aabdec47a6f

Recorded start: 1792173128.

Assistant message `msg_0c6b0978390c03de016ad2644b96dc81999648a66b86630f1f`:

```text
I’ll revise the impact into a more distinct wet cartoon splat and shorten the slide cue, preserving the originals and the existing sequence timing.
```

Assistant message `msg_0c6b0978390c03de016ad264904c4c8199af8e58f1962227c2`:

```text
Updated the [audio handoff](/Users/sfoley/repos/plumbing_inc/handoffs/spare-employee-dispenser-audio.json) with:

- **SPLAT v2:** layered wet impact, 0.34 seconds.
- **Slide v2:** quieter downward slide, 0.56 seconds.

Originals preserved. Timing, file integrity, and clipping checks passed. Listening approval and Engineering integration remain pending.

![Revised dispenser audio preview](/Users/sfoley/repos/plumbing_inc/audio/sources/spare-employee-dispenser-v2/sequence-reference-v2-5.5s.wav)
```

### Turn 01a145df-1e6f-7bc1-9505-fe5086516245

Recorded start: 1792173612.

Assistant message `msg_0c6b0978390c03de016ad26630df3881998a8e568d213b3b96`:

```text
No required audio issue. Triggering SPLAT at 1.9s lets its 0.34s tail overlap slide/vending safely.

The respawn release cue ends at 2.2s, but control returns at 1.9s—acceptable because audio never gates control. Art v4 timing supersedes the illustrative audio schedule.
```

### Turn 01a145ec-8689-7562-9362-eec989fe4cb7

Recorded start: 1792174491.

Assistant message `msg_0c6b0978390c03de016ad2699ee0508199a6c6bc369a2767d5`:

```text
I’ll make a short latch, a motor-and-metal slide, and a separate end-stop clunk so Engineering can sync the sound to the door’s actual movement. I’ll deliver the files without playing audio or opening the game.
```

Assistant message `msg_0c6b0978390c03de016ad269d6622c81998b89f87c211d5ce3`:

```text
Delivered the [door-audio handoff](/Users/sfoley/repos/plumbing_inc/handoffs/sliding-progress-door-audio.json):

- **Latch:** 0.12s
- **Motor/metal slide:** 0.9s
- **End-stop clunk:** 0.18s, triggered when the door finishes opening

Versioned originals, synthesis source, gains, and provenance are included. Technical checks passed; listening and Engineering integration remain pending. No game or audio playback was started.
```

### Turn 01a145f1-d5c2-7cc3-b00a-c2340bf49bfc

Recorded start: 1792174839.

User message `01a145f1-d5df-7ba3-8140-214457869bd0`:

```text
Do we have any buzzing for the flies? We should.

Also, when the user pressed UP/DOWN/LEFT/RIGHT on the pre-game screens, I want to have some kind of plumbing-themed sound effect. Please find a handful and let me hear them and choose one
```

Assistant message `msg_0c6b0978390c03de016ad26af8f914819985804d934143c40f`:

```text
I’ll check whether the flies already have buzzing, then put together a few plumbing-themed menu sounds for you to audition.
```

Assistant message `msg_0c6b0978390c03de016ad26b1cfb4c8199ae24111d19d77dfe`:

```text
The flies currently have no buzzing audio. I’ll prepare a quiet looping buzz for Engineering to add near living swarms.

For the menus, I found CC0 metal clicks, latches, and hollow impacts from Kenney. I’ll turn four into short plumbing-themed candidates—pipe tap, valve click, wrench clink, and latch—and let you choose before any menu sound is integrated.
```

Assistant message `msg_0c6b0978390c03de016ad26b633cd081998ad23b5752acf748`:

```text
**The flies don’t currently buzz.** I’ve prepared a quiet swarm loop and sent it to Engineering for proximity-based playback.

Here are **four menu candidates**, each repeated four times so you can judge how it feels during navigation. They’re adapted from Kenney’s CC0 [RPG Audio](https://kenney.nl/assets/rpg-audio) and [Impact Sounds](https://kenney.nl/assets/impact-sounds).

**1. Pipe tap**
![Pipe tap](/Users/sfoley/repos/plumbing_inc/audio/sources/menu-navigation-candidates-v1/pipe-tap-preview.mp3)

**2. Valve click**
![Valve click](/Users/sfoley/repos/plumbing_inc/audio/sources/menu-navigation-candidates-v1/valve-click-preview.mp3)

**3. Wrench clink**
![Wrench clink](/Users/sfoley/repos/plumbing_inc/audio/sources/menu-navigation-candidates-v1/wrench-clink-preview.mp3)

**4. Latch**
![Latch](/Users/sfoley/repos/plumbing_inc/audio/sources/menu-navigation-candidates-v1/latch-preview.mp3)

Which do you prefer for **UP/DOWN/LEFT/RIGHT**?
```

### Turn 01a145f5-70d8-7781-88f4-0b76c5b91e80

Recorded start: 1792175075.

Assistant message `msg_0c6b0978390c03de016ad26be507ec8199aa4f3d1770a1b465`:

```text
**Prototype 43 now includes fly buzzing.** It fades with distance, stops when swarms die, and respects pause and mute. Engineering reports packaged tests passed; listening/mix review is still pending.

Menu sounds remain unassigned until you choose a candidate.
```

### Turn 01a146af-a53c-7a73-a3b4-98022b2ed861

Recorded start: 1792187278.

User message `01a146af-a641-73c1-bdeb-a3115645afca`:

```text
The Clogfather is going to need some kind of audio. Firing his projectiles, splatting noises maybe when they hit. Possibly some kind of groaning or something. Please talk to the Storyboarding Agent and come up with some ideas for Clogfather sounds.

We'll need some unique new music for that boss fight too. Something that suggests the sewer and disgusting grossness if possible. Have Engineering integrate it when you're done. I'll give feedback later if I don't like the choices.
```

Assistant message `msg_0c6b0978390c03de016ad29b92aae481999bf51b6fcd90ab9e`:

```text
I’ll consult Storyboarding about The Clogfather’s personality and attack cues, then choose boss music and prepare a coordinated sound set for Engineering. I’ll make the first-pass choices so you can give feedback once they’re in the game.
```

Assistant message `msg_0c6b0978390c03de016ad29bb5f81881998463073d55920b3f`:

```text
The current build has a boss HUD, but no playable Clogfather encounter yet. I’ve asked Engineering to confirm that boundary so we can add the audio support without claiming the fight is implemented.

I’m leaning toward clogged-pipe pressure, wet projectile pops, heavy splats, and strained drain-like groans. For the music, I’ll compose a separate retro boss loop with a lurching bass line and hollow pipe percussion.
```

Assistant message `msg_0c6b0978390c03de016ad29bf6b3c88199a1df997807cdb549`:

```text
Storyboarding’s direction is “an immense blockage reluctantly forced into motion”: obstructed coughs for firing, wet slaps for impacts, and groans that sound like trapped air in pipework rather than speech.

I’ve adjusted the original boss track, **“Backpressure,”** to 150 BPM to keep the fight energetic. Engineering confirmed the encounter is still pending, so the delivery will include event mappings and integration instructions; actual fight playback must wait for that implementation.
```

Assistant message `msg_0c6b0978390c03de016ad29c3e76988199b50697a3c958fd3d`:

```text
Consulted Storyboarding and delivered:

- **12 effects:** pressure warnings, sludge firing, wet splats, pipe-like groans, hurt feedback, and collapse.
- **“Backpressure”:** an original 51-second retro boss loop at 150 BPM, with lurching bass, organ, and hollow pipe percussion.

Engineering has the [complete handoff](/Users/sfoley/repos/plumbing_inc/handoffs/clogfather-audio.json). Technical audio checks passed; listening review remains pending.

**The playable Clogfather encounter doesn’t exist yet**, so actual attack synchronization awaits that implementation. Engineering has been asked to integrate the audio support now.

![Backpressure music preview](/Users/sfoley/repos/plumbing_inc/audio/sources/clogfather-v1/backpressure-preview.mp3)
```

### Turn 01a146e3-0300-75d1-8e06-898ef1819cba

Recorded start: 1792190645.

User message `01a146e3-0325-7b53-bc71-40ca86d9da05`:

```text
FYI: When I move the opening screen cursor around, there is no sound. Did you find sound effects for that yet? Are you waiting on any feedback or input from me? If not, please get the sound effect ready and hand off to engineering
```

Assistant message `msg_0c6b0978390c03de016ad2a8b812a881998b6edb82bc1fefb3`:

```text
Yes—I found four candidates, but **I’m waiting for your choice**, so Engineering hasn’t added one yet:

1. Pipe tap
2. Valve click
3. Wrench clink
4. Latch

I suggest **valve click** for frequent menu navigation. Here it is again:

![Valve click preview](/Users/sfoley/repos/plumbing_inc/audio/sources/menu-navigation-candidates-v1/valve-click-preview.mp3)

Shall I use that one?
```

### Turn 01a14702-9c99-73e0-8499-9c3d46573907

Recorded start: 1792192715.

User message `01a14702-9cd4-7681-ab80-ab741d402745`:

```text
I ike the wrench clink the best
```

Assistant message `msg_0c6b0978390c03de016ad2b0cf24a08199aa425240a6d3b2f1`:

```text
I’ll mark wrench clink as your choice and hand the selected file to Engineering for pre-game navigation.
```

Assistant message `msg_0c6b0978390c03de016ad2b0e4a2108199ba0aa2c3e12991a9`:

```text
**Wrench clink selected.** I’ve prepared the exact sound you auditioned and handed it to Engineering for directional navigation across the pre-game screens. Integration is pending; no further input needed from you.
```

### Turn 01a14729-fd2f-7b90-86e1-f38c423b16d9

Recorded start: 1792195296.

User message `01a14729-fd4b-76b3-bd91-8c24f7ebd67f`:

```text
When a Flushfiend died, it makes a low-pitched bonk/thud sound. Could we get something closer to porcelain breaking/shattering?
```

Assistant message `msg_0c6b0978390c03de016ad2bae3bcc88199ac6212a12eb47bfd`:

```text
I’ll check the current death sound and find a sharper ceramic-breaking replacement for the Flushfiend.
```

Assistant message `msg_0c6b0978390c03de016ad2bb19fd888199b8d33d2761e36af2`:

```text
Yes—I prepared a **ceramic-style crack and shatter** with a short debris tail and handed it to Engineering to replace the Flushfiend’s death bonk. Integration is pending.

![Flushfiend shatter preview](/Users/sfoley/repos/plumbing_inc/assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav)
```

### Turn 01a1472c-8075-7fc2-8c05-21373dcc7c6f

Recorded start: 1792195461.

User message `01a1472c-8091-7911-8737-6f2fd2886ee8`:

```text
That's good enough for now, thanks
```

Assistant message `msg_0c6b0978390c03de016ad2bb86e79c819999ab8a0a9652aa22`:

```text
You’re welcome—we’ll keep that shatter sound for now.
```

### Turn 01a1472c-b96f-7151-8c37-ea3d7a2b2b3f

Recorded start: 1792195475.

User message `01a1472c-b988-7433-9be8-2de167e944eb`:

```text
Handoff to engineering if you haven't already
```

Assistant message `msg_0c6b0978390c03de016ad2bb964bec8199ab0bccd09b31d07b`:

```text
Already handed off to Engineering, with the sound file and instructions to replace the Flushfiend’s death bonk.
```

### Turn 01a1472d-a850-7ea1-bebb-d660df256c40

Recorded start: 1792195536.

Assistant message `msg_0c6b0978390c03de016ad2bbd2cf0c8199bb8e878f00791f92`:

```text
Engineering has integrated the shatter sound, and source tests pass. It’s being combined with other changes for **build 47**, which isn’t ready yet. In-game listening remains pending.
```

### Turn 01a14826-60f6-7ea1-b5c7-9543b7f6699a

Recorded start: 1792211837.

Assistant message `msg_0c6b0978390c03de016ad2fb81e9f8819999df44060104b0b0`:

```text
I’ll prepare a roughly three-second toilet flush for player death and hand it to Engineering as a once-per-death cue. I won’t open the game or play audio during your playtest.
```

Assistant message `msg_0c6b0978390c03de016ad2fbb0991081999c6ee76b8f9d3d37`:

```text
Delivered a **three-second toilet flush** to Engineering for build 52. It’s assigned to player death only, once per death, with source and CC0 provenance preserved.

Technical checks passed; integration and listening review remain pending. No game or audio playback was started.
```

### Turn 01a1482b-39c6-7860-9bb4-60465fcdaad5

Recorded start: 1792212154.

Assistant message `msg_0c6b0978390c03de016ad2fcbcd6648199ae6c2e973e8ac390`:

```text
**Prototype 52 is ready**, with the three-second flush integrated for player deaths. Engineering reports packaged tests passed; listening review is still pending. No game window was opened.
```

### Turn 01a14b89-d98f-7c73-8fc0-a2c402a946eb

Recorded start: 1792268687.

Assistant message `msg_0c6b0978390c03de016ad3d995e0dc8199ab9a2bc342267c34`:

```text
Noted—the canonical repository is now `/Users/sfoley/repos/drain_damage`. I’ll use it for future audio work and won’t recreate the old directory. If access is blocked, I’ll flag the project-folder settings that need updating.
```

### Turn 01a14b9a-cb30-7950-b657-c4f84f3877e4

Recorded start: 1792269798.

Assistant message `msg_0c6b0978390c03de016ad3ddf1d6888199b15b01786fbc0d6c`:

```text
I’ll test creating, reading, and deleting one temporary file in the renamed project folder using normal permissions.
```

Assistant message `msg_0c6b0978390c03de016ad3ddfad9908199a28c31477f9d0d51`:

```text
**Write-access test failed under normal permissions.**

- Exact error: `PermissionError: [Errno 1] Operation not permitted: '/Users/sfoley/repos/drain_damage/.audio-access-check-_wb8ei1q.tmp'`
- Test working directory: `/Users/sfoley/repos/drain_damage`
- Chat’s configured working directory remains `/Users/sfoley/repos/plumbing_inc`.
- Configured writable roots: old project path, `/Users/sfoley/.codex/visualizations/2026/10/14/01a138c6-3821-7f63-a3f4-8fcb11771092`, `/private/tmp`, and `/private/var/folders/y3/fnkknsvj5ygc9v3mhvfbkwh00000gn/T`.
- Cleanup: no temporary file was created.

No escalation, workaround, or project changes attempted.
```

### Turn 01a14b9e-5a76-72b3-9062-8a697ae61f8d

Recorded start: 1792270031.

Assistant message `msg_0c6b0978390c03de016ad3ded4a698819980e27fda112080b2`:

```text
I’ll send Audio 2 the recoverable decisions, asset records, integration status, and outstanding checks. I won’t change files or archive this chat.
```

Assistant message `msg_0c6b0978390c03de016ad3df46cca4819982e7f380c6660bff`:

```text
The handoff wasn’t sent. Sean, may I send Audio 2 the full project history and clarifications?

Automatic approval review rejected the cross-chat message because authorization appeared only in a delegated message, not directly from you. No files were changed or archived.
```

### Turn 01a14ba3-5074-7932-867d-f746e17650af

Recorded start: 1792270356.

Assistant message `msg_0c6b0978390c03de016ad3e018140c819988f660de9570d7fe`:

```text
Sean, please confirm that I may create the full Audio archive at `/private/tmp/drain-damage-original-agent-archives/audio.md` for the replacement agents.

Automatic approval review already blocked this history transfer because authorization came through delegated messages. Creating a file for the same transfer would bypass that rejection without your direct confirmation. No archive has been written.
```

### Turn 01a14ba4-a202-7b33-aec6-f72df4191d3d

Recorded start: 1792270443.

User message `01a14ba4-a23a-7881-bc46-04b40c13e7e6`:

```text
Yeah do it
```

Assistant message `msg_0c6b0978390c03de016ad3e06ddc54819985f5dca43b4a100a`:

```text
I’ll create the full Audio archive in the approved temporary folder, including decisions, asset provenance, integration history, and known gaps. I’ll leave the game files unchanged.
```

<!-- markdownlint-enable MD013 -->
