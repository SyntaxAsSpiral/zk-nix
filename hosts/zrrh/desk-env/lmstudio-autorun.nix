{ pkgs, ... }:

{
  imports = [ ../../../shared/home/lmstudio-logs.nix ];

  # LM Studio on zrrh. The package provides the binary; LM Studio owns ~/.lmstudio.
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
