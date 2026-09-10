#!/usr/bin/env python3
"""NiMiFy icon set from user's provided image (blue subject on white bg).

- Crops subject bbox, makes white -> transparent
- App icon: soft light circle + subject centered
- Tray variants: status dot badge (green/gray) bottom-right
- ICOs (256..16), PNGs, mipmaps, splash
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw

SRC = r'C:\Users\nima\AppData\Roaming\Hermes\composer-images\file_00000000ba0c82438cc5e4d8c3779472_cddbea.png'
TMP = os.environ.get('LOCALAPPDATA') + r'\Temp'
SIZE = 1024

img = Image.open(SRC).convert('RGB')
a = np.array(img)

# --- 1) subject bbox (non-white) ---
mask = ~((a[:, :, 0] > 235) & (a[:, :, 1] > 235) & (a[:, :, 2] > 235))
ys, xs = np.where(mask)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()

# --- 2) crop with padding, white->transparent ---
pad = int(0.06 * max(x1 - x0, y1 - y0))
cx0, cy0 = max(0, x0 - pad), max(0, y0 - pad)
cx1, cy1 = min(img.width, x1 + pad), min(img.height, y1 + pad)
subj = img.crop((cx0, cy0, cx1, cy1))

s = np.array(subj.convert('RGBA')).astype(np.int16)
# luminance-based alpha: white -> 0, colored -> 255 (smooth)
lum = (s[:, :, 0] * 0.299 + s[:, :, 1] * 0.587 + s[:, :, 2] * 0.114)
sat = s[:, :, :3].max(axis=2).astype(np.int16) - s[:, :, :3].min(axis=2).astype(np.int16)  # colorfulness
alpha = np.clip((255 - lum) * 1.4 + sat * 2.2, 0, 255).astype(np.uint8)
s[:, :, 3] = alpha
subj_t = Image.fromarray(s.astype(np.uint8), 'RGBA')

# square canvas, fit subject
canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
w, h = subj_t.size
sc = min(SIZE * 0.82 / w, SIZE * 0.82 / h)
nw, nh = int(w * sc), int(h * sc)
subj_big = subj_t.resize((nw, nh), Image.LANCZOS)
canvas.paste(subj_big, ((SIZE - nw) // 2, (SIZE - nh) // 2), subj_big)
canvas.save(os.path.join(TMP, 'nm_subject.png'))


def app_icon(size=1024, bg=(255, 255, 255), ring=None):
    """Rounded-square app icon: soft circle bg + subject."""
    ic = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(ic)
    # rounded rect (squircle-ish) background — white for maximum subject contrast
    r = size * 0.23
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=bg + (255,))
    if ring:
        d.rounded_rectangle(
            [int(size*0.02), int(size*0.02), size-1-int(size*0.02), size-1-int(size*0.02)],
            radius=r*0.96, outline=ring + (255,), width=max(2, int(size*0.03)))
    subj_r = canvas.resize((int(size * 0.78), int(size * 0.78)), Image.LANCZOS)
    off = (size - subj_r.width) // 2
    ic.paste(subj_r, (off, off), subj_r)
    return ic


def tray_icon(size=1024, dot=None, dark_ring=None):
    """Circular tray icon: subject on soft circle + status dot badge."""
    ic = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(ic)
    d.ellipse([0, 0, size - 1, size - 1], fill=(255, 255, 255, 245))
    if dark_ring:
        d.ellipse([int(size*0.015)]*2 + [size-1-int(size*0.015)]*2, outline=dark_ring + (255,), width=max(2, int(size*0.02)))
    subj_r = canvas.resize((int(size * 0.80), int(size * 0.80)), Image.LANCZOS)
    off = (size - subj_r.width) // 2
    ic.paste(subj_r, (off, off), subj_r)
    if dot:
        r = size * 0.13
        cx, cy = size - int(r * 1.35), size - int(r * 1.35)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=dot + (255,), outline=(255, 255, 255, 255), width=max(2, int(size*0.02)))
    return ic


def save_ico(im, path, sizes=(256, 128, 64, 48, 32, 16)):
    im.save(path, format='ICO', sizes=[(s, s) for s in sizes])


GREEN = (46, 160, 67)
GRAY = (140, 144, 150)
RED = (200, 60, 60)

app_icon(1024).save(os.path.join(TMP, 'nm_app.png'))

tray_icon(1024).save(os.path.join(TMP, 'nm_tray.png'))
tray_icon(1024, dot=GREEN).save(os.path.join(TMP, 'nm_tray_conn.png'))
tray_icon(1024, dot=GRAY).save(os.path.join(TMP, 'nm_tray_disc.png'))
tray_icon(1024, dark_ring=(120, 124, 130)).save(os.path.join(TMP, 'nm_tray_dark.png'))

save_ico(app_icon(1024), os.path.join(TMP, 'nm_app.ico'))
save_ico(tray_icon(1024), os.path.join(TMP, 'nm_tray.ico'))
save_ico(tray_icon(1024, dot=GREEN), os.path.join(TMP, 'nm_tray_conn.ico'))
save_ico(tray_icon(1024, dot=GRAY), os.path.join(TMP, 'nm_tray_disc.ico'))
save_ico(tray_icon(1024, dark_ring=(120, 124, 130)), os.path.join(TMP, 'nm_tray_dark.ico'))

# preview grid
pv = Image.new('RGB', (520, 260), (240, 240, 240))
for i, (p, pos) in enumerate([(os.path.join(TMP,'nm_app.png'), (10, 10)),
                              (os.path.join(TMP,'nm_tray.png'), (180, 10)),
                              (os.path.join(TMP,'nm_tray_conn.png'), (350, 10))]):
    im = Image.open(p).resize((160, 160), Image.LANCZOS)
    pv.paste(im, pos, im)
for j, p in enumerate([os.path.join(TMP,'nm_tray_disc.png'), os.path.join(TMP,'nm_tray_dark.png')]):
    im = Image.open(p).resize((160, 160), Image.LANCZOS)
    pv.paste(im, (10 + j * 170, 90), im)
pv.save(os.path.join(TMP, 'nm_preview.jpg'), quality=80)
print('generated all NiMiFy icons in', TMP)
