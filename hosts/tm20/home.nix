# tm20 home: the shell, for remote sessions. No desktop.
_:
{
  imports = [ ../../shared/home/nushell.nix ];

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
