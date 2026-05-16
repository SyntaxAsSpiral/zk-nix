# bb-server — Bitburner WebSocket sync server + MCP bridge
{ pkgs, ... }:

{
  systemd.user.services.bb-server = {
    Unit = {
      Description = "Bitburner WS sync + MCP server";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "%h/bb-server";
      ExecStart = "${pkgs.nodejs_24}/bin/node %h/bb-server/server.js";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
