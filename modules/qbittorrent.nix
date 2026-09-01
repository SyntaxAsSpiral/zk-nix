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

  # SO_MARK 0x54 selects ip rule 5181 → table 52 (Mullvad). Netfilter
  # OUTPUT marks happen after fib lookup, so they cannot do this.
  qbtMarkLib = pkgs.runCommandCC "libqbtmark" { } ''
    mkdir -p $out/lib
    cat > mark.c <<'EOF'
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <sys/socket.h>
    int socket(int domain, int type, int protocol) {
      static int (*real_socket)(int, int, int) = 0;
      if (!real_socket)
        real_socket = dlsym(RTLD_NEXT, "socket");
      int fd = real_socket(domain, type, protocol);
      if (fd >= 0) {
        int mark = 0x54;
        setsockopt(fd, SOL_SOCKET, SO_MARK, &mark, sizeof(mark));
      }
      return fd;
    }
    EOF
    $CC -shared -fPIC -o $out/lib/libqbtmark.so mark.c -ldl
  '';
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
          # Mullvad via policy routing (see qbt-mullvad-policy). Do not punch the LAN.
          PortForwardingEnabled = false;
          LSDEnabled = false;
          InterfaceName = "tailscale0";
        };

        AutoRun = {
          Enabled = true;
          # Completion triggers a local scanner that syncs stable payloads to zrrh
          Program = "/etc/nixos/scripts/qbt-sync-zrrh.sh";
        };
      };

      extraArgs = [ "--confirm-legal-notice" ];
    };

    # Allow scp in autorun to read SSH keys from ~/.ssh.
    # PrivateUsers must be off so CAP_NET_ADMIN/SO_MARK applies to host routing.
    systemd.services.qbittorrent.serviceConfig = {
      ProtectHome = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      AmbientCapabilities = "CAP_NET_ADMIN";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_ADMIN";
      Environment = "LD_PRELOAD=${qbtMarkLib}/lib/libqbtmark.so";
      # IPv6 sockets bind the LAN/Comcast addresses and skip Mullvad.
      RestrictAddressFamilies = lib.mkForce [
        "AF_INET"
        "AF_NETLINK"
      ];
    };
    systemd.services.qbittorrent.preStart = ''
      install -d -m 0755 -o zk -g users /var/lib/qBittorrent/qBittorrent/config
      install -m 0600 -o zk -g users ${enforcedConfig} /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
    '';

    # Ensure torrent directory exists on the temp subvolume
    systemd.tmpfiles.rules = [
      "d /mnt/vault/@temp/torrents 0755 zk users -"
    ];

    # Bring Mullvad up as an exit node on this Tailscale identity, but do not
    # let Tailscale's default "lookup 52" rule swallow the whole host.
    services.tailscale.extraSetFlags = [
      "--exit-node=auto:any"
      "--exit-node-allow-lan-access=true"
      "--accept-dns=false"
    ];

    systemd.services.qbt-mullvad-policy = {
      description = "Route only qBittorrent through the Tailscale Mullvad exit node";
      after = [ "tailscaled.service" ];
      before = [
        "tailscaled-set.service"
        "qbittorrent.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.iproute2
        pkgs.iptables
        pkgs.nftables
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
      };
      script = ''
        set -euo pipefail
        MARK=0x54
        TABLE=52
        PREF_TS=5180
        PREF_QBT=5181
        PREF_MAIN=5182

        flush_pref() {
          local fam="$1" pref="$2"
          while ip "-$fam" rule del pref "$pref" 2>/dev/null; do :; done
        }

        apply_rules() {
          flush_pref 4 "$PREF_TS"
          flush_pref 4 "$PREF_QBT"
          flush_pref 4 "$PREF_MAIN"
          ip -4 rule add pref "$PREF_TS" to 100.64.0.0/10 lookup "$TABLE"
          ip -4 rule add pref "$PREF_QBT" fwmark "$MARK" lookup "$TABLE"
          ip -4 rule add pref "$PREF_MAIN" lookup main

          flush_pref 6 "$PREF_TS"
          flush_pref 6 "$PREF_QBT"
          flush_pref 6 "$PREF_MAIN"
          ip -6 rule add pref "$PREF_TS" to fd7a:115c:a1e0::/48 lookup "$TABLE"
          ip -6 rule add pref "$PREF_QBT" fwmark "$MARK" lookup "$TABLE"
          ip -6 rule add pref "$PREF_MAIN" lookup main

          # NAT-PMP/SSDP to the LAN router would still succeed via allow-lan-access.
          iptables -C OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 5351 -j DROP 2>/dev/null \
            || iptables -A OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 5351 -j DROP
          iptables -C OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 1900 -j DROP 2>/dev/null \
            || iptables -A OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 1900 -j DROP
          ip6tables -C OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 5351 -j DROP 2>/dev/null \
            || ip6tables -A OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 5351 -j DROP
          ip6tables -C OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 1900 -j DROP 2>/dev/null \
            || ip6tables -A OUTPUT -m cgroup --path system.slice/qbittorrent.service -p udp --dport 1900 -j DROP
        }

        nft delete table inet qbt-mullvad 2>/dev/null || true
        nft delete table ip qbt-mullvad 2>/dev/null || true
        nft delete table ip6 qbt-mullvad 2>/dev/null || true
        while true; do
          apply_rules
          sleep 15
        done
      '';
    };
  };
}
