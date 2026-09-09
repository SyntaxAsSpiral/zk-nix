# System-level configuration
{ config, lib, ... }:

{
  options.my.host = lib.mkOption {
    type = lib.types.enum [
      "nxiz"
      "adeck"
      "zrrh"
    ];
    description = "Host identifier — selects per-host blocks in shared modules";
  };

  options.my.flakePath = lib.mkOption {
    type = lib.types.str;
    description = "Where this flake lives on the host — single source of truth for nh and zcli";
  };

  config = {
    my.flakePath =
      {
        nxiz = "/mnt/repository/nix-os";
        adeck = "/etc/nixos";
        zrrh = "/etc/nixos";
      }
      .${config.my.host};

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "zk"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://cuda-maintainers.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    nix.extraOptions = ''
      !include /etc/nixos/secrets/nix-access-tokens.conf
    '';
    # crates.io/Fastly 403s User-Agents that start with "curl/".
    # nixpkgs fetchurl sends "curl/$version Nixpkgs/$version"; last --user-agent wins.
    systemd.services.nix-daemon.environment.NIX_CURL_FLAGS = "--user-agent Nixpkgs";
    nixpkgs.config.allowUnfree = true;

    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    console.keyMap = "us";
  };
}
