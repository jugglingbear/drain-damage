#!/usr/bin/env python3
"""Validate Art's modular mockup and build a local, interactive layer contact sheet."""

import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/prototypes/modular-aim/manifest.json"
OUTPUT = ROOT / "previews/modular-aim.html"
PAIRS = {"tony": "pressure-gun", "sean": "heavy-plunger-launcher"}
DIRECTIONS = {"right", "up_right", "up"}


def build() -> None:
    """Reject incomplete pose sets and generate a preview using only delivered raster layers."""
    data = json.loads(MANIFEST.read_text())
    scale = data.get("source_scale", 1)
    if type(scale) is not int or scale < 1:
        raise ValueError("source_scale must be a positive integer")
    seen: set[tuple[str, str]] = set()
    cards: list[str] = []
    render_poses: list[dict] = []
    bodies: dict[str, dict] = {}
    for pose in data["poses"]:
        hero, direction = pose["hero"], pose["direction"]
        if PAIRS.get(hero) != pose["weapon"] or direction not in DIRECTIONS or (hero, direction) in seen:
            raise ValueError("Invalid, duplicate or incorrectly equipped pose")
        seen.add((hero, direction))
        layers: list[dict] = []
        roles: set[str] = set()
        for layer in pose["layers"]:
            role = layer["role"]
            if role not in {"body", "back_arm", "weapon", "front_hand", "front_arm"} or role in roles:
                raise ValueError(f"Invalid or duplicate layer role: {role}")
            roles.add(role)
            path = (ROOT / layer["path"]).resolve()
            if not path.is_relative_to(ROOT):
                raise ValueError("Layer path escapes repository")
            raw = path.read_bytes()
            if raw[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError(f"Expected PNG: {path}")
            width, height = struct.unpack(">II", raw[16:24])
            region = layer.get("source_rect", [0, 0, width, height])
            destination = layer.get("destination", [0, 0, 128, 128])
            pivot = layer.get("pivot", [64, 104])
            rotation = layer.get("rotation_degrees", 0)
            if len(region) != 4 or len(destination) != 4 or len(pivot) != 2:
                raise ValueError("Malformed layer transform")
            if any(type(v) not in (int, float) or not math.isfinite(v)
                   for v in region + destination + pivot + [rotation]):
                raise ValueError("Nonfinite layer transform")
            x, y, w, h = region
            if min(x, y) < 0 or min(w, h) <= 0 or x + w > width or y + h > height:
                raise ValueError(f"Source region outside {path}")
            if min(destination[2:]) <= 0:
                raise ValueError("Destination must have positive dimensions")
            layers.append({"role": role, "src": "../" + path.relative_to(ROOT).as_posix(),
                           "source_rect": region, "destination": destination,
                           "pivot": pivot, "rotation_degrees": rotation})
        if not {"body", "weapon"}.issubset(roles):
            raise ValueError("Each pose needs separate body and weapon layers")
        body = next(layer for layer in layers if layer["role"] == "body")
        if hero in bodies and bodies[hero] != body:
            raise ValueError(f"Standing body must remain identical across directions: {hero}")
        bodies[hero] = body
        if not roles.intersection({"back_arm", "front_hand", "front_arm"}):
            raise ValueError("Mockup requires separate arm/hand artwork")
        anchors = {"feet": [64, 104], **{key: pose[key] for key in ["grip", "support_hand", "muzzle"]}}
        for name, point in anchors.items():
            if len(point) != 2 or any(type(v) not in (int, float) or not 0 <= v <= 128 for v in point):
                raise ValueError(f"Invalid logical anchor: {name}")
        render_poses.append({"layers": layers, "anchors": anchors})
        cards.append(f'<article><h2>{hero.title()} · {direction.replace("_", " ")}</h2>'
                     f'<canvas class="stage" width="512" height="512" data-pose="{len(cards)}"></canvas>'
                     '<p>Feet: white · grip: gold · support: cyan · muzzle: pink</p></article>')
    if seen != {(hero, direction) for hero in PAIRS for direction in DIRECTIONS}:
        raise ValueError("Expected exactly six poses")
    controls = ''.join(f'<label><input type="checkbox" checked data-toggle="{role}">{role.replace("_", " ")}</label>'
                       for role in ["body", "back_arm", "weapon", "front_hand", "front_arm"])
    page = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Modular aiming mockup</title>
<style>
body{margin:0;padding:28px;background:#101c24;color:#eee9dd;font:16px system-ui}h1{margin-top:0}
.controls{display:flex;gap:18px;flex-wrap:wrap;padding:18px;background:#24383d;border-radius:8px}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px;margin-top:20px}
article{background:#1c3037;padding:16px;border-radius:10px}h2{font-size:18px}article p{font-size:12px}
.stage{display:block;width:256px;height:256px;margin:auto;image-rendering:pixelated;
background:repeating-conic-gradient(#35434a 0% 25%,#29363d 0% 50%) 50% / 16px 16px}label{cursor:pointer}
</style><h1>Modular aiming mockup</h1>
<p>Art-layer study only. This is not a gameplay screenshot or a finished animation set.</p>
<div class="controls">CONTROLS<label><input id="mirror" type="checkbox">Mirror left</label>
<label><input id="anchors" type="checkbox" checked>Show anchors</label></div><main>CARDS</main>
<script>
const poses=POSE_DATA;
const images=new Map();
const colors={feet:'white',grip:'#ffcf70',support_hand:'cyan',muzzle:'#ff80b0'};
function draw(){
 const toggles=[...document.querySelectorAll('[data-toggle]')];
 const hidden=new Set(toggles.filter(i=>!i.checked).map(i=>i.dataset.toggle));
 document.querySelectorAll('canvas').forEach(canvas=>{
  const pose=poses[Number(canvas.dataset.pose)],c=canvas.getContext('2d');
  c.setTransform(1,0,0,1,0,0);c.clearRect(0,0,512,512);c.scale(4,4);c.imageSmoothingEnabled=false;
  if(document.querySelector('#mirror').checked){c.translate(128,0);c.scale(-1,1);}
  for(const layer of pose.layers){
   if(hidden.has(layer.role))continue;
   c.save();c.translate(...layer.pivot);c.rotate(layer.rotation_degrees*Math.PI/180);
   c.translate(-layer.pivot[0],-layer.pivot[1]);
   c.drawImage(images.get(layer.src),...layer.source_rect,...layer.destination);c.restore();
  }
  if(document.querySelector('#anchors').checked)for(const [name,p] of Object.entries(pose.anchors)){
   c.fillStyle=colors[name];c.fillRect(p[0]-1,p[1]-1,2,2);
  }
 });
}
Promise.all([...new Set(poses.flatMap(p=>p.layers.map(l=>l.src)))].map(src=>new Promise((resolve,reject)=>{
 const image=new Image();image.onload=()=>{images.set(src,image);resolve();};
 image.onerror=()=>reject(new Error('Cannot load '+src));image.src=src;
}))).then(()=>{draw();document.querySelectorAll('input').forEach(input=>input.addEventListener('change',draw));})
.catch(error=>{document.querySelector('main').textContent=error.message;});
</script></html>
'''
    page = page.replace('CONTROLS', controls).replace('CARDS', ''.join(cards))
    page = page.replace('POSE_DATA', json.dumps(render_poses).replace('<', '\\u003c'))
    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(page)
    print(f"Validated six poses and built {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    build()
