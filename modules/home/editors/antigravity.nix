{ pkgs, ... }:
{
  # Google Antigravity IDE helper, exposed via antigravity-nix overlay as pkgs.google-antigravity
  home.packages = with pkgs; [
    google-antigravity
  ];
  xdg.configFile."Antigravity/User/settings.json".source = ./vscode/User/settings.json;
}
