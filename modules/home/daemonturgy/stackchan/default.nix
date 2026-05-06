{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.aiohttp ]);

  bridgeScript = pkgs.writeTextFile {
    name = "stackchan-bridge.py";
    text = builtins.readFile ./bridge.py;
  };
in
{
  systemd.user.services.stackchan-bridge = {
    Unit = {
      Description = "Stack-chan ↔ Sideriod MCP bridge (XiaoZhi relay)";
      After = [ "network-online.target" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pythonEnv}/bin/python3 ${bridgeScript}";
      Restart = "always";
      RestartSec = "20";
    };
  };
}
