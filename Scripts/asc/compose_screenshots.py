#!/usr/bin/env python3
"""
SignalDrop App Store screenshots — v5.

Uses Jesse's CLEAN dark-wallpaper capture (jesse3-1.png, 1100x1756).
The menu has uniform dark chrome with no warm bleed-through. Each of the 5
listing screenshots uses the same source menu (which already shows evidence
of every feature) and varies only the headline + accent color.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

W, H = 2880, 1800

MENU_SRC = Path("/tmp/sd-review/jesse3-1.png")
OUT_DIR = Path("/Users/jesse/Developer/dropout/Screenshots/AppStore-2026-05-09/final")
OUT_DIR.mkdir(parents=True, exist_ok=True)

SF_BOLD = "/System/Library/Fonts/SFNS.ttf"
SF_HEAVY = "/System/Library/Fonts/SFCompactDisplay.ttf"

SHOTS = [
    {
        "name": "01-status",
        "h1": "Live status.",
        "h2": "At a glance.",
        "sub": "Current network, signal strength, and connection quality —\nright in your menu bar.",
        "accent": (90, 200, 255),       # cyan
        "glow":   (40, 100, 180),
        "tag":    "Always on · Always tracking",
    },
    {
        "name": "02-isp-receipt",
        "h1": "The receipt.",
        "h2": "Your ISP can't dispute.",
        "sub": "One click copies a paste-ready summary of your downtime —\nfor support chats that go somewhere.",
        "accent": (255, 160, 70),       # orange
        "glow":   (180, 90, 30),
        "tag":    "Copy Receipt for Support",
    },
    {
        "name": "03-weak-signal",
        "h1": "Weak signal?",
        "h2": "Caught early.",
        "sub": "Get a heads-up before your connection collapses,\nnot after the call freezes.",
        "accent": (255, 210, 80),       # amber
        "glow":   (160, 110, 30),
        "tag":    "Signal · Degradation alerts",
    },
    {
        "name": "04-event-log",
        "h1": "Every drop.",
        "h2": "Logged with cause.",
        "sub": "Disconnects, switches, signal changes — captured to a local\ntimeline. ISP-suspected outages flagged automatically.",
        "accent": (255, 105, 110),      # red
        "glow":   (160, 40, 60),
        "tag":    "Recent events · CSV export",
    },
    {
        "name": "05-reliability",
        "h1": "Per network.",
        "h2": "Tracked locally.",
        "sub": "Uptime and drop counts for every WiFi you connect to —\nstored on your Mac, never uploaded.",
        "accent": (190, 165, 255),      # lavender
        "glow":   (110, 80, 200),
        "tag":    "Network reliability · 100% local",
    },
]


def make_background(w, h, glow):
    base = Image.new("RGB", (w, h), (8, 11, 22))
    px = base.load()
    for y in range(h):
        ty = y / h
        for x in range(0, w, 4):
            tx = x / w
            t = (tx * 0.35 + ty * 0.55)
            r = int(10 + (4 - 10) * t)
            g = int(13 + (6 - 13) * t)
            b = int(24 + (12 - 24) * t)
            for dx in range(4):
                if x + dx < w:
                    px[x + dx, y] = (r, g, b)
    glow_layer = Image.new("RGB", (w, h), (8, 11, 22))
    gd = ImageDraw.Draw(glow_layer)
    cx, cy = int(w * 0.20), int(h * 0.22)
    max_r = int(w * 0.55)
    for r in range(max_r, 0, -40):
        t = r / max_r
        col = tuple(int(c * (1 - t) * 0.55 + 12 * t) for c in glow)
        gd.ellipse([cx - r, cy - r, cx + r, cy + r * 0.8], fill=col)
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=240))
    out = Image.blend(base, glow_layer, 0.45)
    vig = Image.new("L", (w, h), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-w // 4, -h // 4, w + w // 4, h + h // 4], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(radius=300))
    return Image.composite(out, Image.new("RGB", (w, h), (3, 5, 10)), vig)


def add_drop_shadow(img, blur=46, opacity=190):
    pad = blur * 2
    sh = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    layer = Image.new("RGBA", img.size, (0, 0, 0, opacity))
    if img.mode == "RGBA":
        mask = img.split()[3]
    else:
        mask = Image.new("L", img.size, 255)
    sh.paste(layer, (pad, pad), mask)
    return sh.filter(ImageFilter.GaussianBlur(radius=blur)), pad


def best_font(size):
    for path in (SF_HEAVY, SF_BOLD):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def compose_one(shot):
    name = shot["name"]
    out = OUT_DIR / f"{SHOTS.index(shot) + 1:02d}-{name}.png"

    bg = make_background(W, H, shot["glow"])

    # Load Jesse's clean menu shot (1100x1756, contains menubar + dropdown)
    menu = Image.open(MENU_SRC).convert("RGBA")

    # Scale to fit canvas height with breathing room
    target_h = 1700
    scale = target_h / menu.height
    nw = int(menu.width * scale)
    nh = int(menu.height * scale)
    menu_scaled = menu.resize((nw, nh), Image.LANCZOS)

    # Position: right-aligned with margin
    right_margin = 140
    menu_x = W - nw - right_margin
    menu_y = (H - nh) // 2  # vertically centered

    # Drop shadow
    sh, pad = add_drop_shadow(menu_scaled, blur=46, opacity=180)
    bg.paste(sh, (menu_x - pad, menu_y - pad + 18), sh)
    bg.paste(menu_scaled, (menu_x, menu_y), menu_scaled)

    # ----- Left text block -----
    draw = ImageDraw.Draw(bg)
    f_h1 = best_font(196)
    f_h2 = best_font(196)
    f_sub = best_font(48)
    f_tag = best_font(34)

    h1_bbox = draw.textbbox((0, 0), shot["h1"], font=f_h1)
    h1_w, h1_h = h1_bbox[2] - h1_bbox[0], h1_bbox[3] - h1_bbox[1]
    h2_bbox = draw.textbbox((0, 0), shot["h2"], font=f_h2)
    h2_w, h2_h = h2_bbox[2] - h2_bbox[0], h2_bbox[3] - h2_bbox[1]

    # If h2 is too wide for the left zone, shrink h2 to fit
    cap_max_w = menu_x - 80 - 160
    if h2_w > cap_max_w:
        size = 196
        while h2_w > cap_max_w and size > 100:
            size -= 8
            f_h2 = best_font(size)
            h2_bbox = draw.textbbox((0, 0), shot["h2"], font=f_h2)
            h2_w, h2_h = h2_bbox[2] - h2_bbox[0], h2_bbox[3] - h2_bbox[1]

    sub_lines = shot["sub"].split("\n")
    sub_metrics = []
    for ln in sub_lines:
        b = draw.textbbox((0, 0), ln, font=f_sub)
        sub_metrics.append((ln, b[2] - b[0], b[3] - b[1]))

    line_gap_h = 40
    block_gap = 80
    sub_line_gap = 14
    total_text_h = h1_h + line_gap_h + h2_h + block_gap + sum(m[2] + sub_line_gap for m in sub_metrics) - sub_line_gap

    pad_x = 160
    start_y = (H - total_text_h) // 2 - 40

    tag = shot["tag"].upper()
    tag_bbox = draw.textbbox((0, 0), tag, font=f_tag)
    tag_h = tag_bbox[3] - tag_bbox[1]
    tag_y = start_y - tag_h - 30
    tag_color = tuple(min(255, int(c * 0.95)) for c in shot["accent"])
    draw.text((pad_x, tag_y), tag, fill=tag_color + (255,), font=f_tag)

    draw.text((pad_x, start_y), shot["h1"], fill=(245, 247, 252, 255), font=f_h1)
    h2_y = start_y + h1_h + line_gap_h
    draw.text((pad_x, h2_y), shot["h2"], fill=shot["accent"] + (255,), font=f_h2)

    sy = h2_y + h2_h + block_gap
    for ln, lw, lh in sub_metrics:
        draw.text((pad_x, sy), ln, fill=(195, 200, 215, 235), font=f_sub)
        sy += lh + sub_line_gap

    # Brand mark bottom-left
    f_brand = best_font(32)
    brand_y = H - 90
    draw.ellipse([pad_x, brand_y, pad_x + 22, brand_y + 22], fill=shot["accent"] + (255,))
    draw.text((pad_x + 36, brand_y - 8), "SignalDrop", fill=(220, 222, 235, 230), font=f_brand)

    bg.convert("RGB").save(out, "PNG", optimize=True)
    return out


# Clean old v4 outputs first
for f in OUT_DIR.glob("*.png"):
    f.unlink()

for shot in SHOTS:
    out = compose_one(shot)
    print(f"Composed {shot['name']:18} → {out.name}")
print(f"\nDone. {len(SHOTS)} screenshots in {OUT_DIR}")
