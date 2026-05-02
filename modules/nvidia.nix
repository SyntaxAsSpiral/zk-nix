# NVIDIA graphics
{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;  # enables nvidia-suspend/resume/hibernate services
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland/Niri performance and stability
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_DynamicPowerManagement=0x02
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';
}
