{ ... }:

{
  systemd.user.services.honcho-mcp = {
    Unit = {
      Description = "Honcho MCP Server";
      After = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "%h/honcho/mcp";
      ExecStart = "%h/honcho/mcp/node_modules/.bin/wrangler dev --port 8787 --ip 0.0.0.0";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
