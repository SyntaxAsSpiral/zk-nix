# Local disks + Taildrive shares
#
# Local disks mount normally at boot.
# Remote access is via Taildrive (WebDAV at 100.100.100.100:8080),
# browsable through Thunar bookmarks — no NFS, no mount dependencies.
#
# Taildrive shares are declared per-host and registered via a systemd
# oneshot after tailscaled is online.
{ config, lib, pkgs, ... }:

let
  perHost = {
    nxiz = {
      local = {
        "/mnt/repository" = {
          device = "/dev/disk/by-uuid/0d00b77b-254d-4372-82c3-d19e139ab088";
          fsType = "btrfs";
          options = [ "ssd" "discard=async" "space_cache=v2" "noatime" ];
        };
        "/mnt/archive" = {
          device = "/dev/disk/by-uuid/619e6bb2-7f29-4236-82a0-1153e7503454";
          fsType = "btrfs";
          options = [ "space_cache=v2" "noatime" ];
        };
      };
      # Taildrive shares: name → local path
      driveShares = {
        repository = "/mnt/repository";
        archive = "/mnt/archive";
      };
    };

    adeck = {
      local = {
        "/mnt/vault" = {
          device = "/dev/disk/by-uuid/b802e750-3c43-4004-9caf-4d34ae1ddaaf";
          fsType = "btrfs";
          options = [
            "compress=zstd:1"
            "noatime"
            "nofail"
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=60"
            "x-systemd.mount-timeout=5"
            "x-systemd.device-timeout=5"
          ];
        };
        "/mnt/echo" = {
          device = "/dev/disk/by-uuid/ba0a8294-d776-48ed-b436-8fefda48fc03";
          fsType = "btrfs";
          options = [
            "ssd"
            "discard=async"
            "noatime"
            "nofail"
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=60"
            "x-systemd.mount-timeout=5"
            "x-systemd.device-timeout=5"
          ];
        };
      };
      driveShares = {
        vault = "/mnt/vault";
        echo = "/mnt/echo";
      };
    };

    zrrh = {
      local = {
        "/mnt/media" = {
          device = "/dev/disk/by-uuid/112f1862-0a75-4b85-b33e-95f36bfda498";
          fsType = "btrfs";
          options = [ "ssd" "discard=async" "space_cache=v2" "noatime" "nofail" ];
        };
        "/mnt/games" = {
          device = "/dev/disk/by-uuid/7b93a14d-9680-4458-b36a-d46ef18432b4";
          fsType = "btrfs";
          options = [ "ssd" "discard=async" "space_cache=v2" "noatime" "nofail" ];
        };
      };
      driveShares = {
        media = "/mnt/media";
        games = "/mnt/games";
      };
    };
  };

  h = perHost.${config.my.host};
  hasShares = h.driveShares != {};

  # Build the shell commands to register Taildrive shares
  shareCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: path:
      "${pkgs.tailscale}/bin/tailscale drive share ${name} ${path}"
    ) h.driveShares
  );
in
{
  fileSystems = h.local;

  # Register Taildrive shares after tailscaled is online
  systemd.services.taildrive-shares = lib.mkIf hasShares {
    description = "Register Taildrive shares";
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "zk";
      # tailscaled needs a moment to come online after the unit starts
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = pkgs.writeShellScript "taildrive-register" ''
        set -euo pipefail
        ${shareCommands}
      '';
    };
  };
}
