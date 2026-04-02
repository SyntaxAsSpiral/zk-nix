# qBittorrent-nox on adeck — headless torrent daemon with web UI
# Access via https://adeck.tail293e98.ts.net:8080 from any mesh node
{ config, lib, pkgs, ... }:

let
  inherit (builtins) concatStringsSep isAttrs isString;
  inherit (lib) collect mapAttrsRecursive replaceString escape;
  inherit (lib.generators) toINI mkKeyValueDefault mkValueStringDefault;

  gendeepINI = toINI {
    mkKeyValue =
      let
        sep = "=";
      in
      k: v:
        if isAttrs v then
          concatStringsSep "\n" (
            collect isString (
              mapAttrsRecursive (
                path: value:
                  "${escape [ sep ] (concatStringsSep "\\" ([ k ] ++ path))}${sep}${
                    replaceString "\n" "\\n" (mkValueStringDefault { } value)
                  }"
              ) v
            )
          )
        else
          mkKeyValueDefault { } sep k v;
  };

  enforcedConfig = pkgs.writeText "adeck-qBittorrent.conf" (
    gendeepINI config.services.qbittorrent.serverConfig
  );
in
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
    systemd.services.qbittorrent.preStart = ''
      install -d -m 0755 -o zk -g users /var/lib/qBittorrent/qBittorrent/config
      install -m 0600 -o zk -g users ${enforcedConfig} /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
    '';

    # Ensure torrent directory exists on the temp subvolume
    systemd.tmpfiles.rules = [
      "d /mnt/vault/@temp/torrents 0755 zk users -"
    ];
  };
}
