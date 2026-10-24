# Game sound auditions

Open [the portable sound page](drain-damage-sound-auditions.html) in a browser. It embeds the audio
and works offline.
Groups and sound tables start collapsed. Search by ID, character, action, or filename.
For example, search `gnat`, then expand Gnatastrophe to open all its sound tables. Playback uses source volume, not the
game's mix. Nothing autoplays.

Regenerate after **every audio creation or change**, including audition-only changes, and commit the result with
the audio. Keep all auditions in the repository unless Sean explicitly requests otherwise. Rejected candidates and
repeated demonstrations remain available; never overwrite an earlier file.

Rebuild from the repository root:

```sh
python3 tools/build_sound_auditions.py
python3 tools/build_sound_auditions.py --check
```

[The sound registry](sound-registry.json) maps permanent `DD-S0001`-style project-wide IDs and globally unique UUIDs
onto logical sound slots, their files, and their authoritative runtime sources. A slot can contain multiple current
clips (such as randomized hit variants). Shared files can serve separate slots; requesting an alternative targets the
named action, not every use of that file. Sean and Tony currently share jump, hurt, and death cues.

## Requesting and adding alternatives

Ask Audio: “Give me three alternatives for DD-S0001.” Audio should read this registry and the listed source/provenance,
then create `DD-S0001.1.wav`, `DD-S0001.2.wav`, etc. under `audio/alternatives/DD-S0001/`.
Append each candidate to that slot's `alternatives` array:

```json
{"id": "DD-S0001.1", "path": "audio/alternatives/DD-S0001/DD-S0001.1.wav"}
```

Use the next unused positive suffix. Never overwrite candidates or recycle IDs. Preserve generation prompts and source
licenses with the candidate delivery. Rebuild the page to compare candidates beside the current sound. Adding a
candidate
is an audition only; selecting it still requires integration into the listed runtime mapping and relevant game checks.
The globally unique candidate identity is the parent UUID plus the same numeric suffix.

After intentional runtime mapping changes, review and reconcile:

```sh
python3 tools/build_sound_auditions.py --refresh
```

Refresh preserves existing identities and alternatives, assigns IDs to new slots, and retains removed slots
as retired.
Commit the registry with the regenerated page. Do not delete and regenerate the registry to renumber it.

## Mapping sources and coverage

Monster hit/death mappings live in `bestiary/*/monster.json`, bundled into `data/combat.json`. Dispenser mappings are in
that generated bundle too. Other encounter sounds, weapons, music, doors, and menu cues currently live in GDScript.
This registry is a unified review index, not a replacement for those runtime sources. The generator reads those mappings
and rejects stale registered values or missing files. Its code adapters must be extended when new audio systems are
added;
it is not a general GDScript interpreter. Rebuild combat data first if its canonical sources change.

The page includes current mapped audio and reset-phase previews of the three synthesized square-wave cues. The runtime
oscillator's carried phase can differ. All 17 existing weapon candidates and their repeated demonstrations are
registered under the weapon slots.
Other historical source archives remain preserved; register further candidates under the relevant slot when auditioning
them. The older [weapon auditions](../drain-damage-all-weapon-auditions.html) also remain available. Level 2 has no
assigned
sounds yet.
Add future sections to the generator's `SECTIONS` and assign their slots when those levels are implemented.

The older `audio/catalog.json` tracks delivery history and is incomplete; use this registry for current audition IDs.
No game behavior or mix is changed by building this page.

## Freshness check

The audio-auditions GitHub workflow runs the generator’s freshness check on pushes and pull requests. It fails when
the committed HTML differs from regenerated output, including when audio bytes change at an existing path.
Run the generator locally and include its output before pushing; CI verifies rather than making automatic commits.
