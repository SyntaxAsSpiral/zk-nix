# Shared services
{ config, pkgs, ... }:

let
  guiFileHosts = [
    "nxiz"
    "zrrh"
  ];
in
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];
  };

  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;

  security.rtkit.enable = true;

  services = {
    openssh = {
      enable = true;
      extraConfig = "AcceptEnv TERM_PROGRAM";
    };
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    # Shared drive management; fwupd expects udisks2.
    udisks2.enable = true;
    # GUI virtual filesystem stack only on interactive GUI hosts.
    gvfs.enable = builtins.elem config.my.host guiFileHosts;
  };
}
