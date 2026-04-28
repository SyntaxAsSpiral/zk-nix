{ config, pkgs, ... }:

let
  llmster = pkgs.callPackage ./llmster-bin/package.nix { };
  lms = pkgs.buildFHSEnv {
    name = "lms";
    runScript = "${llmster}/bin/lms";
    targetPkgs = pkgs: [
      pkgs.gcc.cc.lib
      pkgs.vulkan-loader
    ];
  };
in
{
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    rm -f "$HOME/.lmstudio/.internal/llmster-pid.lock"
  '';

  home.packages = [ lms ];

  home.file.".lmstudio/settings.json" = {
    source = ./settings.json;
    force = true;
  };
  home.file.".lmstudio/config-presets" = {
    source = ../config-presets;
    force = true;
  };
  home.file.".lmstudio/.internal/http-server-config.json" = {
    source = ./http-server-config.json;
    force = true;
  };

  systemd.user.services.llmster = {
    Unit = {
      Description = "LM Studio daemon (llmster)";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib"
        "HOME=%h"
      ];
      ExecStart = "${llmster}/bin/llmster";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
