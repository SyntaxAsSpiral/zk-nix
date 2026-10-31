# sky: a small snapshot of the sky (planet signs, degrees, retrogrades, moon phase, tightest
# aspects) from sideriod's gnomon on adeck.
{ pkgs, ... }:
let
  sky = pkgs.writeShellApplication {
    name = "sky";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      gawk
      gnused
    ];
    text = builtins.readFile ./sky.sh;
  };
in
{
  home.packages = [ sky ];
}
