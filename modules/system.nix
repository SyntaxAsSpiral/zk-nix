# System-level configuration
{ lib, ... }:

{
  options.my.host = lib.mkOption {
    type = lib.types.enum [
      "nxiz"
      "adeck"
      "zrrh"
    ];
    description = "Host identifier — selects per-host blocks in shared modules";
  };

  config = {
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
    };
    nix.extraOptions = ''
      !include /etc/nixos/secrets/nix-access-tokens.conf
    '';
    nixpkgs.config.allowUnfree = true;

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

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
