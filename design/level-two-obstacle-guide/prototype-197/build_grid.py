"""Compose the requested guide from unchanged native captures."""
from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path('/Users/sfoley/repos/drain_damage')
OUT = ROOT / 'design/level-two-obstacle-guide'
CAP = OUT / 'sources'
FONT = Path('/System/Library/Fonts/Supplemental')
COLORS = ['#81dfbc', '#f3ba68', '#b6b5f0']


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT / ('Arial Bold.ttf' if bold else 'Arial.ttf')), size)


def item(title: str, action: str, note: str, index: int, stamp: int,
         crop: tuple[int, int, int, int], status: str = 'SHOWCASE') -> dict:
    return dict(title=title, action=action, note=note, encounter=f'2-{index:02d}',
                source=str(CAP / f'encounter-{index:02d}-{stamp}.png'), crop=crop, status=status)


def native(title: str, action: str, note: str, filename: str, encounter: str) -> dict:
    return dict(title=title, action=action, note=note, encounter=encounter,
                source=str(OUT / 'sources' / filename),
                crop=(0, 65, 960, 535), status='CONTINUOUS SLICE')


DODGE = [
    native('Valve-stem slalom', 'STEER around alternating obstructions', 'Wall baffles + upright center valve',
           'tony-normal-x300-yaw18-0030.png', '2-01'),
    item('Elbow-pipe breach', 'STEER along the clear far bank', 'Avoid the pipe and its long waterfall pit',
         2, 32, (330, 210, 960, 540)),
    item('Chain-hung plug', 'STEER around the hanging plug', 'Stay grounded; jumping is not the route',
         3, 38, (330, 95, 950, 520)),
    item('Giant brush curtain', 'WEAVE between the ceiling brushes', 'Keep out of the bristles',
         4, 38, (330, 90, 950, 530)),
    item('Float-arm sweep', 'STEER through the open bank lane', 'Watch the ball sweep on its mounted arm',
         6, 38, (320, 150, 930, 530)),
]
JUMP = [
    item('Channel-flange hop', 'JUMP over the raised joints', 'The close pair clears in one hop',
         5, 38, (280, 160, 950, 535), 'SHOWCASE + SLICE'),
    item('Buckled drain grate', 'JUMP above the torn metal spikes', 'Full-channel barrier',
         9, 38, (300, 150, 950, 535)),
    item('Maintenance hand', 'JUMP the hole after the hand clears', 'The hand destroys the whole channel width',
         11, 32, (350, 110, 960, 535)),
    item('Straight cleanout caps', 'JUMP from cap to cap', 'Original aligned showcase variant',
         7, 47, (0, 140, 960, 535)),
]
BOTH = [
    native('Staggered cleanout caps', 'STEER AND JUMP between smaller caps', 'Current variant: alternate near / far landings',
           'tony-normal-x300-yaw18-0130.png', '2-07 variant'),
    item('Broken-basin hopscotch', 'STEER AND JUMP onto each slab', 'Alternating porcelain landing platforms',
         8, 47, (0, 135, 960, 535)),
    item('Strainer: middle lane', 'DODGE OR JUMP the resulting hole', 'Wait for the falling basket to clear',
         12, 32, (340, 90, 960, 535), 'SHOWCASE + SLICE FAMILY'),
    item('Strainer: two lanes', 'DODGE OR JUMP the wider-lane hole', 'Short showcase cut: clear bank route or timed hop',
         13, 32, (340, 90, 960, 535)),
    item('Emergency flume launch', 'ALIGN + AUTOMATIC LAUNCH', 'Stay grounded on the ramp; do not press jump',
         10, 38, (230, 190, 960, 535)),
    native('Slalom + flange jumps', 'STEER AND JUMP through the sequence', 'Integrated combo; joints also between machines',
           'tony-normal-x300-yaw18-0050.png', '2-01 + 2-05'),
]
DODGE.extend([
    native('Long strainer: one lane', 'STEER around; too long to jump', 'Long footprint; clear opposite bank remains',
           'tony-normal-x300-yaw18-1194.png', '197 continuous'),
    native('Long strainer: two lanes', 'STEER into the remaining bank lane', 'Long footprint; do not attempt a full-length jump',
           'tony-normal-x300-yaw18-1290.png', '197 continuous'),
])
JUMP.append(native('Short strainer: all three lanes', 'JUMP after the basket retracts',
                   'Short full-width cut; no side route',
                   'tony-normal-x300-yaw18-1131.png', '197 continuous'))
GROUPS = [DODGE, JUMP, BOTH]
HEADINGS = ['DODGE', 'JUMP', 'BOTH']
SUBHEADS = ['Choose a clear lane', 'Time the takeoff', 'Read AND, OR and AUTO carefully']
WIDTH, HEIGHT = 2400, 3900
MARGIN, COLUMN, GAP, ROW = 48, 752, 24, 490


def wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int],
            size: int, color: str, width: int, bold: bool = False) -> None:
    face = font(size, bold)
    line = ''
    x, y = xy
    for word in text.split():
        proposed = (line + ' ' + word).strip()
        if draw.textlength(proposed, font=face) > width and line:
            draw.text((x, y), line, font=face, fill=color)
            line = word
            y += size + 7
        else:
            line = proposed
    draw.text((x, y), line, font=face, fill=color)


def card(canvas: Image.Image, entry: dict, x: int, y: int, color: str) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((x, y, x+COLUMN, y+ROW-18), radius=16, fill='#172a35', outline='#35505c', width=2)
    draw.text((x+20, y+16), entry['title'], font=font(33, True), fill='#f7efdd')
    draw.text((x+20, y+60), entry['status'], font=font(18, True), fill=color)
    original = Image.open(entry['source']).convert('RGB')
    cropped = original.crop(entry['crop'])
    picture = ImageOps.contain(cropped, (COLUMN-40, 272), Image.Resampling.LANCZOS)
    px = x+(COLUMN-picture.width)//2
    py = y+90+(272-picture.height)//2
    canvas.paste(picture, (px, py))
    draw.line((x+20, y+377, x+COLUMN-20, y+377), fill=color, width=2)
    wrapped(draw, entry['action'], (x+20, y+391), 24, color, COLUMN-40, True)
    wrapped(draw, entry['note'], (x+20, y+431), 21, '#c3d2d7', COLUMN-40)


def main() -> None:
    """Save the overview, category detail sheets and source provenance."""
    canvas = Image.new('RGB', (WIDTH, HEIGHT), '#0b1923')
    draw = ImageDraw.Draw(canvas)
    draw.text((MARGIN, 35), 'DRAIN DAMAGE  /  LEVEL 2 OBSTACLE FIELD GUIDE', font=font(48, True), fill='#f7efdd')
    draw.text((MARGIN, 103), 'Actual game captures • 13 showcase encounters + current continuous variants',
              font=font(29), fill='#a9c1cb')
    draw.text((MARGIN, 148), 'SHOWCASE = individual test encounter. CONTINUOUS SLICE = placed in the current course.',
              font=font(24), fill='#a9c1cb')
    for col, entries in enumerate(GROUPS):
        x = MARGIN+col*(COLUMN+GAP)
        draw.rounded_rectangle((x, 210, x+COLUMN, 312), radius=12, fill=COLORS[col])
        draw.text((x+20, 220), HEADINGS[col], font=font(40, True), fill='#0b1923')
        draw.text((x+20, 272), SUBHEADS[col], font=font(23), fill='#0b1923')
        for row, entry in enumerate(entries):
            card(canvas, entry, x, 334+row*ROW, COLORS[col])
            source = Path(entry['source'])
            copied = OUT/'sources'/source.name
            if source.resolve() != copied.resolve():
                shutil.copy2(source, copied)
            entry['saved_source'] = str(copied.relative_to(ROOT))
    wrapped(draw, 'PICTURES SHOW THE OBSTACLES', (824, 2870), 29, COLORS[1], COLUMN-40, True)
    wrapped(draw, 'Native game captures. Rider positions are not route diagrams.',
            (824, 2930), 27, '#c3d2d7', COLUMN-45)
    draw.text((MARGIN, 3810), 'Capture basis: Prototype 195 showcase + 197 continuous additions • 23 Nov 2026 • Category review: Level Design',
              font=font(24), fill='#a9c1cb')
    draw.text((MARGIN, 3850), 'Ramp launch is automatic. “Both” includes combined skills and alternative routes, as labeled.',
              font=font(24), fill='#a9c1cb')
    canvas.save(OUT/'obstacles-dodge-jump-both.png')
    for col in range(3):
        x = MARGIN+col*(COLUMN+GAP)
        detail = Image.new('RGB', (832, 3710), '#0b1923')
        detail.paste(canvas.crop((x, 210, x+COLUMN, 3770)), (40, 65))
        ImageDraw.Draw(detail).text((40, 20), 'LEVEL 2  /  '+HEADINGS[col], font=font(26, True), fill='#f7efdd')
        detail.save(OUT/(HEADINGS[col].lower()+'-detail.png'))
    manifest = dict(date='2026-11-23', method='Native Prototype195 showcase and Prototype197 new continuous variants; crop/scale/layout only',
                    status='Art inspected; all18 categories accepted by Level Design', groups=dict(zip(HEADINGS, GROUPS)))
    previous = json.loads((OUT/'prototype-195/sources.json').read_text())
    originals = {entry['title']: entry['source']
                 for entries in previous['groups'].values() for entry in entries}
    for entries in GROUPS:
        for entry in entries:
            entry['original_capture'] = originals.get(
                entry['title'], str(ROOT/'previews/ride-197/final'/Path(entry['source']).name))
    manifest['self_review'] = '18 cards inspected; new long cuts and full-width short cut use final197 captures.'
    manifest['capture_log'] = 'previews/ride-197/final/qa.log'
    (OUT/'sources.json').write_text(json.dumps(manifest, indent=2)+'\n')


if __name__ == '__main__':
    main()
