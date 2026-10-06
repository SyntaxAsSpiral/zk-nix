# System-level configuration
{ config, lib, ... }:

{
  options.my.host = lib.mkOption {
    type = lib.types.enum [
      "nxiz"
      "adeck"
      "zrrh"
      "tm20"
      "jump"
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
        nxiz = "/etc/nixos";
        adeck = "/etc/nixos";
        zrrh = "/etc/nixos";
        tm20 = "/etc/nixos";
        jump = "/etc/nixos";
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
      builders-use-substitutes = true;
      # CUDA cache left Cachix (cuda-maintainers now 401s). numtide advertises
      # priority 30, which would beat cache.nixos.org — pin it last.
      extra-substituters = [
        "https://cache.nixos-cuda.org"
        "https://jovian-nixos.cachix.org"
        "https://cache.numtide.com?priority=100"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "jovian-nixos.cachix.org-1:mAWLjAxLNgObL1rkdS5zOzYREBSLFLnw4JYWG9l0tEU="
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
