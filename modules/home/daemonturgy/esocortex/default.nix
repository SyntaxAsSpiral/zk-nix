{ pkgs, ... }:

{
  # Loopback only. Mesh access is tailscale serve, same shape as hermes-dashboard.
  systemd.user.services.esocortex-api = {
    Unit = {
      Description = "Esocortex read-only HTTP API";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 /mnt/echo/esocortex/cli/api.py --host 127.0.0.1 --port 8880";
      ExecStartPost = "-${pkgs.tailscale}/bin/tailscale serve --bg --https=8880 http://127.0.0.1:8880";
      ExecStopPost = "-${pkgs.tailscale}/bin/tailscale serve --https=8880 off";
      Restart = "always";
      RestartSec = "5";
      WorkingDirectory = "/mnt/echo/esocortex";
      Environment = [
        "PYTHONPATH=/mnt/echo/esocortex/src"
      ];
    };
  };
}
