{
  description = "NixOS configurations for zk mesh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors = {
      url = "github:misterio77/nix-colors";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
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

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
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

    kaleidux = {
      url = "github:Mjoyufull/Kaleidux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };

    herm-tui-npm = {
      url = "file+https://registry.npmjs.org/herm-tui/latest";
      flake = false;
    };

    opentui-core-linux-x64-npm = {
      url = "file+https://registry.npmjs.org/@opentui%2fcore-linux-x64";
      flake = false;
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
    in
    {
      nixosConfigurations.adeck = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.overlays = [ inputs.llm-agents.overlays.default ];
          }
          ./hosts/adeck/configuration.nix
          jovian.nixosModules.default
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.overwriteBackup = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zk = {
              imports = [
                nix-colors.homeManagerModules.default
                agenix.homeManagerModules.default
                ./hosts/adeck/home.nix
              ];
            };
          }
        ];
      };

      nixosConfigurations.nxiz = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
          }
          ./hosts/nxiz/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.overwriteBackup = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.zk = {
              imports = [
                nix-colors.homeManagerModules.default
                agenix.homeManagerModules.default
                ./hosts/nxiz/home.nix
              ];
            };
          }
        ];
      };

      nixosConfigurations.zrrh = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.overlays = [
              inputs.nix-cachyos-kernel.overlays.pinned
              inputs.llm-agents.overlays.default
            ];
          }
          ./hosts/zrrh/configuration.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.overwriteBackup = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.zk = {
              imports = [
                nix-colors.homeManagerModules.default
                agenix.homeManagerModules.default
                ./hosts/zrrh/home.nix
              ];
            };
          }
        ];
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
