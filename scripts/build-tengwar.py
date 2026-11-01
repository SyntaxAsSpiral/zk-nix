#!/usr/bin/env python3
"""Build TengwarPUA.ttf, the font the quenya and tengwar scripts draw from.

usage: build-tengwar.py UNIFONT_CSUR.otf OUTDIR ESOSCRIPT.py

From GNU Unifont's Unifont CSUR (SIL OFL 1.1) it keeps the Tengwar letters, moved to U+F5100 + (cp - U+E000), clear
of the private-use codepoints Nerd Fonts take for icons, and the Klingon glyphs where they are. It adds one
precomposed glyph per letter and vowel at U+F5200 + 5 * (the letter's place in TENGWAR_LETTERS) + (the vowel's
place in aeiou): the vowel mark has no width, which a terminal still gives a cell, so each syllable is one glyph.
TENGWAR_LETTERS is read from esoscript.py (shared/home/esoscript), the source of truth for the tables.

Needs fontTools: 
    nix shell --impure --expr 'with (builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem}; python3.withPackages (p: [ p.fonttools ])' -c python3 build-tengwar.py ...
"""
import importlib.util
import os
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

VOWEL_MARKS = {"a": 0xE040, "e": 0xE046, "i": 0xE044, "o": 0xE04A, "u": 0xE04C}


def letters_from(path):
    spec = importlib.util.spec_from_file_location("esoscript", path)
    eso = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(eso)
    return eso.TENGWAR_LETTERS


def build(src_path, out_dir, esoscript):
    letters = letters_from(esoscript)
    src = TTFont(src_path)
    cmap = src.getBestCmap()
    gs = src.getGlyphSet()
    glyphs, metrics, order, uni = {}, {}, [".notdef"], {}

    def add(name, parts, advance, codepoint=None):
        pen = TTGlyphPen(None)
        # TrueType wants the opposite winding to CFF
        out = Cu2QuPen(pen, 1.0, reverse_direction=True)
        for cp, dx in parts:
            gs[cmap[cp]].draw(TransformPen(out, (1, 0, 0, 1, dx, 0)))
        g = pen.glyph()
        g.recalcBounds(None)
        glyphs[name] = g
        metrics[name] = (advance, getattr(g, "xMin", 0) if g.numberOfContours else 0)
        if name not in order:
            order.append(name)
        if codepoint is not None:
            uni[codepoint] = name

    add(".notdef", [], 32)
    # the plain Tengwar block and the Cirth after it (U+E080..), moved out of the way of Nerd Font icons
    for cp in range(0xE000, 0xE100):
        if cp in cmap:
            add(f"tengwar_{cp:04X}", [(cp, 0)], src["hmtx"][cmap[cp]][0], 0xF5100 + cp - 0xE000)
    # one glyph per letter and vowel: the mark, which has negative x, is drawn at the letter's advance
    for li, letter in enumerate(letters):
        adv = src["hmtx"][cmap[letter]][0]
        for vi, vowel in enumerate("aeiou"):
            add(f"syl_{letter:04X}_{vowel}", [(letter, 0), (VOWEL_MARKS[vowel], adv)], adv, 0xF5200 + li * 5 + vi)
    # pIqaD, where it already is
    for cp in list(range(0xF8D0, 0xF8EA)) + list(range(0xF8F0, 0xF8FA)):
        if cp in cmap:
            add(f"klingon_{cp:04X}", [(cp, 0)], src["hmtx"][cmap[cp]][0], cp)

    fb = FontBuilder(64, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(uni)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=56, descent=-8)
    names = src["name"]

    def nm(i):
        r = names.getName(i, 3, 1, 0x409)
        return str(r) if r else ""

    fb.setupNameTable(
        {
            "familyName": "Tengwar PUA",
            "styleName": "Regular",
            # name IDs 4 and 6: without them a strict parser (fontdb in asciinema's agg) drops the font as having no family
            "fullName": "Tengwar PUA",
            "psName": "TengwarPUA-Regular",
            "copyright": nm(0),
            "licenseDescription": nm(13),
            "licenseInfoURL": nm(14) or "https://scripts.sil.org/OFL",
        }
    )
    fb.setupOS2(sTypoAscender=56, sTypoDescender=-8, sTypoLineGap=0, usWinAscent=56, usWinDescent=8)
    fb.setupPost(isFixedPitch=1)
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "TengwarPUA.ttf")
    fb.save(out)
    print(f"{out}: {len(order)} glyphs, {len(letters) * 5} syllables")


if __name__ == "__main__":
    build(*sys.argv[1:4])
