# NixOS configuration for seed — portable x86_64 UEFI rescue stick.
# Boot the target, join GBZ Wi-Fi and Tailscale, SSH in, partition and install.
# Does not import profiles/core.nix: that profile is the workstation set
# (Playwright, the NVIDIA/Steam desktop) and blew the stick out to 8.5 GiB.
# XFCE is local to this file: LightDM on tty7, tty1 stays a rescue console.
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system.nix
    ../../modules/boot.nix
    ../../modules/nh.nix
    ../../modules/secrets.nix
    ../../modules/networking.nix
    ../../modules/ssh-identity.nix
  ];

  my.host = "seed";

  # Portable stick: never write NVRAM boot entries on whatever box it is plugged into.
  # bootctl still installs the removable fallback EFI/BOOT/BOOTX64.EFI.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  documentation.enable = false;

  users.users.zk = {
    isNormalUser = true;
    uid = 1000;
    description = "zk@seed";
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
      "networkmanager"
      "disk"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
    ];
  };
  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  # Same shape as the old adeck desktop module: LightDM, autologin, PipeWire.
  # XFCE instead of Enlightenment. No 32-bit audio, no Bluetooth, no Steam.
  # tty1 stays a console. LightDM conflicts with getty@tty7, not tty1,
  # so a machine whose GPU never comes up still boots into a shell.
  services = {
    openssh = {
      enable = true;
      extraConfig = "AcceptEnv TERM_PROGRAM";
    };
    getty.autologinUser = "zk";

    xserver = {
      enable = true;
      xkb.layout = "us";
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
      displayManager.lightdm.enable = true;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin = {
        enable = true;
        user = "zk";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts-color-emoji
    recursive
  ];

  # Same handoff as the mesh: bash stays the login shell, interactive SSH and tty1 enter Nushell.
  programs.bash.interactiveShellInit = ''
    if [[ $- == *i* && -t 0 ]]; then
      if [[ -n "$SSH_CONNECTION" && -z "$NUSHELL_VERSION" && -z "$VSCODE_RESOLVING_ENVIRONMENT" ]]; then
        exec ${pkgs.nushell}/bin/nu --login
      fi
      if [[ "$(tty)" == "/dev/tty1" ]]; then
        exec ${pkgs.nushell}/bin/nu --login
      fi
    fi
  '';

  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs
    xfsprogs
    cryptsetup
    nvme-cli
    smartmontools
    efibootmgr
    pciutils
    usbutils
    rsync
    git
    curl
    tmux
    nixos-install-tools
    firefox
  ];

  system.stateVersion = "25.11";
}
