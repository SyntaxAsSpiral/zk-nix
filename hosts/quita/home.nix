# Quita home: laptop terminal. Nushell and the shared CLI set, Zed, Firefox, Thunar, GTK.
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nixarchy.homeManagerModules.nixarchy

    ../../shared/home/daemon-profile.nix
    ../../shared/home/nushell.nix
    ../../shared/home/gh.nix
    ../../shared/home/zcli.nix
    ../../shared/home/editors/nano.nix
    ../../shared/home/yazi/default.nix
    ../../shared/home/editors/zed.nix

    ../../shared/home/browser/firefox.nix
    ../../shared/home/gtk.nix
    ../../shared/home/icons.nix
    ../../shared/home/thunar.nix
  ];

  programs = {
    home-manager.enable = true;
    nixarchy.enable = true;

    kitty = {
      enable = true;
      font = {
        name = "RecMonoCasual Nerd Font Mono";
        size = 11;
      };
      settings.shell = "${pkgs.nushell}/bin/nu";
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableNushellIntegration = true;
    };
  };

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "25.11";

    packages = with pkgs; [
      cargo
      gcc
      gnumake
      go
      rustc

      nixd
      nil
      nixfmt
    ];
  };
}
