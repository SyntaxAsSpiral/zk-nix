# Spotify + Spicetify
{ pkgs, ... }:

{
  home.packages = [ pkgs.spotify ];

  # TODO: spicetify-nix integration
  # https://github.com/Gerg-L/spicetify-nix
}
