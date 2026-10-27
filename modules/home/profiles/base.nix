# Baseline home environment — imported by adeck, nxiz, and zrrh. seed slims it
# down in hosts/seed/home.nix; tm20 has no Home-Manager.
{
  imports = [
    ../daemon-profile.nix
    ../nushell.nix
    ../xdg.nix

    # Shell tools
    ../shell/bat.nix
    ../shell/btop.nix
    ../shell/eza.nix
    ../shell/fastfetch/default.nix
    ../shell/fun.nix
    ../shell/fzf.nix
    ../shell/gh.nix
    ../shell/git.nix
    ../shell/lazygit.nix
    ../shell/yazi/default.nix
    ../shell/zcli.nix

    # Editors
    ../editors/nano.nix
    ../editors/zed.nix

    ../daemonturgy/pi/default.nix
  ];

  home.username = "zk";
  home.homeDirectory = "/home/zk";

  programs.home-manager.enable = true;
}
