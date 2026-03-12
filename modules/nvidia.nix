# NVIDIA graphics
{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;  # preserves VRAM on suspend, fixes resume
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland/Niri performance and stability
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_DynamicPowerManagement=0x02
  '';
}
