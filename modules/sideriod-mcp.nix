{ pkgs, ... }:
let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [ mcp ]);
in
{
  systemd.services.sideriod-mcp = {
    description = "Sideriod MCP Server";
    after = [
      "network.target"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.nix
      pkgs.git
    ];

    environment = {
      SIDERIOD_MCP_TRANSPORT = "http";
      SIDERIOD_MCP_HOST = "0.0.0.0";
      SIDERIOD_MCP_PORT = "8765";
    };

    serviceConfig = {
      User = "zk";
      ExecStart = "${pythonEnv}/bin/python3 /home/zk/sideriod/mcp/server.py";
      Restart = "on-failure";
      RestartSec = "5s";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
