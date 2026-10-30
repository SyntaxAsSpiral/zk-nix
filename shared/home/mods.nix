# mods writes ~/.config/mods/mods.yml when it is absent, so the file is declared on every host.
{ pkgs, ... }:
{
  home.packages = [ pkgs.mods ];
  xdg.configFile."mods/mods.yml".source = ./mods.yml;
}
