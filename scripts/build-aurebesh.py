#!/usr/bin/env python3
"""Build AurebeshPUA.otf, the private-use font the aurebesh script draws from.

usage: build-aurebesh.py AUREBESH.otf OUTDIR

AurebeshPUA.otf  Aurebesh glyphs also at U+F5000 + ASCII (aurebesh)

The source is the Aurebesh.otf of Neale Davidson's zip at pixelsagas.com, which carries an OFL 1.1 file.
It sits in plane 15 so Nerd Font icons, which own U+E000 and U+EA00, cannot
shadow them. Needs fontTools: 
    nix shell --impure --expr 'with (builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem}; python3.withPackages (p: [ p.fonttools ])' -c python3 ...
"""
import sys, os
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._c_m_a_p import CmapSubtable


def build(src, out, mapping, family):
    f = TTFont(src)
    base = f.getBestCmap()
    if not any(t.isUnicode() and t.format == 12 for t in f["cmap"].tables):
        n = CmapSubtable.newSubtable(12)
        n.platformID, n.platEncID, n.language, n.cmap = 3, 10, 0, {}
        f["cmap"].tables.append(n)
    for t in f["cmap"].tables:
        if t.isUnicode() and t.format in (4, 12):
            for new, old in mapping.items():
                if old in base and (t.format == 12 or new < 0x10000):
                    t.cmap[new] = base[old]
    for r in f["name"].names:
        if r.nameID in (1, 4, 16):
            r.string = family
        elif r.nameID == 6:
            r.string = family.replace(" ", "") + "-Regular"
        elif r.nameID == 3:
            r.string = family.replace(" ", "")
    # the author's licence file (OFL 1.1) travels with the font: say so in the name table, keep his copyright (id 0)
    names = f["name"]
    names.setName("This Font Software is licensed under the SIL Open Font License, Version 1.1.", 13, 3, 1, 0x409)
    names.setName("https://openfontlicense.org", 14, 3, 1, 0x409)
    f.save(out)


if __name__ == "__main__":
    aure, out = sys.argv[1:3]
    os.makedirs(out, exist_ok=True)
    build(aure, f"{out}/AurebeshPUA.otf", {0xF5000 + o: o for o in range(0x21, 0x7F)}, "Aurebesh PUA")
