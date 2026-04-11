{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.lmstudio;
  
  # Use steam-run for FHS environment. It is battle-tested.
  # The binaries are managed in ~/.lmstudio/bin/
  lmstudio-pkg = pkgs.runCommand "lmstudio-custom" { 
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p $out/bin
    
    # lms CLI wrapper
    makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/lms \
      --add-flags "/home/zk/.lmstudio/bin/lms"

    # LM Studio GUI wrapper
    makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/lm-studio \
      --add-flags "/home/zk/.lmstudio/bin/LM-Studio.AppImage" \
      --add-flags "--no-sandbox" \
      --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
  '';

in {
  options.my.lmstudio = {
    enable = mkEnableOption "LM Studio";
    headless = mkOption {
      type = types.bool;
      default = false;
      description = "Only install CLI wrapper, no GUI wrapper.";
    };
    daemon = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable llmster daemon (systemd user service).";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ 
      (if cfg.headless then 
        (pkgs.runCommand "lmstudio-cli-only" { } ''
          mkdir -p $out/bin
          ln -s ${lmstudio-pkg}/bin/lms $out/bin/lms
        '')
      else lmstudio-pkg)
    ];

    systemd.user.services.llmster = mkIf cfg.daemon.enable {
      description = "LM Studio daemon (llmster)";
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${lmstudio-pkg}/bin/lms daemon up";
        ExecStop = "${lmstudio-pkg}/bin/lms daemon down";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = "20s";
      };
      wantedBy = [ "default.target" ];
    };
  };
}
