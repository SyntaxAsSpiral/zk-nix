# NVIDIA graphics
{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;  # enables nvidia-suspend/resume/hibernate services
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland/Niri performance and stability
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_DynamicPowerManagement=0x02
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  # nvidia-sleep.sh is a Type=oneshot with infinite start timeout and is
  # Required by systemd-suspend. Hyprland 0.56 keeps the DRM device busy, so
  # the write to /proc/driver/nvidia/suspend busy-loops (fans, never sleeps).
  # Freeze Hyprland first (no-op on niri/zrrh). Cap the hook so a miss fails
  # in seconds instead of hanging the suspend job.
  systemd.services = {
    nvidia-suspend.serviceConfig = {
      TimeoutStartSec = "20s";
      TimeoutStopSec = "5s";
    };
    nvidia-hibernate.serviceConfig = {
      TimeoutStartSec = "20s";
      TimeoutStopSec = "5s";
    };

    hyprland-pre-nvidia-sleep = {
      description = "Freeze Hyprland before NVIDIA suspend";
      before = [
        "nvidia-suspend.service"
        "nvidia-hibernate.service"
        "systemd-suspend.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "hyprland-pre-nvidia-sleep" ''
          ${pkgs.procps}/bin/pkill -STOP -f '/bin/Hyprland( |$)' || true
        '';
      };
    };

    hyprland-post-nvidia-wake = {
      description = "Unfreeze Hyprland after NVIDIA resume";
      after = [
        "nvidia-resume.service"
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "hyprland-post-nvidia-wake" ''
          ${pkgs.procps}/bin/pkill -CONT -f '/bin/Hyprland( |$)' || true
        '';
      };
    };
  };
}
