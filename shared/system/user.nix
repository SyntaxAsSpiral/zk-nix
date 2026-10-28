# The workstation login: the extras on top of core.nix.
{ pkgs, ... }:

{
  users.users.zk = {
    linger = true;
    extraGroups = [
      "audio"
      "video"
      "input"
      "dialout"
      "docker"
    ];
    packages = [ ];
  };

  users.defaultUserShell = pkgs.bash;

  # Keep zsh available for tools/apps that probe it.
  programs.zsh.enable = true;
}
