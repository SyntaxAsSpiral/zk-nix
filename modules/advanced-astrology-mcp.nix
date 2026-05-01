{ pkgs, ... }:
let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [ mcp ]);
in {
  systemd.services.advanced-astrology-mcp = {
    description = "Advanced Astrology MCP Server";
    after = [ "network.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      ASTRO_MCP_TRANSPORT = "http";
      ASTRO_MCP_HOST = "0.0.0.0";
      ASTRO_MCP_PORT = "8765";
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
