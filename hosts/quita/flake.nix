# quita: bare NixOS plus nixarchy, the nixarchy way (their README, "On NixOS you already run").
# No fleet flake yet. Flakes only see tracked files, so `git add` anything new here.
{
  # The same caches nixarchy's own flake declares. Without them the first rebuild
  # compiles a compositor. Needs --accept-flake-config on that first rebuild.
  nixConfig = {
    extra-substituters = [
      "https://nixarchy.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixarchy.cachix.org-1:05JOuIlsQOWY2/5DQMq7JEA1hwlhgvmMWowMfka8mMM="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixarchy = {
      url = "github:olafkfreund/nixarchy/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nixarchy, ... }:
    {
      nixosConfigurations.quita = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nixarchy; };
        modules = [
          nixarchy.nixosModules.nixarchy
          nixarchy.inputs.home-manager.nixosModules.home-manager
          ./configuration.nix
          ./nixarchy-apps.nix
        ];
      };
    };
}
