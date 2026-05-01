{ config, ... }:

{
  systemd.user.services.hermes-dashboard = {
    Unit = {
      Description = "Hermes Agent web dashboard";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "/run/current-system/sw/bin/hermes dashboard --host 100.89.32.9 --port 9119 --no-open --insecure";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "HERMES_HOME=${config.home.homeDirectory}/.hermes"
      ];
    };
  };
}
