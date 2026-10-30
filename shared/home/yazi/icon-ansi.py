"""Print yazi's preset [icon] table with each hex colour swapped for an ANSI name.

Same hex, same name, so icons that share a colour still share one. Hue picks the
name; low saturation picks white, gray or darkgray.
"""
import colorsys
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
icon = text[text.index("[icon]"):]


def ansi(m):
    r, g, b = (int(m.group(1)[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    if s < 0.15:
        return '"white"' if v > 0.85 else '"gray"' if v > 0.5 else '"darkgray"'
    deg = h * 360
    for upper, name in (
        (15, "red"), (45, "lightred"), (70, "yellow"), (165, "green"),
        (205, "cyan"), (260, "blue"), (340, "magenta"), (361, "red"),
    ):
        if deg < upper:
            return f'"{name}"'


print(re.sub(r'"#([0-9a-fA-F]{6})"', ansi, icon), end="")
