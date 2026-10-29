# The core every host starts from: the common system modules, the zk login user,
# and the SSH and tty1 handoff to Nushell. Seed is the core plus the stick.
{ config, pkgs, ... }:

{
  imports = [
    ./system.nix
    ./nh.nix
    ./secrets.nix
    ./networking.nix
    ./ssh-identity.nix
    ./shell.nix
  ];

  users.users.zk = {
    isNormalUser = true;
    uid = 1000;
    description = "zk@${config.my.host}";
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Bash stays the login shell. Interactive SSH and the local console enter Nushell. The
  # console is tty1, or a kmscon pty: no SSH, and no display. Nushell exports NU_VERSION,
  # so a bash started from inside it stays bash.
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      if [[ $- == *i* && -t 0 && -z "$NU_VERSION" ]]; then
        tty_name=$(tty)
        if [[ -n "$SSH_CONNECTION" || "$tty_name" == /dev/tty1 ||
              ( "$tty_name" == /dev/pts/* && -z "$DISPLAY$WAYLAND_DISPLAY" ) ]]; then
          exec ${pkgs.nushell}/bin/nu --login
        fi
      fi
    '';
  };

  services = {
    openssh = {
      enable = true;
      extraConfig = "AcceptEnv TERM_PROGRAM";
    };
    getty.autologinUser = "zk";
  };
}
