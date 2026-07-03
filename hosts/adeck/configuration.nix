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
    ../../modules/pulse-generator.nix
    ../../modules/qbittorrent.nix
    ../../modules/sideriod-mcp.nix
  ];

  my.host = "adeck";

  # Jovian-NixOS Hardware Support (Steam Deck)
  # This enables udev rules, fan control, and other hardware-specific tweaks.
  jovian.devices.steamdeck.enable = true;

  programs.niri.enable = true;
  programs.dconf.enable = true;

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    fwupd.enable = true;
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
  ];

  systemd = {
    # Firmware fan control is sufficient on this device; Jovian fan daemon crashes
    # because expected hwmon names are absent on this hardware/kernel combo.
    services.jupiter-fan-control.enable = lib.mkForce false;

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
