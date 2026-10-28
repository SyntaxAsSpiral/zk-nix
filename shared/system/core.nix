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

  # Bash stays the login shell. Interactive SSH and tty1 enter Nushell.
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      if [[ $- == *i* && -t 0 ]]; then
        if [[ -n "$SSH_CONNECTION" && -z "$NUSHELL_VERSION" ]]; then
          exec ${pkgs.nushell}/bin/nu --login
        fi
        if [[ "$(tty)" == "/dev/tty1" ]]; then
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
