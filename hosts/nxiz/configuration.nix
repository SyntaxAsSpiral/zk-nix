# NixOS configuration for nxiz
{ pkgs, ... }:

{
  imports = [

    # global
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
    # host-specific #

    # Login manager playground modules (inert by default).
    # Activate explicitly via one toggle at a time:
    #   my.login.ly.enable = true;
    #   my.login.greetd.enable = true;
    ../../modules/ly.nix
    ../../modules/greetd.nix
  ];

  my.host = "nxiz";
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
      REPO_KEYS="/etc/nixos/secrets/hosts/nxiz"
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

  # nxiz-only services
  services.gnome.gnome-keyring.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Thunar service + plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Keep Wake-on-LAN enabled on the wired NIC.
  systemd.services.wol-enp10s0 = {
    description = "Enable Wake-on-LAN on enp10s0";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -s enp10s0 wol g
    '';
  };

  system.stateVersion = "25.11";
}
