# NixOS configuration for seed — portable x86_64 UEFI stick. It is the core: copy it to
# start a host, then add on. It is also the rescue stick. Boot the target, join GBZ Wi-Fi
# and Tailscale, SSH in, then partition and install, or run `zcli deploy seed` to deploy itself.
# Names its own shared modules. packages.nix and the NVIDIA/Steam desktop
# blew the stick out to 8.5 GiB, so they are not in this list.
# Console only: no display server.
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../shared/system/system.nix
    ../../shared/system/boot.nix
    ../../shared/system/nh.nix
    ../../shared/system/secrets.nix
    ../../shared/system/networking.nix
    ../../shared/system/ssh-identity.nix
    ../../shared/system/shell.nix
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
  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh = {
      enable = true;
      extraConfig = "AcceptEnv TERM_PROGRAM";
    };
    getty.autologinUser = "zk";
  };

  # Same handoff as the mesh: bash stays the login shell, interactive SSH and tty1 enter Nushell.
  programs.bash.interactiveShellInit = ''
    if [[ $- == *i* && -t 0 ]]; then
      if [[ -n "$SSH_CONNECTION" && -z "$NUSHELL_VERSION" ]]; then
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
  ];

  system.stateVersion = "25.11";
}
