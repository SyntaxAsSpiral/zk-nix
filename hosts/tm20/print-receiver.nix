# Mesh print receiver — POST http://tm20:8766/print
# USB stays on this host. Clients: Holliday Table, holliday-estate, sideriod.
{
  pkgs,
  ...
}:

let
  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);
  receiver = ./print_receiver.py;
in
{
  networking.firewall.allowedTCPPorts = [ 8766 ];

  systemd.services.print-receiver = {
    description = "tm20 mesh print receiver";
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.tm20-cli
      pkgs.tailscale
      pkgs.coreutils
    ];
    serviceConfig = {
      User = "zk";
      Group = "plugdev";
      SupplementaryGroups = [ "plugdev" ];
      StateDirectory = "print-receiver";
      WorkingDirectory = "/var/lib/print-receiver";
      Environment = [
        "PRINT_SPOOL=/var/lib/print-receiver/spool"
        "PRINT_PORT=8766"
      ];
      EnvironmentFile = "/run/secrets/print-token";
      ExecStartPre = pkgs.writeShellScript "wait-tailscale-ip" ''
        set -euo pipefail
        for _ in $(seq 1 30); do
          if ${pkgs.tailscale}/bin/tailscale ip -4 | grep -q .; then
            exit 0
          fi
          sleep 1
        done
        echo "no Tailscale IPv4 after 30s" >&2
        exit 1
      '';
      ExecStart = "${python}/bin/python3 ${receiver} --port 8766";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
