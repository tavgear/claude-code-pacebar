#!/usr/bin/env python3
"""Turn ANSI-coloured terminal output on stdin into a PNG, for the README.

    ./preview.sh | python3 demo/render.py demo/pacebar.png

Only needed to regenerate the images in the README. The font paths below are
Debian's; point them at any monospace TTF your system has.
"""
import re, sys
from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf"
BOLD = "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf"
SIZE, PAD, GAP, BG = 26, 28, 4, (22, 24, 29)  # GAP keeps identical bars in
                                              # neighbouring rows from merging

# xterm system colours 0-15, then the 6×6×6 cube and the grey ramp.
SYS = [(0,0,0),(205,0,0),(0,205,0),(205,205,0),(0,0,238),(205,0,205),(0,205,205),(229,229,229),
       (127,127,127),(255,0,0),(0,255,0),(255,255,0),(92,92,255),(255,0,255),(0,255,255),(255,255,255)]
STEPS = [0, 95, 135, 175, 215, 255]

def xterm(n):
    if n < 16:
        return SYS[n]
    if n < 232:
        n -= 16
        return (STEPS[n // 36], STEPS[n // 6 % 6], STEPS[n % 6])
    v = 8 + (n - 232) * 10
    return (v, v, v)

def cells(line):
    """Split one line into (char, fg, bg, bold) cells."""
    fg, bg, bold, out = SYS[7], None, False, []
    for chunk in re.split(r"(\x1b\[[0-9;]*m)", line):
        if chunk.startswith("\x1b["):
            args = [int(x or 0) for x in chunk[2:-1].split(";")]
            i = 0
            while i < len(args):
                a = args[i]
                if a == 0:
                    fg, bg, bold = SYS[7], None, False
                elif a == 1:
                    bold = True
                elif a in (38, 48) and args[i+1:i+2] == [5]:
                    colour = xterm(args[i+2])
                    fg, bg = (colour, bg) if a == 38 else (fg, colour)
                    i += 2
                elif 30 <= a <= 37:
                    fg = SYS[a - 30]
                elif 90 <= a <= 97:
                    fg = SYS[a - 90 + 8]
                i += 1
        else:
            out += [(ch, fg, bg, bold) for ch in chunk]
    return out

lines = [cells(l.rstrip("\n")) for l in sys.stdin.readlines()]
while lines and not lines[-1]:
    lines.pop()

font, bold_font = ImageFont.truetype(FONT, SIZE), ImageFont.truetype(BOLD, SIZE)
cw = font.getlength("M")
ch = SIZE * 1.7
img = Image.new("RGB", (int(max(len(l) for l in lines) * cw) + PAD * 2,
                        int(len(lines) * ch) + PAD * 2), BG)
draw = ImageDraw.Draw(img)

for row, line in enumerate(lines):
    y = PAD + row * ch
    for col, (char, fg, bg, bold) in enumerate(line):
        x = PAD + col * cw
        if bg:
            draw.rectangle([x, y + GAP, x + cw + 1, y + ch - GAP], fill=bg)
        if char != " ":
            draw.text((x, y + ch * 0.22), char, font=bold_font if bold else font, fill=fg)

img.save(sys.argv[1])
print(f"{sys.argv[1]}: {img.width}×{img.height}")
