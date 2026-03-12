# Shared services
{ pkgs, ... }:

{
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
}
