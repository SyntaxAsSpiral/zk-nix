# Esoteric fonts

The source fonts of the esoteric scripts. `shared/system/esofonts.nix` builds from them and installs the result;
nothing here is installed as it stands except what has no package.

- `Aurebesh*.otf` (Neale Davidson, OFL 1.1): the faces are installed as they are. `Aurebesh.otf` is also the source of
  `AurebeshPUA.otf`, built by `scripts/build-aurebesh.py`.
- `Maya.otf` (Unicode Fonts for Ancient Scripts, George Douros; personal use): the unmodified original. The installed
  `Maya.otf` is this plus the Mayan numerals from Noto Sans Mayan Numerals, added by `scripts/build-maya-numerals.py`.
- `QUEN*.TTF` and `ModernRunic-Regular.ttf`: no package; installed as they are.

`TengwarPUA.ttf` has no source here. It is built from Unifont CSUR (nixpkgs `unifont`) by `scripts/build-tengwar.py`,
reading its letters from `shared/home/esoscript/esoscript.py`. The fonts for everyday use (Syne Mono, Kode Mono,
Miracode, the Google display faces) come from nixpkgs through `shared/system/fonts.nix`.
