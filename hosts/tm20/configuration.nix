# NixOS configuration for tm20 — Pi 3B+ print-host appliance.
# Minimal: firmware, NM, Tailscale, SSH, Epson USB. No desktop, no HM, no core profile.
# tm20/tm20-set and print-receiver are a later layer.
{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/system.nix
    ../../modules/networking.nix
    ../../modules/ssh-identity.nix
  ];

  my.host = "tm20";

  sdImage.compressImage = false;
  boot.zfs.forceImportRoot = false;

  hardware.enableRedistributableFirmware = true;

  zramSwap.enable = true;

  users.groups.plugdev = { };
  users.users.zk = {
    isNormalUser = true;
    uid = 1000;
    description = "zk@tm20";
    extraGroups = [
      "wheel"
      "networkmanager"
      "plugdev"
      "dialout"
    ];
    linger = true;
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.mosh.enable = true;

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/zk/.ssh/id_ed25519"
  ];
  age.secrets.wifi-password = {
    file = ../../secrets/wifi-password.age;
    owner = "zk";
    group = "users";
    mode = "0400";
    path = "/run/secrets/wifi-password";
  };

  # system.nix includes this file; empty is enough for nix-daemon to start.
  environment.etc."nixos/secrets/nix-access-tokens.conf" = {
    text = "";
    mode = "0600";
  };

  environment.systemPackages = with pkgs; [
    coreutils
    git
    tmux
    ripgrep
    curl
    usbutils
    libusb1
    liberation_ttf
  ];

  services.udev.extraRules = ''
    # Epson TM-T20III (04b8:0e28) — raw USB for tm20/nusb, not CUPS.
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e28", MODE="0660", GROUP="plugdev", TAG+="uaccess"

    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTRS{idVendor}=="04b8", ATTRS{idProduct}=="0e28", ATTR{bInterfaceClass}=="07", RUN+="${pkgs.bash}/bin/sh -c 'echo -n $kernel > /sys/bus/usb/drivers/usblp/unbind'"
  '';

  system.stateVersion = "25.11";
}
