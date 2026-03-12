# NixOS configuration for adeck — agentic server
{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system.nix
    ../../modules/boot.nix
    ../../modules/user.nix
    ../../modules/networking.nix
    ../../modules/taildrive.nix
    ../../modules/nh.nix
    ../../modules/services.nix
    ../../modules/pulse-generator.nix
    ../../modules/packages.nix
    ../../modules/fonts.nix
    ../../modules/qbittorrent.nix
  ];

  my.host = "adeck";

  # Host Identity (SSH)
  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Robust host key management — copy from flake repo to /etc/ssh with correct permissions
  system.activationScripts.sshHostKeys = {
    text = ''
      mkdir -p /etc/ssh
      REPO_KEYS="/etc/nixos/secrets/hosts/adeck"
      if [ -d "$REPO_KEYS" ]; then
        for key in ssh_host_ed25519_key ssh_host_rsa_key; do
          if [ -f "$REPO_KEYS/$key" ]; then
            rm -f "/etc/ssh/$key"
            cp -f "$REPO_KEYS/$key" "/etc/ssh/$key"
            chmod 600 "/etc/ssh/$key"
            chown root:root "/etc/ssh/$key"
          fi
          if [ -f "$REPO_KEYS/$key.pub" ]; then
            rm -f "/etc/ssh/$key.pub"
            cp -f "$REPO_KEYS/$key.pub" "/etc/ssh/$key.pub"
            chmod 644 "/etc/ssh/$key.pub"
            chown root:root "/etc/ssh/$key.pub"
          fi
        done
      fi
    '';
    deps = [ "etc" ];
  };

  # Jovian-NixOS Hardware Support (Steam Deck)
  # This enables udev rules, fan control, and other hardware-specific tweaks.
  jovian.devices.steamdeck.enable = true;

  programs.niri.enable = true;
  programs.dconf.enable = true;

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  security.polkit.enable = true;
  # Firmware fan control is sufficient on this device; Jovian fan daemon crashes
  # because expected hwmon names are absent on this hardware/kernel combo.
  systemd.services.jupiter-fan-control.enable = lib.mkForce false;

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
  ];

  # Prevent screen dimming during stage 2 boot by forcing it to 100%
  systemd.services.restore-brightness = {
    description = "Force brightness to 100% on boot";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  virtualisation.docker.enable = true;

  systemd.tmpfiles.rules = [
    "d /home/zk/.local/bin 0755 zk users -"
    "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
  ];

  system.stateVersion = "24.11";
}
