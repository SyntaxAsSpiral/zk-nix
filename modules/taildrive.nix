# Drive mounts: local disks + NFS automounts for mesh shares
#
# Local disks mount normally at boot.
# Remote NFS shares use systemd automount: zero boot delay,
# mount-on-access, unmount after 60s idle.
#
# NFS servers are configured per-host (only hosts with exports run nfsd).
# Clients address servers by Tailscale IP (stable across network changes).
{ config, lib, pkgs, ... }:

let
  # Tailscale IPs (stable identifiers)
  ts = {
    nxiz  = "100.115.135.104";
    zrrh  = "100.126.60.24";
    adeck = "100.89.32.9";
  };

  # NFS automount options: lazy mount on access, no boot dependency
  nfsAutoOpts = [
    "nfsvers=4.2"
    "soft"              # return errors rather than hang indefinitely
    "timeo=10"          # 1s timeout per RPC attempt
    "retrans=1"         # 1 retry then give up
    "_netdev"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=60"
    "x-systemd.mount-timeout=5"
  ];

  # --- Per-host filesystem declarations ---
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
      nfs = {
        "/mnt/media" = {
          device = "${ts.zrrh}:/mnt/media";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
        "/mnt/vault" = {
          device = "${ts.adeck}:/mnt/vault";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
      };
      exports = ''
        /mnt/repository  ${ts.adeck}(rw,no_subtree_check,no_root_squash) ${ts.zrrh}(rw,no_subtree_check,no_root_squash)
      '';
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
      };
      nfs = {
        "/mnt/repository" = {
          device = "${ts.nxiz}:/mnt/repository";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
        "/mnt/media" = {
          device = "${ts.zrrh}:/mnt/media";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
      };
      exports = ''
        /mnt/vault  ${ts.nxiz}(rw,no_subtree_check,no_root_squash) ${ts.zrrh}(rw,no_subtree_check,no_root_squash)
      '';
    };

    zrrh = {
      local = {
        # Current zrrh layout (by UUID to avoid nvme enumeration drift):
        #   /mnt/media -> nvme1n1p1 (label Media)
        #   /mnt/games -> nvme1n1p2 (label Games)
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
      nfs = {
        "/mnt/repository" = {
          device = "${ts.nxiz}:/mnt/repository";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
        "/mnt/vault" = {
          device = "${ts.adeck}:/mnt/vault";
          fsType = "nfs";
          options = nfsAutoOpts;
        };
      };
      exports = ''
        /mnt/media  ${ts.nxiz}(rw,no_subtree_check,no_root_squash) ${ts.adeck}(ro,no_subtree_check,no_root_squash)
      '';
    };
  };

  h = perHost.${config.my.host};
  hasExports = h.exports != null;
  hasLocalVault = h.local ? "/mnt/vault";
in
{
  # NFS client support (all hosts)
  environment.systemPackages = [ pkgs.nfs-utils ];

  # NFS server (only on hosts that export)
  services.nfs.server = lib.mkIf hasExports {
    enable = true;
    exports = h.exports;
  };

  # On adeck, only run nfs-server when the vault block device is present.
  # This avoids boot-time exportfs warnings when undocked.
  systemd.services.nfs-server.unitConfig = lib.mkIf (config.my.host == "adeck") {
    ConditionPathExists = "/dev/disk/by-uuid/b802e750-3c43-4004-9caf-4d34ae1ddaaf";
  };

  # When /mnt/vault mounts (automount trigger), start nfs-server.
  # Works both after docking and after first local access.
  systemd.services.nfs-server-after-vault = lib.mkIf (config.my.host == "adeck") {
    description = "Start nfs-server after /mnt/vault is mounted";
    wantedBy = [ "mnt-vault.mount" ];
    after = [ "mnt-vault.mount" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start nfs-server.service";
    };
  };

  # Open NFS port on hosts that export
  networking.firewall.allowedTCPPorts = lib.mkIf hasExports [ 2049 ];

  # Merge local + NFS mounts
  fileSystems = h.local // h.nfs;
}
