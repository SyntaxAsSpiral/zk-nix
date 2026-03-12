# Shared services
{ config, pkgs, ... }:

let
  guiFileHosts = [ "nxiz" "zrrh" ];
in {
  services.openssh = {
    enable = true;
    extraConfig = "AcceptEnv TERM_PROGRAM";
  };
  programs.mosh.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];
  };

  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Drive management for GUI file managers
  services.udisks2.enable = builtins.elem config.my.host guiFileHosts;
  services.gvfs.enable = builtins.elem config.my.host guiFileHosts;
}
