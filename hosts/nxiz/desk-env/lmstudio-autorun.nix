{ pkgs, ... }:

{
  # LM Studio on nxiz. The package provides the binary; LM Studio owns ~/.lmstudio.
  systemd.user.services.lmstudio = {
    Unit = {
      Description = "LM Studio";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
