"""Generates the PulseRoute launcher icons with the standard library only.

Outputs (1024x1024) in assets/icon/:
  icon.png             full icon: coral gradient + white "pulse route" line
  icon_background.png  adaptive icon background (gradient)
  icon_foreground.png  adaptive icon foreground (line, transparent)
Run: python tool/generate_icon.py
"""
import math
import struct
import zlib

SIZE = 1024
START = (0xFF, 0x5A, 0x36)  # coral (brand seed)
END = (0xE0, 0x2F, 0x6B)  # raspberry
# A heartbeat that doubles as a route, ending in a location dot.
PULSE = [(0.14, 0.56), (0.34, 0.56), (0.43, 0.33), (0.54, 0.74),
         (0.63, 0.47), (0.78, 0.47)]
DOT = (0.84, 0.47)


def write_png(path, rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)

    def chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def gradient(x, y):
    t = (x + y) / (2 * SIZE)
    return tuple(round(a + (b - a) * t) for a, b in zip(START, END))


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def coverage(x, y, scale):
    c = SIZE / 2
    tr = lambda p: (c + (p[0] * SIZE - c) * scale, c + (p[1] * SIZE - c) * scale)
    pts = [tr(p) for p in PULSE]
    px, py = x + .5, y + .5
    d = min(seg_dist(px, py, *pts[i], *pts[i + 1]) for i in range(len(pts) - 1))
    line = max(0.0, min(1.0, 0.035 * SIZE * scale - d + 0.5))
    dx, dy = tr(DOT)
    dot = max(0.0, min(1.0, 0.055 * SIZE * scale - math.hypot(px - dx, py - dy) + 0.5))
    return max(line, dot)


def render(background, scale):
    rows = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            r, g, b = gradient(x, y) if background else (255, 255, 255)
            a = 255 if background else 0
            if scale:
                cov = coverage(x, y, scale)
                if cov > 0:
                    if background:
                        r, g, b = (round(v + (255 - v) * cov) for v in (r, g, b))
                    else:
                        a = round(255 * cov)
            row += [r, g, b, a]
        rows.append(row)
    return rows


write_png("assets/icon/icon.png", render(True, 1.0))
write_png("assets/icon/icon_background.png", render(True, 0))
# Adaptive icons crop to the inner ~66%, so the drawing is smaller.
write_png("assets/icon/icon_foreground.png", render(False, 0.64))
print("Icons written to assets/icon/")
