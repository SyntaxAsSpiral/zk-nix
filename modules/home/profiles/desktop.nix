# Desktop home profile — nxiz + zrrh (GUI hosts).
# adeck theming is intentionally unset; themed imperatively per-host
# on a catppuccin base (operator's choice — no stylix, keep it organic).
{
  imports = [
    ../catppuccin.nix
    ../browser/firefox.nix
    ../gtk.nix
    ../icons.nix
    ../spotify.nix
    ../thunar.nix
    ../cli/fzf-emoji.nix
  ];
}
