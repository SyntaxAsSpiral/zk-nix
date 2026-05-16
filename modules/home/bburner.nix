# Bitburner — self-hosted hacking idle game served as a static web app
# Builds from source via buildNpmPackage, served by miniserve on port 8090
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.bburner;

  bburner-pkg = pkgs.buildNpmPackage {
    pname = "bitburner";
    version = "3.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "bitburner-official";
      repo = "bitburner-src";
      rev = "v3.0.0";
      hash = "sha256-unznH3H817eLEy5RMMYQEIVoH+wNUUZrR5nwV+e16ro=";
    };

    nodejs = pkgs.nodejs_24;

    npmDepsHash = "sha256-axFi78uXqEzon0wsUL0AuKQHvcvkyZhD3kOVMzv+P9c=";

    nativeBuildInputs = [ pkgs.git ];

    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    buildPhase = ''
      git init
      git config user.email "nix@build"
      git config user.name "nix"
      git commit --allow-empty -m "nix" --no-gpg-sign
      npm run build
    '';

    installPhase = ''
      mkdir -p $out
      cp index.html $out/
      cp -r dist $out/dist
    '';

    meta = with lib; {
      description = "Bitburner — a cyberpunk hacking idle game";
      homepage = "https://github.com/bitburner-official/bitburner-src";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
in
{
  options.programs.bburner = {
    enable = lib.mkEnableOption "Bitburner web app";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port to serve Bitburner on";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.miniserve ];

    systemd.user.services.bburner = {
      Unit = {
        Description = "Bitburner web app";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${pkgs.miniserve}/bin/miniserve --port ${toString cfg.port} --index index.html ${bburner-pkg}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
