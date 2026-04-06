{ ... }:

let
  lexemancySiteDir = "/home/zk/lexemancy-site";
  pulsePython = "/etc/profiles/per-user/zk/bin/python3";
in
{
  systemd.services.pulse-generator = {
    description = "Pulse Log Generator";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "zk";
      WorkingDirectory = lexemancySiteDir;
      Environment = "PATH=/etc/profiles/per-user/zk/bin:/run/current-system/sw/bin";
      ExecStart = "${pulsePython} src/github_status_rotator.py";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  systemd.timers.pulse-generator = {
    description = "Run Pulse Generator daily at 2:24 AM PST";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 02:24:00";
      Persistent = true;
      Unit = "pulse-generator.service";
    };
  };
}
