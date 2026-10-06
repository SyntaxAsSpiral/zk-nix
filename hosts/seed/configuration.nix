# NixOS configuration for seed — portable x86_64 UEFI rescue stick.
# Boot the target, join GBZ Wi-Fi and Tailscale, SSH in, partition and install.
# Does not import profiles/core.nix: that profile is the workstation set
# (fonts, Playwright, PipeWire, Mesa) and blew the stick out to 8.5 GiB.
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

  services.openssh = {
    enable = true;
    extraConfig = "AcceptEnv TERM_PROGRAM";
  };

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
  services.getty.autologinUser = "zk";

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
  ];

  system.stateVersion = "25.11";
}
