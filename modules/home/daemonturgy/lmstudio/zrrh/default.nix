{ config, pkgs, ... }:

{
  imports = [ ../log-retention.nix ];

  # LM Studio config for zrrh.
  # System package (pkgs.lmstudio) handles binaries and services.
  # Mutable symlinks — LMStudio writes its config, so we force link to the repo.
  # The repo is stored at /etc/nixos on zrrh.
  home.activation.lmstudioConfigZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/zrrh/settings.json ${config.home.homeDirectory}/.lmstudio/settings.json
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/config-presets ${config.home.homeDirectory}/.lmstudio/config-presets
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/zrrh/http-server-config.json ${config.home.homeDirectory}/.lmstudio/.internal/http-server-config.json
  '';

  # Full GUI install: CUDA detection and `lms` CLI attach to this process.
  # niri spawn-at-startup is fire-and-forget and misses some boots.
  systemd.user.services.lmstudio = {
    Unit = {
      Description = "LM Studio";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio --hidden";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
