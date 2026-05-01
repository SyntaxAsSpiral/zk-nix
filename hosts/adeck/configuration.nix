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
    ../../modules/system.nix
    ../../modules/boot.nix
    ../../modules/user.nix
    ../../modules/networking.nix
    ../../modules/storage.nix
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

  security.sudo.extraRules = [
    {
      users = [ "hermes" ];
      commands = [
        {
          command = "${pkgs.docker}/bin/docker";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.hermes-agent = {
    enable = true;
    container = {
      enable = true;
      hostUsers = [ "zk" ];
    };
    addToSystemPackages = true;
    extraArgs = [ "--accept-hooks" ];
    settings = {
      model = {
        default = "supergemma4-26b-uncensored-v2";
        provider = "custom";
        api_key = "lms";
        base_url = "http://localhost:1234/v1";
      };
      toolsets = [ "hermes-cli" ];
      agent = {
        max_turns = 60;
        gateway_timeout = 1800;
        restart_drain_timeout = 60;
        gateway_timeout_warning = 900;
        gateway_notify_interval = 180;
        reasoning_effort = "medium";
      };
      terminal = {
        backend = "local";
        timeout = 180;
        persistent_shell = true;
      };
      compression = {
        enabled = true;
        threshold = 0.85;
        target_ratio = 0.2;
        protect_last_n = 20;
      };
      dashboard = {
        host = "100.89.32.9";
        port = 9119;
      };
    };
  };

  systemd.services.hermes-dashboard = {
    description = "Hermes Agent web dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "hermes-agent.service" ];
    wants = [ "hermes-agent.service" ];
    environment = {
      HOME = "/var/lib/hermes";
      HERMES_HOME = "/var/lib/hermes/.hermes";
      PATH = lib.mkForce "/run/wrappers/bin:${lib.makeBinPath [ pkgs.docker ]}";
    };
    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      WorkingDirectory = "/var/lib/hermes/workspace";
      ExecStart = "/run/current-system/sw/bin/hermes dashboard --host 100.89.32.9 --port 9119 --no-open --insecure";
      Restart = "always";
      RestartSec = 10;
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/zk/.local/bin 0755 zk users -"
    "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
  ];

  system.stateVersion = "24.11";
}
