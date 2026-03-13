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
            SavePath = "/mnt/vault/@staging/";
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
          DefaultSavePath = "/mnt/vault/@staging/";
        };

        AutoRun = {
          Enabled = true;
          # %F = content path (file or folder)
          Program = ''/run/current-system/sw/bin/scp -r "%F" zk@zrrh:/mnt/media/Incoming/'';
        };
      };

      extraArgs = [ "--confirm-legal-notice" ];
    };

    # Allow scp in autorun to read SSH keys from ~/.ssh
    systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

    # Ensure torrent staging directory exists on vault
    systemd.tmpfiles.rules = [
      "d /mnt/vault/@staging 0755 zk users -"
    ];
  };
}
