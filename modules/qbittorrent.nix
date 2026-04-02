# qBittorrent-nox on adeck — headless torrent daemon with web UI
# Access via https://adeck.tail293e98.ts.net:8080 from any mesh node
{ config, lib, ... }:

{
  config = lib.mkIf (config.my.host == "adeck") {
    services.qbittorrent = {
      enable = true;
      user = "zk";
      group = "users";
      openFirewall = true;

      serverConfig = {
        LegalNotice.Accepted = true;

        Preferences = {
          General.Locale = "en";
          Downloads = {
            SavePath = "/mnt/vault/@temp/torrents/";
            TempPathEnabled = false;
          };
          WebUI = {
            Username = "zk";
            "Password_PBKDF2" = ''@ByteArray(49o93hob1WYLnAHEYkqseQ==:Q9DLtfkoPFHERaNqTl2qV43uLb8bjlhQbYm+ZW60X357V/vEgspVFcynf9SbAt5dSTJPfAYg8FyjAFOzFFYD5w==)'';
            HTTPS = {
              Enabled = true;
              CertificatePath = "/var/lib/qBittorrent/adeck.crt";
              KeyPath = "/var/lib/qBittorrent/adeck.key";
            };
          };
        };

        BitTorrent.Session = {
          AnonymousMode = true;
          MaxRatioEnabled = true;
          MaxRatio = 0;
          MaxRatioAction = 1; # Remove torrent
          Encryption = 1; # Force encrypted connections
          DefaultSavePath = "/mnt/vault/@temp/torrents/";
        };

        AutoRun = {
          Enabled = true;
          # Completion triggers a local scanner that syncs stable payloads to zrrh
          Program = "/etc/nixos/scripts/qbt-sync-zrrh.sh";
        };
      };

      extraArgs = [ "--confirm-legal-notice" ];
    };

    # Allow scp in autorun to read SSH keys from ~/.ssh
    systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

    # Ensure torrent directory exists on the temp subvolume
    systemd.tmpfiles.rules = [
      "d /mnt/vault/@temp/torrents 0755 zk users -"
    ];
  };
}
