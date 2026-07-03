# Desktop home profile — nxiz + zrrh (GUI hosts).
# adeck theming is intentionally unset pending nix-colors/stylix migration.
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
