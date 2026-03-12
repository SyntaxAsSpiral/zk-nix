# msgvault home-manager module
# Archive and query Gmail offline (DuckDB/Parquet + SQLite)
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.msgvault;

  msgvault-pkg = pkgs.buildGoModule rec {
    pname = "msgvault";
    version = "0.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "wesm";
      repo = "msgvault";
      rev = "v${version}";
      hash = lib.fakeHash; # TODO: update with actual hash
    };

    go = pkgs.go_1_25;

    subPackages = [ "cmd/msgvault" ];
    tags = [ "fts5" ];

    CGO_ENABLED = 1;

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.sqlite ];

    ldflags = [
      "-s" "-w"
      "-X" "github.com/wesm/msgvault/cmd/msgvault/cmd.Version=v${version}"
      "-X" "github.com/wesm/msgvault/cmd/msgvault/cmd.Commit=0d91419"
      "-X" "github.com/wesm/msgvault/cmd/msgvault/cmd.BuildDate=1970-01-01T00:00:00Z"
    ];

    vendorHash = lib.fakeHash; # TODO: update with actual hash

    doCheck = false;

    meta = with lib; {
      description = "Archive and query Gmail offline (DuckDB/Parquet + SQLite)";
      homepage = "https://github.com/wesm/msgvault";
      license = licenses.mit;
      mainProgram = "msgvault";
      platforms = platforms.linux;
    };
  };
in
{
  options.programs.msgvault = {
    enable = lib.mkEnableOption "msgvault Gmail archiver";

    package = lib.mkOption {
      type = lib.types.package;
      default = msgvault-pkg;
      description = "The msgvault package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
