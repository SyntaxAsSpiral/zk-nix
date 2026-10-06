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
    seed = {
      # Rescue stick: plain console, stock kernel, never touch the host's NVRAM.
      canTouchEfiVariables = false;
      plymouth = false;
      blacklistNouveau = false;
      stockKernel = true;
      kernelParams = [ "boot.shell_on_fail" ];
    };
  };
  h = perHost.${config.my.host};
in
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = h.canTouchEfiVariables;
    };
    consoleLogLevel = 3;
    kernelPackages =
      if config.my.host == "adeck" then
        # Valve vendor kernel: steamdeck EC driver (battery charge limit,
        # fan hwmon) is patched in; stock kernels lack it entirely
        pkgs.linuxPackages_jovian
      else if h.stockKernel or false then
        # Broadest hardware support from cache.nixos.org; no CachyOS overlay needed.
        pkgs.linuxPackages_latest
      else
        pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    inherit (h) kernelParams;
    blacklistedKernelModules = lib.optionals h.blacklistNouveau [ "nouveau" ];
    plymouth = lib.mkIf h.plymouth {
      enable = true;
      theme = h.plymouthTheme;
      logo = h.plymouthLogo;
      themePackages = h.plymouthThemePackages;
    };
  };
}
