#!/usr/bin/env python3
"""Build portable auditions and maintain permanent sound-slot identities from current mappings."""

import argparse
import base64
import html
import io
import json
import math
import re
import struct
import uuid
import wave
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "audio/sound-registry.json"
OUTPUT = ROOT / "audio" / "drain-damage-sound-auditions.html"
SECTIONS = ["Hero sounds — Sean and Tony", "Weapon sounds", "Level 1", "Level 2", "Menus and shared sounds"]


def discover() -> dict[str, dict[str, Any]]:
    """Read canonical profiles and the game's current, deliberately supported code mappings."""
    slots: dict[str, dict[str, Any]] = {}

    def add(key: str, section: str, name: str, paths: list[str], source: str) -> None:
        slots[key] = dict(section=section, name=name, paths=paths, source=source)

    for profile in sorted((ROOT / "bestiary").glob("*/monster.json")):
        data = json.loads(profile.read_text())
        for event in ("hit", "death"):
            add(f"creature/{data['id']}/{event}", "Level 1", f"{data['name']} — {event}",
                [v["path"] for v in data["audio"][event]["variants"]], str(profile.relative_to(ROOT)))

    for filename, owner in [("skitterling_audio.gd", "Skitterling"), ("clogfather_audio.gd", "Clogfather")]:
        source = f"scripts/{filename}"
        text = (ROOT / source).read_text()
        constants = dict(re.findall(r'const (\w+)\s*:?=\s*"res://([^"\n]+)"', text))
        block = text.split("const CUES := {", 1)[1].split("\n}", 1)[0]
        for event, expression in re.findall(r'"([\w_]+)":\s*\[([^\]]+)\]', block):
            if owner == "Skitterling":
                version, name = re.search(r'(V\d)\+"([^"]+)"', expression).groups()
                paths = [constants[version] + name]
            else:
                base = constants["ROAR_BASE" if event.endswith("roar") else "BASE"]
                paths = [base + name + ".wav" for name in re.findall(r'"([^"]+)"', expression)]
            add(f"{owner.lower()}/{event}", "Level 1", f"{owner} — {event.replace('_', ' ')}", paths, source)
        if owner == "Skitterling":
            for name in ("formed-loop", "dispersed-loop"):
                add(f"skitterling/{name}", "Level 1", f"Skitterling — {name}",
                    [constants["V1"] + name + ".wav"], source)

    simple = {
        "hero_death_audio.gd": (SECTIONS[0], "Sean and Tony — death flush"),
        "swarm_audio.gd": ("Level 1", "Gnatastrophe — ambient swarm"),
        "flushfiend_death_audio.gd": ("Level 1", "Flushfiend — porcelain shatter"),
        "door_audio.gd": ("Level 1", "Progress door"),
        "title_screen.gd": (SECTIONS[4], "Menu navigation"),
        "music_director.gd": ("Level 1", "Music"),
    }
    for filename, (section, owner) in simple.items():
        source = f"scripts/{filename}"
        for index, path in enumerate(re.findall(r'"res://([^"\n]+\.(?:wav|ogg))"', (ROOT / source).read_text())):
            group = SECTIONS[4] if filename == "music_director.gd" and index == 0 else section
            add(f"{filename}/{index}", group, f"{owner} — {Path(path).stem}", [path], source)

    source = "scripts/starter_weapon_audio.gd"
    text = (ROOT / source).read_text()
    base = re.search(r'"res://([^"\n]+/)"', text)[1]
    for hero, filename in re.findall(r'"(tony|sean)"\s*:\s*"([^"]+\.wav)"', text):
        add(f"weapon/{hero}/shot", SECTIONS[1], f"{hero.title()} — starter weapon shot", [base + filename], source)

    dispenser = json.loads((ROOT / "data/combat.json").read_text())["dispenser"]["audio"]
    for cue in dispenser["cues"]:
        events = [event for event, ids in dispenser["event_mapping"].items() if cue["cue_id"] in ids]
        add(f"dispenser/{cue['cue_id']}", "Level 1", f"Employee dispenser — {', '.join(events)}",
            [cue["path"]], "data/combat.json#/dispenser/audio")

    tones = re.findall(r'play_tone\(([\d.]+),\s*([\d.]+)\)', (ROOT / "scripts/game.gd").read_text())
    labels = {540: ("checkpoint", "Level 1"), 360: ("Sean and Tony — jump", SECTIONS[0]),
              65: ("Sean and Tony — hurt", SECTIONS[0])}
    for frequency, duration in tones:
        name, section = labels[int(float(frequency))]
        key = f"tone/{name}"
        add(key, section, name, [], "scripts/game.gd: play_tone / fill_audio")
        slots[key]["tone"] = [float(frequency), float(duration)]
    flush_audio = json.loads((ROOT / "handoffs/level-two-flush-audio.json").read_text())
    flush_audio["cues"].append(json.loads((ROOT / "handoffs/level-two-flush-audio-v2.json").read_text())["cue"])
    for cue in flush_audio["cues"]:
        if cue["event"] == "debris_break":
            continue  # Swimming has no breakable props; retain the old slot and audition as retired.
        add(f"level-two-flush/{cue['event']}", "Level 2", f"The Flush — {cue['event'].replace('_', ' ')}",
            [cue["path"]], "data/level-two-flush.json#/audio")
    flush = json.loads((ROOT / "data/level-two-flush.json").read_text())
    if "music" in flush:
        add("proposed-flush/countdown-music", "Level 2", "The Flush — Air Running Out music",
            [flush["music"]["path"]], "data/level-two-flush.json#/music")
    ride_path = ROOT / "data/level-two-ride.json"
    if ride_path.exists():
        ride = json.loads(ride_path.read_text())
        if "music" in ride:
            add("proposed-level-two-ride/music", "Level 2", "Ride music — Fighting Is Not an Option",
                [ride["music"]["path"]], "data/level-two-ride.json#/music")
        for cue in ride.get("audio", {}).get("cues", []):
            add(f"level-two-ride/{cue['event']}", "Level 2", f"Log ride — {cue['event'].replace('_', ' ')}",
                [cue["path"]], "data/level-two-ride.json#/audio")
            if "trigger" in cue:
                slots[f"level-two-ride/{cue['event']}"]["trigger"] = cue["trigger"]
    return slots


def refresh(registry: dict[str, Any], slots: dict[str, dict[str, Any]]) -> None:
    """Retain IDs and alternatives across file replacements; never recycle retired slots."""
    records = registry.setdefault("sounds", [])
    by_key = {record["key"]: record for record in records}
    next_number = max((int(record["id"].split("S")[-1]) for record in records), default=0) + 1
    for key, slot in slots.items():
        if key not in by_key:
            record = dict(key=key, id=f"DD-S{next_number:04d}", uuid=str(uuid.uuid4()), alternatives=[])
            records.append(record)
            by_key[key] = record
            next_number += 1
        by_key[key].update(slot, status="current")
    for record in records:
        if record["key"] not in slots and record.get("status") != "proposed":
            record["status"] = "retired"


def validate(registry: dict[str, Any], slots: dict[str, dict[str, Any]]) -> None:
    """Reject stale mappings, duplicate identities, unsafe paths and missing audio."""
    identities: set[str] = set()
    keys: set[str] = set()
    current = {}
    for record in registry["sounds"]:
        if record["key"] in keys:
            raise ValueError("Duplicate sound key")
        keys.add(record["key"])
        for identity in (record["id"], record["uuid"]):
            if identity in identities:
                raise ValueError(f"Duplicate ID: {identity}")
            identities.add(identity)
        uuid.UUID(record["uuid"])
        if record["status"] == "proposed" and (record["paths"] or "tone" in record):
            raise ValueError("Proposed slots must contain alternatives only, not current audio")
        paths = list(record["paths"])
        for alternative in record["alternatives"]:
            identity = alternative["id"]
            if not re.fullmatch(re.escape(record["id"]) + r'\.[1-9]\d*', identity) or identity in identities:
                raise ValueError(f"Invalid or duplicate alternative: {identity}")
            identities.add(identity)
            paths.append(alternative["path"])
            if "repeated_path" in alternative:
                paths.append(alternative["repeated_path"])
        for path in paths:
            resolved = (ROOT / path).resolve()
            if not resolved.is_relative_to(ROOT) or not resolved.is_file():
                raise ValueError(f"Missing or unsafe audio path: {path}")
        if record["status"] == "current":
            current[record["key"]] = {key: record[key] for key in slots.get(record["key"], {})}
    if current != slots:
        raise ValueError("Runtime mappings changed. Review and run --refresh; IDs will be preserved.")


def tone_bytes(frequency: float, duration: float) -> bytes:
    """Preview the game's square-wave envelope with a reset phase (runtime phase can vary)."""
    rate = 22050
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as output:
        output.setparams((1, 2, rate, 0, "NONE", "not compressed"))
        samples = []
        for index in range(math.ceil(duration * rate)):
            phase = (index + 1) * frequency / rate
            amplitude = (0.075 if phase % 1 < 0.5 else -0.075) * min((duration - index / rate) * 30, 1)
            samples.append(struct.pack("<h", round(amplitude * 32767)))
        output.writeframes(b"".join(samples))
    return buffer.getvalue()


def render(registry: dict[str, Any]) -> str:
    """Embed original audio bytes in a searchable, offline audition page."""
    esc = html.escape
    style = (ROOT / "audio/sources/starter-weapons-audition-v1/index.html").read_text()
    style = style.split("<style>")[1].split("</style>")[0]
    parts = ['<!doctype html><html lang="en"><meta charset="utf-8">',
             '<meta name="viewport" content="width=device-width,initial-scale=1">',
             '<title>Drain Damage — sound auditions</title><style>' + style,
             'input,button {font:inherit;padding:9px;background:#243440;color:#edf2f5;border:1px solid #657784}',
             'code {user-select:all} nav a {margin-right:20px} td small {overflow-wrap:anywhere}',
             'tr.current-sound {background:#183f30} tr.current-sound th {border-left:5px solid #70e5a0}',
             '.in-game {display:inline-block;background:#9af0b9;color:#103222;font-size:.75rem;',
             'font-weight:800;padding:3px 9px;border-radius:5px;margin-right:10px;letter-spacing:.05em}',
             '</style><header><div class="tag">Drain Damage · sound library</div><h1>Every game sound</h1>',
             '<p>Ask Audio for alternatives to an ID, for example <code>DD-S0001</code>. '
             'New candidates become <code>DD-S0001.1</code>, <code>DD-S0001.2</code>, and so on. '
             'A candidate does not change the game until it is selected and integrated.</p>',
             '<p>Original files play at source volume, without the game’s mixing, fades or layering. '
             'Expand a group to see its sounds and alternatives. '
             'Shared cues are labelled; separate actions retain separate IDs even when they reuse a file. '
             'Historical unused files remain in the source archives.</p>',
             '<label>Find a sound <input id="search" type="search" placeholder="ID, character, action…"></label> '
             '<button id="stop">Stop all sounds</button><p id="results" role="status"></p><nav>']
    parts += [f'<a href="#section-{index}">{esc(section)}</a>' for index, section in enumerate(SECTIONS)]
    parts.append('</nav></header>')
    for index, section in enumerate(SECTIONS):
        parts.append(f'<section id="section-{index}"><h2>{esc(section)}</h2>')
        records = [r for r in registry["sounds"] if r["section"] == section and r["status"] in ("current", "proposed")]
        if not records:
            parts.append('<p>No sounds assigned yet. This level is not implemented.</p></section>')
            continue
        groups: dict[str, list[dict[str, Any]]] = {}
        for record in records:
            group = record.get("group", record["name"].split(" — ")[0])
            groups.setdefault(group, []).append(record)
        for group, members in groups.items():
            parts.append(f'<details class="sound-group"><summary>{esc(group)} · {len(members)} sounds</summary>')
            for record in members:
                identity = record["id"]
                parts.append(f'<details class="sound-slot"><summary><code>{esc(identity)}</code> · '
                             f'{esc(record["name"])} · {len(record["alternatives"])} alternatives</summary>')
                if record["status"] == "proposed":
                    parts.append('<p><strong>PROPOSED — NOT IN GAME</strong> · Auditions only.</p>')
                parts.append(f'<p><small>{esc(record["source"])} · Global UUID: {esc(record["uuid"])}</small></p>')
                if record.get("trigger"):
                    parts.append(f'<p>{esc(record["trigger"])}</p>')
                parts.append('<div class="table-wrap"><table><thead><tr><th>ID</th><th>Version</th>'
                             '<th>Listen</th></tr></thead><tbody>')
                clips = [(identity, "Current", path, (ROOT / path).read_bytes()) for path in record["paths"]]
                if "tone" in record:
                    clips.append((identity, "Current — synthesized preview (reset phase)", "",
                                  tone_bytes(*record["tone"])))
                for alternative in record["alternatives"]:
                    path = alternative["path"]
                    clips.append((alternative["id"], alternative.get("name", "Alternative"), path,
                                  (ROOT / path).read_bytes()))
                    if "repeated_path" in alternative:
                        path = alternative["repeated_path"]
                        clips.append((alternative["id"], "Five-shot demonstration", path, (ROOT / path).read_bytes()))
                for clip_id, label, path, payload in clips:
                    mime = "audio/ogg" if path.endswith(".ogg") else "audio/wav"
                    encoded = base64.b64encode(payload).decode("ascii")
                    row_class = ' class="current-sound"' if clip_id == identity else ""
                    badge = '<span class="in-game">IN GAME</span> ' if clip_id == identity else ""
                    parts.append(f'<tr{row_class}><th scope="row"><code>{esc(clip_id)}</code></th>'
                                 f'<td>{badge}{esc(label)}<small>{esc(path)}</small></td><td>'
                                 f'<audio controls preload="none" aria-label="{esc(record["name"])} '
                                 f'{esc(clip_id)} {esc(label)}" src="data:{mime};base64,{encoded}"></audio></td></tr>')
                parts.append('</tbody></table></div></details>')
            parts.append('</details>')
        parts.append('</section>')
    parts.append('''<script>
const players = [...document.querySelectorAll('audio')];
for (const player of players) player.addEventListener('play', () => {
  for (const other of players) if (other !== player) other.pause();
});
document.querySelector('#stop').onclick = () => {
  for (const player of players) { player.pause(); player.currentTime = 0; }
};
document.querySelector('#search').oninput = event => {
  const query = event.target.value.trim().toLowerCase();
  let matches = 0;
  for (const group of document.querySelectorAll('.sound-group')) {
    const groupMatch = group.querySelector('summary').textContent.toLowerCase().includes(query);
    let visible = false;
    for (const slot of group.querySelectorAll('.sound-slot')) {
      slot.hidden = !(groupMatch || slot.textContent.toLowerCase().includes(query));
      if (!slot.hidden) visible = true;
    }
    group.hidden = !visible;
    if (visible) matches++;
  }
  for (const section of document.querySelectorAll('section')) {
    section.hidden = !!query && ![...section.querySelectorAll('.sound-group')].some(group => !group.hidden);
  }
  document.querySelector('#results').textContent = query ? `${matches} matching groups` : '';
};
for (const group of document.querySelectorAll('.sound-group')) {
  group.addEventListener('toggle', () => {
    for (const slot of group.querySelectorAll('.sound-slot')) slot.open = group.open;
  });
};
</script></html>''')
    return "\n".join(parts) + "\n"


def main() -> None:
    """Refresh explicitly, otherwise fail on drift, then generate the portable page."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true", help="Reconcile mappings without changing existing IDs")
    parser.add_argument("--check", action="store_true", help="Validate only; do not write the HTML")
    args = parser.parse_args()
    registry = json.loads(REGISTRY.read_text()) if REGISTRY.exists() else {"schema_version": 1, "sounds": []}
    slots = discover()
    if args.refresh:
        refresh(registry, slots)
    validate(registry, slots)
    if args.refresh:
        REGISTRY.write_text(json.dumps(registry, indent=2) + "\n")
    page = render(registry)
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text() != page:
            raise ValueError("Audition HTML is stale. Run tools/build_sound_auditions.py and commit the result.")
    else:
        OUTPUT.write_text(page)
    print(f"Validated {len(slots)} sound slots. {'Checked' if args.check else 'Built'} {OUTPUT.name}")


if __name__ == "__main__":
    main()
