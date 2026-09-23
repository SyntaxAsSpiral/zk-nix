{
  description = "NixOS configurations for zk mesh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nxiz keeps Hyprland 0.56.2 while its configuration is still hyprlang.
    nixpkgs-hyprland.url = "github:NixOS/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";

    nixpkgs-sonic-pi.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";

    # LLM inference stack (llama-cpp, vllm) with CUDA — deliberately pinned
    # so routine `nix flake update` never rebuilds the CUDA world.
    # Bump explicitly with: nix flake update nixpkgs-llm
    nixpkgs-llm.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors = {
      url = "github:misterio77/nix-colors";
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

    noctalia = {
      url = "github:noctalia-dev/noctalia/v4.7.7";
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
      url = "github:xddxdd/nix-cachyos-kernel/26da04e24aef2993ea256917be42d18f83ce8e8b";
      # Do NOT follow nixpkgs — patches are pinned to flake's own nixpkgs
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };

    herm-source = {
      url = "github:liftaris/herm/main";
      flake = false;
    };

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nix-colors,
      jovian,
      agenix,
      ...
    }:
    let
      system = "x86_64-linux";
      meshOverlays = import ./overlays { inherit inputs; };

      # One host = one line below. Shared wiring (platform, overlays, agenix,
      # Home-Manager) lives here; everything host-specific lives in hosts/<name>/.
      mkHost =
        name:
        {
          extraModules ? [ ],
          hostPlatform ? system,
          homeManager ? true,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.hostPlatform = hostPlatform;
              nixpkgs.overlays = meshOverlays.hosts.${name};
            }
            ./hosts/${name}/configuration.nix
            agenix.nixosModules.default
          ]
          ++ nixpkgs.lib.optionals homeManager [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                overwriteBackup = true;
                extraSpecialArgs = { inherit inputs; };
                users.zk.imports = [
                  nix-colors.homeManagerModules.default
                  agenix.homeManagerModules.default
                  ./hosts/${name}/home.nix
                ];
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
        tm20 = mkHost "tm20" {
          hostPlatform = "aarch64-linux";
          homeManager = false;
        };
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
            statix check ${./.}
            touch $out
          '';
          deadnix = pkgs.runCommand "deadnix-check" { buildInputs = [ pkgs.deadnix ]; } ''
            deadnix --fail ${./.}
            touch $out
          '';
        };
    };
}
