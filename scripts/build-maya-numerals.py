#!/usr/bin/env python3
"""Add the Mayan numerals 0-19 (U+1D2E0..U+1D2F3) to Maya.otf, drawn from Noto Sans Mayan Numerals, at the size of the font's own signs.

usage: build-maya-numerals.py MAYA.otf NOTO_MAYAN_NUMERALS.otf OUT.otf

Noto's numerals are small and flat, so a terminal that falls back to them draws them tiny. Here each is scaled to fill
one cell: widest at WIDTH, the tallest (19) at HEIGHT (a little taller than Noto draws them), centred in the advance of the font's signs. Noto is SIL OFL 1.1.
Needs fontTools: nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (p: [p.fonttools])' -c python3 ...
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.boundsPen import BoundsPen

ADVANCE, WIDTH, HEIGHT, FLOOR = 1176, 1150, 1170, 0  # font units (2048 per em); HEIGHT is the height of the font's own signs
NUMERALS = range(0x1D2E0, 0x1D2F4)

maya, noto = TTFont(sys.argv[1]), TTFont(sys.argv[2])
ncm, gs = noto.getBestCmap(), noto.getGlyphSet()
boxes = {}
for cp in NUMERALS:
    bp = BoundsPen(gs)
    gs[ncm[cp]].draw(bp)
    boxes[cp] = bp.bounds
sx = WIDTH / max(b[2] - b[0] for b in boxes.values())
sy = HEIGHT / max(b[3] - b[1] for b in boxes.values())
order = maya.getGlyphOrder()
cmap = [t for t in maya["cmap"].tables if t.isUnicode() and t.format == 12]
assert cmap, "Maya.otf has no format 12 cmap"
for cp in NUMERALS:
    x0, y0, x1, _ = boxes[cp]
    pen = TTGlyphPen(None)
    gs[ncm[cp]].draw(TransformPen(Cu2QuPen(pen, 1.0, reverse_direction=True), (sx, 0, 0, sy, (ADVANCE - (x1 + x0) * sx) / 2, FLOOR - y0 * sy)))
    name = f"u{cp:X}"
    assert name not in order, name
    order.append(name)
    maya["glyf"].glyphs[name] = pen.glyph()
    maya["hmtx"].metrics[name] = (ADVANCE, 0)
    for t in cmap:
        t.cmap[cp] = name
maya.setGlyphOrder(order)
maya["glyf"].glyphOrder = order
maya.save(sys.argv[3])
print(f"{len(NUMERALS)} numerals added; sx {sx:.3f} sy {sy:.3f}; {len(order)} glyphs")
