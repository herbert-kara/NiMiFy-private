#!/usr/bin/env python3
"""Generate NimHiddify icon set: green circle + Iran flag stripes (SVG + PNG + ICO)."""
import math
import os
from PIL import Image, ImageDraw

GREEN = (76, 175, 80)
WHITE = (255, 255, 255)
IR_GREEN = (23, 153, 76)
IR_RED = (219, 39, 45)


def svg_logo(circle_color="#4CAF50", ring=None):
    """Green circle + white disc + Iran flag stripes + emblem dot."""
    return f'''<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="32" cy="32" r="32" fill="{circle_color}"/>
<circle cx="32" cy="32" r="27" fill="#FFFFFF"/>
<rect x="14" y="19" width="36" height="8.6" fill="#17994C"/>
<rect x="14" y="27.6" width="36" height="8.8" fill="#FFFFFF"/>
<rect x="14" y="36.4" width="36" height="8.6" fill="#DB272D"/>
<circle cx="32" cy="32" r="2.6" fill="none" stroke="#DB272D" stroke-width="1.1"/>
<circle cx="32" cy="28.7" r="0.9" fill="#DB272D"/>
<circle cx="32" cy="35.3" r="0.9" fill="#DB272D"/>
<circle cx="28.7" cy="32" r="0.9" fill="#DB272D"/>
<circle cx="35.3" cy="32" r="0.9" fill="#DB272D"/>
</svg>'''


def draw_logo(size=1024, circle_color=GREEN, emblem=True):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, size - 1, size - 1], fill=circle_color + (255,))
    m = size * 0.155
    d.ellipse([m, m, size - 1 - m, size - 1 - m], fill=WHITE + (255,))
    fx0, fx1 = size * 0.22, size * 0.78
    fy0, fy1 = size * 0.30, size * 0.70
    fh = fy1 - fy0
    d.rectangle([fx0, fy0, fx1, fy0 + fh / 3], fill=IR_GREEN + (255,))
    d.rectangle([fx0, fy0 + fh / 3, fx1, fy0 + 2 * fh / 3], fill=WHITE + (255,))
    d.rectangle([fx0, fy0 + 2 * fh / 3, fx1, fy1], fill=IR_RED + (255,))
    if emblem:
        cx, cy = (fx0 + fx1) / 2, (fy0 + fy1) / 2
        r = fh * 0.13
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=IR_RED + (255,), width=max(2, int(size * 0.008)))
        for ang in (90, 270, 0, 180):
            px = cx + r * 0.95 * math.cos(math.radians(ang))
            py = cy + r * 0.95 * math.sin(math.radians(ang))
            pr = r * 0.38
            d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=IR_RED + (255,))
    return img


def save_ico(img, path, sizes=(256, 128, 64, 48, 32, 16)):
    img.save(path, format='ICO', sizes=[(s, s) for s in sizes])


tmp = os.environ.get('LOCALAPPDATA') + r'\Temp'
base = draw_logo(1024)
base.save(os.path.join(tmp, 'nim_logo_base.png'))
draw_logo(1024, (46, 160, 67)).save(os.path.join(tmp, 'nim_logo_conn.png'))
draw_logo(1024, (130, 134, 140)).save(os.path.join(tmp, 'nim_logo_disc.png'))
draw_logo(1024, (28, 32, 38)).save(os.path.join(tmp, 'nim_logo_dark.png'))

# splash icon (transparent bg, just the green circle+flag)
splash = draw_logo(1024)
splash.save(os.path.join(tmp, 'nim_splash.png'))

# ICOs
save_ico(base, os.path.join(tmp, 'nim_logo.ico'))
save_ico(draw_logo(1024, (46, 160, 67)), os.path.join(tmp, 'nim_conn.ico'))
save_ico(draw_logo(1024, (130, 134, 140)), os.path.join(tmp, 'nim_disc.ico'))
save_ico(draw_logo(1024, (28, 32, 38)), os.path.join(tmp, 'nim_dark.ico'))

# app icon (windows runner)
save_ico(base, os.path.join(tmp, 'nim_app.ico'))

with open(os.path.join(tmp, 'nim_logo.svg'), 'w', encoding='utf-8') as f:
    f.write(svg_logo())

print("all icons generated in", tmp)
