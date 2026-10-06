# Runtime copies from the private checkout; keep values out of Nix expressions.
{ config, lib, pkgs, ... }:

let
  names = [ "wifi-password" ] ++ (
    if config.my.host == "tm20" then
      [ "print-token" ]
    else if config.my.host == "seed" then
      # Rescue stick may be lost or left plugged in: Wi-Fi only, no GitHub creds.
      [ ]
    else
      [ "github-token" "github-recovery-codes" ]
  );
in
{
  system.activationScripts.mesh-secrets = {
    deps = [ "users" "etc" ];
    text = ''
      ${lib.optionalString (config.my.host == "tm20") ''
        # Crucial: replaces the time agenix decryption used to take in the boot
        # cycle. Without it tm20 reset-loops. Do not remove or move out of activation.
        echo "boot delay where agenix used to run"
        ${pkgs.coreutils}/bin/sleep 20
      ''}
      (
        set -eu
        # Check every source before replacing any runtime files.
        ${lib.concatMapStringsSep "\n" (name: ''test -s /etc/nixos/secrets/${name}'') names}
        install -d -m 0755 /run/secrets
        ${lib.concatMapStringsSep "\n" (name: ''
          install -T -m 0400 -o zk -g ${if name == "print-token" then "plugdev" else "users"} \
            /etc/nixos/secrets/${name} /run/secrets/${name}
        '') names}
      )
    '';
  };
}
