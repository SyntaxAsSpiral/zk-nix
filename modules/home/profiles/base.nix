# Baseline home environment — imported by adeck, nxiz, and zrrh. seed slims it
# down in hosts/seed/home.nix; tm20 has no Home-Manager.
{
  imports = [
    ../daemon-profile.nix
    ../nushell.nix
    ../xdg.nix

    # CLI tools
    ../cli/bat.nix
    ../cli/btop.nix
    ../cli/eza.nix
    ../cli/fastfetch/default.nix
    ../cli/fun.nix
    ../cli/fzf.nix
    ../cli/gh.nix
    ../cli/git.nix
    ../cli/lazygit.nix
    ../cli/yazi/default.nix
    ../cli/zcli.nix

    # Editors
    ../editors/nano.nix
    ../editors/zed.nix
  ];

  home.username = "zk";
  home.homeDirectory = "/home/zk";

  programs.home-manager.enable = true;
}
