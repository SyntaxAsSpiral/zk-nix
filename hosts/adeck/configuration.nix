# NixOS configuration for adeck — agentic server
{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/core.nix
    ../../modules/llama-tts.nix
    ../../modules/pulse-generator.nix
    ../../modules/qbittorrent.nix
  ];

  my.host = "adeck";

  # Jovian-NixOS Hardware Support (Steam Deck)
  # This enables udev rules, fan control, and other hardware-specific tweaks.
  jovian.devices.steamdeck.enable = true;

  programs.niri.enable = true;
  programs.dconf.enable = true;

  # Compressed swap in RAM — no disk/filesystem changes needed.
  # 14GiB physical; zram default (50%) gives ~7GiB of pressure relief
  # before oomd has to reap agents.
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 100; # zram swap is cheap; use it eagerly

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    fwupd.enable = true;
    # Apply as soon as the Steam Deck EC hwmon shows up (boot/rebind).
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="hwmon", ATTR{name}=="steamdeck_hwmon", ATTR{max_battery_charge_level}="80"
    '';
  };
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    wlr-randr
    kanshi
    waybar
    fuzzel
    pavucontrol
    playerctl
    swayidle
    inputs.jolt.packages.${pkgs.stdenv.hostPlatform.system}.default
    llm-agents.pi
    llm-agents.codex
    llm-agents.gemini-cli
    llm-agents.crush
    llm-agents.grok
  ];

  systemd = {
    # Firmware fan control is sufficient on this device; Jovian fan daemon crashes
    # because expected hwmon names are absent on this hardware/kernel combo.
    # (The jovian kernel restores those hwmon names — revisit if fan curves are wanted.)
    services.jupiter-fan-control.enable = lib.mkForce false;

    # Battery longevity: always plugged in, so cap charge at 80% (like SteamOS).
    # The knob is steamdeck_hwmon from the jovian kernel. Fail if it's missing
    # instead of silently no-op'ing — that was how the cap drifted past 80.
    services.battery-charge-limit = {
      description = "Cap battery charge at 80%";
      wantedBy = [
        "multi-user.target"
        "suspend.target"
        "hibernate.target"
      ];
      after = [
        "suspend.target"
        "hibernate.target"
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -eu
        found=
        for f in /sys/class/hwmon/hwmon*/max_battery_charge_level; do
          [ -e "$f" ] || continue
          echo 80 > "$f"
          echo "set $f to 80"
          found=1
        done
        if [ -z "$found" ]; then
          echo "steamdeck max_battery_charge_level sysfs missing" >&2
          exit 1
        fi
      '';
    };
    timers.battery-charge-limit = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15s";
        OnUnitActiveSec = "10min";
        Persistent = true;
      };
    };

    # Prevent screen dimming during stage 2 boot by forcing it to 100%
    services.restore-brightness = {
      description = "Force brightness to 100% on boot";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
      };
    };

    tmpfiles.rules = [
      "d /home/zk/.local/bin 0755 zk users -"
      "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "24.11";
}
