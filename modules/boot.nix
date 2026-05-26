# Bootloader and kernel configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  perHost = {
    nxiz = {
      canTouchEfiVariables = true;
      plymouth = true;
      plymouthTheme = "fade-in";
      plymouthThemePackages = [ pkgs.catppuccin-plymouth ];
      plymouthLogo = ../assets/lotus-plymouth.png;
      blacklistNouveau = true;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "mem_sleep_default=deep" # Force S3 deep sleep for reliable NVIDIA suspend
      ];
    };
    adeck = {
      canTouchEfiVariables = false;
      plymouth = true;
      plymouthTheme = "fade-in";
      plymouthThemePackages = [ ];
      plymouthLogo = ../assets/yantra-adeck.png;
      blacklistNouveau = false;
      kernelParams = [
        "quiet"
        "splash"
      ];
    };
    zrrh = {
      canTouchEfiVariables = true;
      plymouth = true;
      plymouthTheme = "fade-in";
      plymouthThemePackages = [ pkgs.catppuccin-plymouth ];
      plymouthLogo = ../assets/yantra-zrrh.png;
      blacklistNouveau = true;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
  h = perHost.${config.my.host};
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = h.canTouchEfiVariables;
  boot.consoleLogLevel = 3;
  boot.kernelPackages =
    if config.my.host == "adeck" then
      pkgs.linuxPackages_latest
    else
      pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  boot.kernelParams = h.kernelParams;
  boot.blacklistedKernelModules = lib.optionals h.blacklistNouveau [ "nouveau" ];
  boot.plymouth = lib.mkIf h.plymouth {
    enable = true;
    theme = h.plymouthTheme;
    logo = h.plymouthLogo;
    themePackages = h.plymouthThemePackages;
  };
}
