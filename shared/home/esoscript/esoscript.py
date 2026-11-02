#!/usr/bin/env python3
"""esoscript: write text in an esoteric script, one character for one letter.

usage: esoscript [-s SCRIPT] [text...]   text from the arguments, else a filter over stdin (ANSI colours kept)
       esoscript --all [text...]         the text in every script, one per line
       esoscript --list                  the scripts, each with the font that draws it

This file is the source of truth for every table here. The greek-to-me mod for Claude Code
(SyntaxAsSpiral/greek-to-me) is written from it by its scripts/sync-tables.py; edit the tables here,
never there. Aurebesh, Maya and Tengwar live in the private use
plane and need the fonts shared/system/esofonts.nix builds from assets/esofonts (AurebeshPUA.otf,
Maya.otf, TengwarPUA.ttf) and installs on a NixOS host. A remote terminal needs them on the
machine that draws it.
"""
import re
import sys

LATIN = "abcdefghijklmnopqrstuvwxyz"

# a b c d e f g h i j k l m n o p q r s t u v w x y z
ALPHABETS = {
    "greek": ("αβκδεφγηιξκλμνοπθρστυϝωχψζ", "ΑΒΚΔΕΦΓΗΙΞΚΛΜΝΟΠΘΡΣΤΥϜΩΧΨΖ"),
    "runic": ("ᚨᛒᚲᛞᛖᚠᚷᚺᛁᛃᚲᛚᛗᚾᛟᛈᚲᚱᛊᛏᚢᚢᚹᛉᛃᛉ", None),
    "braille": ("⠁⠃⠉⠙⠑⠋⠛⠓⠊⠚⠅⠇⠍⠝⠕⠏⠟⠗⠎⠞⠥⠧⠺⠭⠽⠵", None),
    "hebrew": ("אבכדעפגהישקלמנופקרסתטווצחז", None),
    "katakana": ("ｱﾊｾﾄｴﾌｹﾍｲｼｶﾘﾏﾅｵﾎｸﾗｻﾀｳﾋﾜｽﾔｿ", None),
    "malayalam": ("അബചദഎഫഗഹഇജകലമനഒപഖരസതഉവഴഷയശ", None),
    "arabic": ("ابثدعفغهيجكلمنوضقرستظزصحطذ", None),
    "grimdark": ("☠ᛒ🜂ᛞ⚙ᚠ🜃ᚺ✠🜄ᚲᛚᛗᚾ☥ᛈ🜔ᚱᛊᛏ⚜🜍ᚹ⚔⛧🜏", None),
    "hiero": ("𓄿𓃀𓎡𓂧𓇋𓆑𓎼𓉔𓇋𓆓𓎡𓃭𓅓𓈖𓂝𓊪𓈎𓂋𓋴𓏏𓅱𓆑𓅱𓐍𓇌𓊃", None),
}
KLINGON = [0xf8d0, 0xf8d1, 0xf8d2, 0xf8d3, 0xf8d4, 0xf8de, 0xf8d5, 0xf8d6, 0xf8d7, 0xf8d8, 0xf8df, 0xf8d9, 0xf8da, 0xf8db, 0xf8dd, 0xf8de, 0xf8e0, 0xf8e1, 0xf8e2, 0xf8e3, 0xf8e5, 0xf8e6, 0xf8e7, 0xf8d2, 0xf8e8, 0xf8e2]
KLINGON_DIGITS = [0xf8f0, 0xf8f1, 0xf8f2, 0xf8f3, 0xf8f4, 0xf8f5, 0xf8f6, 0xf8f7, 0xf8f8, 0xf8f9]


# Unicode blocks, and Cirth, written as codepoints: Ogham (U+1680, feathers, so j is c and x is z), Gothic (Wulfila's, U+10330:
# c is k, v is w, y is j) and Shavian (U+10450, an English alphabet of sounds, so each letter is the nearest sound).
OGHAM = [0x1690, 0x1681, 0x1689, 0x1687, 0x1693, 0x1683, 0x168C, 0x1686, 0x1694, 0x1689, 0x1689, 0x1682, 0x168B,
         0x1685, 0x1691, 0x168A, 0x168A, 0x168F, 0x1684, 0x1688, 0x1692, 0x1683, 0x1692, 0x168E, 0x1694, 0x168E]
GOTHIC = [0x10330, 0x10331, 0x1033A, 0x10333, 0x10334, 0x10346, 0x10332, 0x10337, 0x10339, 0x1033E, 0x1033A, 0x1033B,
          0x1033C, 0x1033D, 0x10349, 0x10340, 0x10335, 0x10342, 0x10343, 0x10344, 0x1033F, 0x10345, 0x10345, 0x10347,
          0x1033E, 0x10336]
SHAVIAN = [0x10468, 0x1045A, 0x10452, 0x1045B, 0x10467, 0x10453, 0x1045C, 0x10463, 0x10466, 0x10461, 0x10452, 0x10464,
           0x10465, 0x1046F, 0x1046A, 0x10450, 0x10452, 0x1046E, 0x10455, 0x10451, 0x10473, 0x1045D, 0x10462, 0x10452,
           0x10458, 0x1045F]
# Cirth (CSUR U+E080..., by the registry's letter names; Angerthas, a letter for a letter: c is k, x and z are z, y is y),
# moved with the Tengwar to U+F5100 + (cp - U+E000), which is U+F5180 up
CIRTH_CSUR = [0xE0B1, 0xE081, 0xE091, 0xE088, 0xE0AF, 0xE082, 0xE092, 0xE0B9, 0xE0A7, 0xE08D, 0xE091, 0xE09E, 0xE085,
              0xE08B, 0xE0B3, 0xE080, 0xE096, 0xE09C, 0xE0A1, 0xE087, 0xE0AA, 0xE083, 0xE0AC, 0xE0A3, 0xE0DF, 0xE0A3]
CIRTH = [cp - 0xE000 + 0xF5100 for cp in CIRTH_CSUR]
BLOCKS = {"ogham": OGHAM, "gothic": GOTHIC, "shavian": SHAVIAN, "cirth": CIRTH}

# Maya.otf: only the 392 main signs that fit one cell, one fixed sign per character.
MAYA_RANGES = "f656f-f6587,f6589-f658e,f6590-f659a,f659c-f65a2,f65a4-f65a6,f65a8-f65af,f65b2-f65c8,f65ca-f65ce,f65d0-f65d7,f65d9-f65e3,f65e6-f65f2,f65f4-f65fb,f65fd-f6600,f6603-f660a,f660c-f661a,f661c-f6620,f6622-f662b,f662d-f662f,f6632-f6636,f6638-f663a,f663c-f6643,f6647,f6649-f664a,f664c-f6651,f6653-f6655,f6657-f6658,f665c,f665f,f6661,f6664-f6671,f6675,f6678-f6679,f667b,f6682-f6683,f6686-f6687,f6689-f668c,f668f-f6690,f6696,f6698,f66a0,f66a4,f66a8,f66aa-f66ab,f66ad-f66ae,f66b5,f66b9-f66ba,f66be,f66c0,f66c4-f66c5,f66c8-f66c9,f66cf,f66d1,f66d3-f66d4,f66d7,f66da-f66db,f66e0,f66e4,f66e7,f66f3-f66f5,f66f8,f66fc,f6706,f670a-f670b,f670d-f670e,f6710,f6713,f6715,f6719-f671a,f671f,f6722,f6728,f672a,f6730-f6733,f6738,f673b,f673f,f6743,f6745-f6748,f674b-f674c,f674e-f6750,f6752,f6757-f6758,f675b-f675c,f6761,f6763,f6767-f6768,f676e-f676f,f6772-f6774,f6778-f6779,f677b-f677c,f677e,f6780,f6788-f6789,f678b,f678d,f6792-f6793,f6795-f6796,f679c,f679e-f679f,f67a3,f67a6,f67ab,f67ae,f67b5-f67b6,f67b9,f67c1,f67c3-f67c4,f67c6-f67c7,f67ca-f67cc,f67d0-f67f0,f67f2-f67f5,f67f9-f67fa,f67fe,f6800-f6801,f6804,f6806,f680a,f680e-f680f,f6816"
MAYA = [c for r in MAYA_RANGES.split(",") for c in range(int(r.split("-")[0], 16), int(r.split("-")[-1], 16) + 1)]

# Tengwar (Unifont CSUR, moved to U+F5100 + (cp - U+E000) so Nerd Font icons do not take it)
Q_CONS = [
    ("qu", 0xE003), ("th", 0xE008), ("ng", 0xE006), ("nd", 0xE004), ("mb", 0xE005), ("ch", 0xE00A), ("hw", 0xE00B),
    ("t", 0xE000), ("p", 0xE001), ("c", 0xE002), ("k", 0xE002), ("q", 0xE003), ("d", 0xE004), ("b", 0xE005),
    ("g", 0xE006), ("f", 0xE009), ("n", 0xE010), ("m", 0xE011), ("v", 0xE015), ("w", 0xE017), ("s", 0xE020),
    ("z", 0xE021), ("h", 0xE024), ("y", 0xE026), ("j", 0xE026), ("r", 0xE030), ("l", 0xE032),
]
TENGWAR_LETTERS = [
    0xE000, 0xE001, 0xE002, 0xE003, 0xE004, 0xE005, 0xE006, 0xE008, 0xE009, 0xE00A, 0xE00B, 0xE010, 0xE011, 0xE015,
    0xE017, 0xE020, 0xE021, 0xE024, 0xE026, 0xE030, 0xE032, 0xE02C,
]
CARRIER = 0xE02C
VOWELS = "aeiou"

# the font that draws each script, for the picker; anything not listed is in ordinary system fonts
# digits 0-9 for scripts that have a numeral set of their own; braille numbers a run with one number sign (below), maya writes each digit (below)
DIGITS = {"arabic": "٠١٢٣٤٥٦٧٨٩", "malayalam": "൦൧൨൩൪൫൬൭൮൯"}
FONTS = {
    "quenya": "Tengwar PUA", "tengwar": "Tengwar PUA", "klingon": "Tengwar PUA", "aurebesh": "Aurebesh PUA",
    "maya": "Maya", "hiero": "Noto Sans Egyptian Hieroglyphs", "grimdark": "Symbola", "ogham": "DejaVu Sans",
    "gothic": "Noto Sans Gothic", "shavian": "Noto Sans Shavian", "cirth": "Tengwar PUA",
}


def table(name):
    if name in BLOCKS:
        return {c: chr(BLOCKS[name][i]) for i, c0 in enumerate(LATIN) for c in (c0, c0.upper())}
    if name == "klingon":
        lo = [chr(c) for c in KLINGON]
        digits = [chr(c) for c in KLINGON_DIGITS]
    else:
        lower, upper = ALPHABETS[name]
        lo = list(lower)
        digits = list(DIGITS.get(name, ""))
    up = list(upper) if name == "greek" and ALPHABETS[name][1] else lo
    m = {}
    for i, c in enumerate(LATIN):
        m[c] = lo[i] if i < len(lo) else c
        m[c.upper()] = up[i] if i < len(up) else m[c]
    for i, d in enumerate(digits):
        m[str(i)] = d
    return m


def mapped(name):
    m = table(name)
    return lambda line: "".join(m.get(c, c) for c in line)


def braille(line):
    """Letters from the table; a run of digits is one number sign, then a-j for 1-9,0."""
    m = table("braille")
    return re.sub(r"\d+", lambda r: "\u283c" + "".join(m["jabcdefghi"[int(d)]] for d in r[0]), "".join(m.get(c, c) for c in line))


def mayan_number(run):
    """A whole number in Mayan numerals: base 20, most significant first, U+1D2E0 is zero."""
    n, digits = int(run), []
    while True:
        n, d = divmod(n, 20)
        digits.append(chr(0x1D2E0 + d))
        if not n:
            return "".join(reversed(digits))


def maya(line):
    letter = lambda c: chr(MAYA[(ord(c.lower()) * 2654435761 & 0xFFFFFFFF) % len(MAYA)]) if c.isascii() and c.isalpha() else c
    return "".join("".join(mayan_number(d) for d in p) if p.isdigit() else "".join(map(letter, p)) for p in re.split(r"(\d+)", line))


def aurebesh(line):
    return "".join(chr(0xF5000 + ord(c)) if c.isascii() and c.isalnum() else c for c in line)


def t(cp):
    return chr(cp - 0xE000 + 0xF5100)


def syllable(letter, vowel):
    return chr(0xF5200 + TENGWAR_LETTERS.index(letter) * 5 + VOWELS.index(vowel))


def _tengwar(line, vowel_on_next):
    """quenya puts a vowel on the NEXT consonant, tengwar on the one BEFORE it; a carrier otherwise."""
    out, s = [], line.lower()
    pending = None  # quenya: a vowel waiting for its consonant
    last = -1  # tengwar: the letter just drawn, while it has no vowel yet

    def flush():
        nonlocal pending
        if pending:
            out.append(syllable(CARRIER, pending))
        pending = None

    def letter(cp):
        nonlocal pending, last
        if vowel_on_next:
            out.append(syllable(cp, pending) if pending else t(cp))
            pending = None
        else:
            out.append(t(cp))
            last = cp

    i = 0
    while i < len(s):
        c = s[i]
        if c in VOWELS:
            if vowel_on_next:
                flush()
                pending = c
            else:
                if last >= 0:
                    out[-1] = syllable(last, c)
                else:
                    out.append(syllable(CARRIER, c))
                last = -1
            i += 1
            continue
        if c == "x":
            letter(0xE002)
            if vowel_on_next:
                out.append(t(0xE020))
            else:
                letter(0xE020)
            i += 1
            continue
        hit = next(((k, cp) for k, cp in Q_CONS if s.startswith(k, i)), None)
        if hit:
            letter(hit[1])
            i += len(hit[0])
            continue
        if vowel_on_next:
            flush()
        else:
            last = -1
        out.append(line[i])
        i += 1
    if vowel_on_next:
        flush()
    return "".join(out)


SCRIPTS = {
    **{n: mapped(n) for n in [*ALPHABETS, "klingon", *BLOCKS]},
    "quenya": lambda line: _tengwar(line, True),
    "tengwar": lambda line: _tengwar(line, False),
    "braille": braille,
    "maya": maya,
    "aurebesh": aurebesh,
}
ORDER = ["greek", "runic", "braille", "klingon", "quenya", "tengwar", "hebrew", "katakana", "malayalam", "arabic",
         "grimdark", "hiero", "cirth", "ogham", "gothic", "shavian", "aurebesh", "maya"]


ANSI = re.compile(r"(\x1b\[[0-9;?]*[ -/]*[@-~])")


def through(tf, text):
    """tf over the text between ANSI colour codes; the codes themselves are kept, so coloured output can be piped."""
    return "".join(part if i % 2 else tf(part) for i, part in enumerate(ANSI.split(text)))


def main(argv):
    args = argv[1:]
    script, mode = "greek", "one"
    while args and args[0].startswith("-"):
        a = args.pop(0)
        if a in ("-s", "--script") and args:
            script = args.pop(0)
        elif a == "--all":
            mode = "all"
        elif a == "--list":
            mode = "list"
        else:
            sys.exit(__doc__)
    if mode == "list":
        for n in ORDER:
            print(f"{n}\t{FONTS.get(n, '')}")
        return
    if script not in SCRIPTS:
        sys.exit(f"esoscript: no script {script!r}; try --list")
    piped = not args and not sys.stdin.isatty()
    text = " ".join(args) if args else (sys.stdin.read() if piped else "")
    if mode == "all":
        text = text.rstrip("\n")
        for n in ORDER:
            print(f"{n:<10} {through(SCRIPTS[n], text)}")
    elif piped:
        sys.stdout.write(through(SCRIPTS[script], text))  # a filter: every newline and blank line kept as it came
    else:
        print(through(SCRIPTS[script], text))

if __name__ == "__main__":
    main(sys.argv)
