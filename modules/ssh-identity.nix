# SSH host identity — key declarations + staging from the flake repo.
# Keys live in secrets/hosts/<host>/ and are copied to /etc/ssh on activation.
{ config, ... }:

{
  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Robust host key management — copy from flake repo to /etc/ssh with correct permissions
  system.activationScripts.sshHostKeys = {
    text = ''
      mkdir -p /etc/ssh
      REPO_KEYS="/etc/nixos/secrets/hosts/${config.my.host}"
      if [ -d "$REPO_KEYS" ]; then
        for key in ssh_host_ed25519_key ssh_host_rsa_key; do
          if [ -f "$REPO_KEYS/$key" ]; then
            rm -f "/etc/ssh/$key"
            cp -f "$REPO_KEYS/$key" "/etc/ssh/$key"
            chmod 600 "/etc/ssh/$key"
            chown root:root "/etc/ssh/$key"
          fi
          if [ -f "$REPO_KEYS/$key.pub" ]; then
            rm -f "/etc/ssh/$key.pub"
            cp -f "$REPO_KEYS/$key.pub" "/etc/ssh/$key.pub"
            chmod 644 "/etc/ssh/$key.pub"
            chown root:root "/etc/ssh/$key.pub"
          fi
        done
      fi
    '';
    deps = [ "etc" ];
  };
}
