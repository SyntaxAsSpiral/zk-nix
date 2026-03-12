# User and shell configuration
{ config, pkgs, ... }:

{
  users.users.zk = {
    isNormalUser = true;
    uid = 1000;
    description = "zk@${config.my.host}";
    shell = pkgs.bash;
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "input" ];
    packages = [];
  };

  users.defaultUserShell = pkgs.bash;
  security.sudo.wheelNeedsPassword = false;

  # Keep zsh available for tools/apps that probe it.
  programs.zsh.enable = true;

  # Default shell behavior:
  # - SSH interactive sessions: hand off to Nushell (mesh shell)
  # - Local TTY1 autologin: enter Nushell login flow (per-host compositor logic lives there)
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      if [[ $- == *i* && -t 0 ]]; then
        if [[ -n "$SSH_CONNECTION" && -z "$NUSHELL_VERSION" && -z "$VSCODE_RESOLVING_ENVIRONMENT" ]]; then
          exec ${pkgs.nushell}/bin/nu --login
        fi

        if [[ "$(tty)" == "/dev/tty1" ]]; then
          exec ${pkgs.nushell}/bin/nu --login
        fi
      fi
    '';
  };

  services.getty.autologinUser = "zk";

  # Secrets management via agenix
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/zk/.ssh/id_ed25519"
  ];

  # Symlink decrypted secrets to /run/secrets/
  age.secrets = {
    wifi-password = {
      file = ../secrets/wifi-password.age;
      owner = "zk";
      group = "users";
      mode = "0400";
      path = "/run/secrets/wifi-password";
    };
    github-token = {
      file = ../secrets/github-token.age;
      owner = "zk";
      group = "users";
      mode = "0400";
      path = "/run/secrets/github-token";
    };
    github-recovery-codes = {
      file = ../secrets/github-recovery-codes.age;
      owner = "zk";
      group = "users";
      mode = "0400";
      path = "/run/secrets/github-recovery-codes";
    };
  };
}
