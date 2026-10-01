# Shared baseline — imported by adeck, nxiz, and zrrh. tm20 does not import it.
# Host-specific values inside these modules key off config.my.host (perHost tables).
{
  imports = [
    ../system.nix
    ../boot.nix
    ../nh.nix
    ../user.nix
    ../secrets.nix
    ../services.nix
    ../storage.nix
    ../packages.nix
    ../networking.nix
    ../fonts.nix
    ../ssh-identity.nix
  ];
}
