# Fonts

## Nixpkgs Fonts (installed via flake)

These are available in nixpkgs and installed via `fonts.nix` module:

### Nerd Fonts
- JetBrainsMono Nerd Font
- Iosevka Nerd Font  
- FiraCode Nerd Font
- VictorMono Nerd Font
- UbuntuMono Nerd Font

### Code Fonts
- Recursive (ZK's favorite - variable font with Casual/Linear)
- Cascadia Code
- IBM Plex Mono
- Source Code Pro
- Hack

### Display/Serif
- Cinzel (decorative capitals)
- EB Garamond
- Cormorant Garamond
- Libre Baskerville

### Unicode/Symbols
- Noto Color Emoji
- Font Awesome
- Material Design Icons

## Esoteric Fonts (manual)

These are rare/hard-to-find fonts that must be manually copied:

| Font | Type | Notes |
|------|------|-------|
| Maya | OTF | Mayan glyphs - very hard to find |
| Aurebesh | OTF | Star Wars alphabet |
| Quenya | TTF | Tolkien Elvish (Tengwar) |
| Modern Runic | TTF | Elder Futhark runes |
| Symbola | OTF | Extensive Unicode symbols |

### Deploy on Linux

```bash
mkdir -p ~/.local/share/fonts/esoteric
cp -r /path/to/dotfiles/fonts/esoteric/* ~/.local/share/fonts/esoteric/
fc-cache -fv
```

On NixOS, home-manager handles this via `home.file` or `fonts.fontconfig.enable`.
