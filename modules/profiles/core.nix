# Shared baseline — imported by every mesh host.
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
