# msgvault home-manager module
# Archive and query email + messaging offline (DuckDB/Parquet + SQLite FTS5)
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.msgvault;

  msgvault-pkg = pkgs.buildGoModule rec {
    pname = "msgvault";
    version = "0.9.0";

    src = pkgs.fetchFromGitHub {
      owner = "wesm";
      repo = "msgvault";
      rev = "v${version}";
      hash = "sha256-6oSXZ9yTQEXdJxiQ9OkpWK/wqjZpLwMC4+3/1yv6Eu8=";
    };

    # nixpkgs removed go_1_25. buildGoModule uses the current toolchain.
    proxyVendor = true;
    subPackages = [ "cmd/msgvault" ];
    tags = [ "fts5" ];

    ldflags = [
      "-s" "-w"
      "-X" "github.com/wesm/msgvault/cmd/msgvault/cmd.Version=v${version}"
    ];

    vendorHash = "sha256-XgtHKRLqNX7LCI22Ls3LQjEs+jX7EwapiiFs7I+gtRE=";

    doCheck = false;

    meta = with lib; {
      description = "Archive and query email + messaging offline (DuckDB/Parquet + SQLite FTS5)";
      homepage = "https://github.com/wesm/msgvault";
      license = licenses.mit;
      mainProgram = "msgvault";
      platforms = platforms.linux;
    };
  };
in
{
  options.programs.msgvault = {
    enable = lib.mkEnableOption "msgvault archiver";

    home = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/vault/@staging/msgvault";
      description = "MSGVAULT_HOME directory";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = msgvault-pkg;
      description = "The msgvault package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = {
      MSGVAULT_HOME = cfg.home;
    };
  };
}
