# Network configuration
{ config, lib, pkgs, ... }:

let
  perHost = {
    nxiz = {
      hostName = "nxiz";
      resolvedDns = true;
      postResumeDnsFlush = true;
      nmEnvironmentFiles = [ config.age.secrets.wifi-password.path ];
      nmProfiles = {
        gbz = {
          connection = {
            id = "GBZ";
            type = "wifi";
            autoconnect = true;
            autoconnect-priority = 100;
          };
          wifi = {
            mode = "infrastructure";
            ssid = "GBZ";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$GBZ_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
      # Replace the bootstrap profile added before this config reaches nxiz.
      dropNmFiles = [ "GBZ.nmconnection" ];
    };
    adeck = {
      hostName = "adeck";
      resolvedDns = false;
      postResumeDnsFlush = false;
      # Dock ethernet used to be a static 10.77 WOL link; it is the LAN drop now.
      nmProfiles = {
        lan = {
          connection = {
            id = "lan";
            type = "ethernet";
            autoconnect = true;
            autoconnect-priority = 100;
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
      # Persistent keyfile outlives ensureProfiles (/run); delete so it cannot win.
      dropNmFiles = [ "zrrh-wol.nmconnection" ];
    };
    zrrh = {
      hostName = "zrrh";
      resolvedDns = true;
      postResumeDnsFlush = true;
      # Apply to the existing DHCP profile without replacing its connection.
      nmWake = true;
    };
  };
  h = perHost.${config.my.host};
in
{
  networking = {
    hostName = h.hostName;
    networkmanager.enable = true;
    networkmanager.dns = lib.mkIf h.resolvedDns "systemd-resolved";
    networkmanager.ensureProfiles.environmentFiles = h.nmEnvironmentFiles or [ ];
    networkmanager.ensureProfiles.profiles = h.nmProfiles or { };
    networkmanager.settings.main.no-auto-default = lib.mkIf ((h.nmProfiles or { }) != { }) "*";
    networkmanager.settings."connection-zrrh-wol" = lib.mkIf (h.nmWake or false) {
      match-device = "mac:60:cf:84:61:d8:00";
      "ethernet.wake-on-lan" = 64; # NM config uses the numeric magic-packet flag.
    };
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
      allowedUDPPortRanges = [{ from = 60000; to = 61000; }];
    };
  };

  services = {
    resolved.enable = h.resolvedDns;
    resolved.settings = lib.mkIf h.resolvedDns {
      Resolve.DNS = [ "1.1.1.1" "9.9.9.9" ];
      Resolve.FallbackDNS = [ "1.1.1.1" "9.9.9.9" ];
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--ssh" ];
    };
  };

  system.activationScripts.nm-drop-persistent = lib.mkIf ((h.dropNmFiles or [ ]) != [ ]) {
    text = lib.concatMapStrings (f: ''
      rm -f /etc/NetworkManager/system-connections/${lib.escapeShellArg f}
    '') h.dropNmFiles;
  };

  environment.etc."systemd/system-sleep/10-dns-resume" = lib.mkIf h.postResumeDnsFlush {
    text = ''
      #!/bin/sh
      if [ "$1" = "post" ]; then
        ${pkgs.systemd}/bin/resolvectl flush-caches || true
        ${pkgs.systemd}/bin/resolvectl reset-server-features || true
        ${pkgs.networkmanager}/bin/nmcli general reload || true
      fi
    '';
    mode = "0755";
  };
}
