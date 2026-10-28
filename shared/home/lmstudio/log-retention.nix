{ config, pkgs, ... }:

let
  logDir = "${config.home.homeDirectory}/.lmstudio/server-logs";
  find = "${pkgs.findutils}/bin/find";
in
{
  systemd.user.services.lmstudio-log-retention = {
    Unit.Description = "Prune LM Studio server logs older than seven days";
    Service = {
      Type = "oneshot";
      ExecStart = "${find} ${logDir} -type f -name '*.log' -mmin +10080 -delete";
      ExecStartPost = "${find} ${logDir} -mindepth 1 -type d -empty -delete";
    };
  };

  systemd.user.timers.lmstudio-log-retention = {
    Unit.Description = "Run LM Studio server log retention daily";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
