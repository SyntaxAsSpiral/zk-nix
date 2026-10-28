# OpenRGB — Arctic Liquid Freezer III 360 A-RGB (zrrh only)
# 48 LEDs: pump head (12) + 3x fans (12 each)
# Single ARGB daisy chain → ADD_GEN2_1 (header 11)
# Controlled via ASUS AURA USB controller (0b05:19af)
# The GUI owns ~/.config/OpenRGB. The files under ./config are the snapshot
# the home activation copies out of /etc/nixos on the first switch.
{ pkgs, ... }:

let
  openrgb = pkgs.openrgb-with-all-plugins;
in
{
  environment.systemPackages = [ openrgb ];
  services.udev.packages = [ openrgb ];
  boot.kernelModules = [ "i2c-dev" ];
}
