{
  description = "NixOS configurations for zk mesh";

  # nixarchy's own caches, for quita. Without them a build compiles a compositor.
  # Builds need --accept-flake-config to use them.
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

    # zrrh keeps OpenRGB 1.0rc3.1. 1.0 renamed the addressable header and
    # drops Hypnotoad's saved colors. The rev is in the URL. Replace it, then
    # `nix flake update nixpkgs-openrgb`. Registry: overlays/README.md.
    nixpkgs-openrgb.url = "github:NixOS/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";

    # LLM inference stack (llama-cpp, vllm) with CUDA — deliberately pinned
    # so routine `nix flake update` never rebuilds the CUDA world.
    # The rev is in the URL. Replace it, then `nix flake update nixpkgs-llm`
    # to refresh the lock hash. Registry: overlays/README.md.
    nixpkgs-llm.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fsel = {
      url = "github:Mjoyufull/fsel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    otter-launcher = {
      url = "github:kuokuo123/otter-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    esotericons = {
      url = "github:SyntaxAsSpiral/esotericons";
      flake = false;
    };

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tm20-source = {
      url = "github:bjornpagen/tm20";
      flake = false;
    };

    pia = {
      url = "github:mrehanabbasi/pia.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jolt = {
      url = "github:jordond/jolt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/02ba4db52e62e1fbece80402d369127ae77cbbeb";
      # Do NOT follow nixpkgs — patches are pinned to flake's own nixpkgs
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # quita's trial: Omarchy on NixOS. The release channel follows the newest tagged release.
    nixarchy = {
      url = "github:olafkfreund/nixarchy/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      jovian,
      nixarchy,
      ...
    }:
    let
      system = "x86_64-linux";
      meshOverlays = import ./overlays { inherit inputs; };

      # One host = one line below. Shared wiring (platform, overlays,
      # Home-Manager) lives here; everything host-specific lives in hosts/<name>/.
      mkHost =
        name:
        {
          extraModules ? [ ],
          hostPlatform ? system,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.hostPlatform = hostPlatform;
              nixpkgs.overlays = meshOverlays.hosts.${name};
            }
            ./hosts/${name}/configuration.nix
          ]
          ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                overwriteBackup = true;
                extraSpecialArgs = { inherit inputs; };
                users.zk.imports = [ ./hosts/${name}/home.nix ];
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        nxiz = mkHost "nxiz" { };
        zrrh = mkHost "zrrh" { };
        adeck = mkHost "adeck" { extraModules = [ jovian.nixosModules.default ]; };
        tm20 = mkHost "tm20" { hostPlatform = "aarch64-linux"; };
        seed = mkHost "seed" { };
        quita = mkHost "quita" { extraModules = [ nixarchy.nixosModules.nixarchy ]; };
      };

      # 6. Formatter (nix fmt)
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      # 7. Dev Shell (nix develop)
      devShells.${system}.default =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
          packages = with pkgs; [
            nixd
            nil
            nixfmt
            statix
            deadnix
          ];
        };

      # 8. Lint Checks (nix flake check)
      checks.${system} =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          statix = pkgs.runCommand "statix-check" { buildInputs = [ pkgs.statix ]; } ''
            # hosts/quita/etc-nixos is quita's /etc/nixos kept verbatim, so it is not linted.
            cd ${./.}
            statix check . --ignore 'hosts/quita/etc-nixos/*'
            touch $out
          '';
          deadnix = pkgs.runCommand "deadnix-check" { buildInputs = [ pkgs.deadnix ]; } ''
            cd ${./.}
            deadnix --fail --exclude hosts/quita/etc-nixos/*.nix .
            touch $out
          '';
        };
    };
}
