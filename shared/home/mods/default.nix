# mods writes ~/.config/mods/mods.yml when it is absent, so the file is declared on every host.
# mods renders markdown through glamour, which reads its style from GLAMOUR_STYLE; the
# theme key in mods.yml only styles mods' forms. The wrapper points it at the ANSI style.
{ pkgs, ... }:
let
  mods = pkgs.symlinkJoin {
    name = "mods";
    paths = [ pkgs.mods ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mods --set-default GLAMOUR_STYLE ${../glow-styles/ansi-custom.json}
    '';
  };
in
{
  home.packages = [ mods ];
  # force: a stale mods.yml left by an older setup would otherwise stop home-manager from activating.
  xdg.configFile."mods/mods.yml" = {
    source = ./mods.yml;
    force = true;
  };
}
