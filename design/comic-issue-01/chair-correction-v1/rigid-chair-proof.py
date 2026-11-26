from pathlib import Path
import math

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

ROOT = Path('/Users/sfoley/repos/drain_damage/design/comic-issue-01/chair-correction-v1')
WIDTH = 43.0
DEPTH = 43.0
HEIGHT = 85.0
SEAT = 45.0
ANGLE = 18.0

def project(point: tuple[float, float, float], angle: float) -> tuple[float, float]:
    """Rotate rigidly around rear-foot axis before fixed orthographic projection."""
    x, y, z = point
    a = math.radians(angle)
    yy, zz = y * math.cos(a) - z * math.sin(a), y * math.sin(a) + z * math.cos(a)
    return 0.85 * x + 0.75 * yy, zz - 0.23 * yy + 0.13 * x

fig, axes = plt.subplots(1, 2, figsize=(12, 6))
for ax, angle, title in zip(axes, [0, ANGLE], ['UPRIGHT', 'SAME CHAIR • ROTATED 18°']):
    def line(a: tuple[float, float, float], b: tuple[float, float, float], color: str = '#60452e') -> None:
        pa, pb = project(a, angle), project(b, angle)
        ax.plot([pa[0], pb[0]], [pa[1], pb[1]], color=color, lw=6, solid_capstyle='butt')
    for x in [0, WIDTH]:
        for y in [0, DEPTH]:
            line((x,y,0), (x,y,HEIGHT if y == 0 else SEAT))
        line((x,0,18), (x,DEPTH,18))
    for y in [0, DEPTH]:
        line((0,y,18), (WIDTH,y,18))
    seat = [project(p,angle) for p in [(0,0,SEAT),(WIDTH,0,SEAT),(WIDTH,DEPTH,SEAT),(0,DEPTH,SEAT)]]
    ax.add_patch(Polygon(seat, facecolor='#e5c79d', edgecolor='#33281e', lw=2, zorder=5))
    for z in [56,HEIGHT]:
        line((0,0,z), (WIDTH,0,z))
    for x in [WIDTH/4, WIDTH/2, WIDTH*3/4]:
        line((x,0,56), (x,0,HEIGHT))
    for x in [0,WIDTH]:
        for y in [0,DEPTH]:
            a=math.radians(angle)
            yy=y*math.cos(a)
            floor=(.85*x+.75*yy, -.23*yy+.13*x)
            ax.plot(floor[0],floor[1], '_', color='#999999', ms=20, mew=3)
            if y and angle:
                foot=project((x,y,0),angle)
                ax.plot([floor[0],foot[0]],[floor[1],foot[1]],'--',color='#188278',lw=1)
    ax.set_title(title, fontsize=14)
    ax.set_xlim(-35,85)
    ax.set_ylim(-20,105)
    ax.set_aspect('equal')
    ax.axis('off')
fig.suptitle('Rigid chair construction proof — dimensions proposed from panel 2',fontsize=15)
fig.text(.5,.06,'Seat 43 × 43 cm | Seat height 45 cm | Back height 85 cm | Front-foot lift 13.3 cm',ha='center')
fig.text(.5,.025,'Identical geometry and projection; only rotation changes. Gray marks = floor shadows. No figures.',ha='center',fontsize=10)
fig.savefig(ROOT/'rigid-chair-proof.png',dpi=160,facecolor='#faf8f2')
fig.savefig(ROOT/'rigid-chair-proof.svg',facecolor='#faf8f2')
