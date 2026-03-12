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

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
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
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
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

    nullclaw = {
      url = "github:nullclaw/nullclaw";
    };

    zeroclaw = {
      url = "github:zeroclaw-labs/zeroclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
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

  };

  outputs = inputs@{ nixpkgs, home-manager, nix-colors, antigravity-nix, yazi-plugins, jovian, agenix, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.adeck = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = system; }
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
          { nixpkgs.hostPlatform = system;
            nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; }
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
          { nixpkgs.hostPlatform = system;
            nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; }
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

      # Custom graphical installer ISO for zrrh
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, lib, ... }: {
            nixpkgs.hostPlatform = system;
            
            # Use zrrh kernel for compatibility
            boot.kernelPackages = pkgs.linuxPackages_cachyos;
            networking.hostName = "zrrh-installer";
            
            # Put user key in the live image
            users.users.nixos.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
            ];
            
            # Bake the entire flake into the ISO at /flake
            # By copying it at activation, it becomes a writable copy the user can easily install from
            system.activationScripts.bakeFlake = {
              text = ''
                if [ ! -d /flake ]; then
                  cp -r ${./.} /flake
                  chmod -R u+w /flake
                  chown -R nixos:nixos /flake
                fi
              '';
            };

            environment.systemPackages = with pkgs; [
              git
              neovim
              age
              nh
            ];
          })
        ];
      };
    };
}
