# NixOS configuration for zrrh — local inference + media/gaming workstation
{ pkgs, inputs, ... }:

{
  imports = [
    # Global
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/system.nix
    ../../modules/nh.nix
    ../../modules/user.nix
    ../../modules/services.nix
    ../../modules/storage.nix
    ../../modules/packages.nix
    ../../modules/networking.nix
    ../../modules/overlays.nix
    ../../modules/fonts.nix
    ../../modules/nvidia.nix
    ../../modules/steam.nix
    ../../modules/performance.nix
    ../../modules/openrgb
    inputs.pia.nixosModules.default
  ];

  my.host = "zrrh";
  my.performance.enable = true;

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
      REPO_KEYS="/etc/nixos/secrets/hosts/zrrh"
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

  # Thunar service + plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  # Compositor
  programs.niri.enable = true;
  programs.xwayland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # Gaming extras
  programs.gamemode.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Earlier NVIDIA handoff for sharper boot graphics
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # GPU Control (AMD/NVIDIA)
  services.lact.enable = true;

  # PIA managed natively for now (disable declarative pia.nix service to avoid conflicts).

  environment.systemPackages = with pkgs; [
    mangohud
    vkbasalt
    vlc
    qbittorrent
    xwayland-satellite
  ];

  system.stateVersion = "25.11";
}
