# Runtime copies from the private checkout; keep values out of Nix expressions.
{ config, lib, ... }:

let
  names = [ "wifi-password" ] ++ (
    if config.my.host == "tm20" then
      [ "print-token" ]
    else
      [ "github-token" "github-recovery-codes" ]
  );
in
{
  system.activationScripts.mesh-secrets = {
    deps = [ "users" "etc" ];
    text = ''
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
