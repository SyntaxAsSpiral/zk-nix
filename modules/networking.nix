# Network configuration
{ config, lib, pkgs, ... }:

let
  perHost = {
    nxiz = {
      hostName = "nxiz";
      resolvedDns = true;
      postResumeDnsFlush = true;
    };
    adeck = {
      hostName = "adeck";
      resolvedDns = false;
      postResumeDnsFlush = false;
    };
    zrrh = {
      hostName = "zrrh";
      resolvedDns = true;
      postResumeDnsFlush = true;
    };
  };
  h = perHost.${config.my.host};
in
{
  networking.hostName = h.hostName;
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkIf h.resolvedDns "systemd-resolved";
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ];
    allowedUDPPortRanges = [{ from = 60000; to = 61000; }];
  };

  services.resolved.enable = h.resolvedDns;
  services.resolved.settings = lib.mkIf h.resolvedDns {
    Resolve.DNS = [ "1.1.1.1" "9.9.9.9" ];
    Resolve.FallbackDNS = [ "1.1.1.1" "9.9.9.9" ];
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

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = [ "--ssh" ];
  };
}
