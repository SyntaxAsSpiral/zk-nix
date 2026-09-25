{ config, pkgs, ... }:

let
  lms = pkgs.buildFHSEnv {
    name = "lms";
    runScript = "${config.home.homeDirectory}/.lmstudio/bin/lms";
    targetPkgs = pkgs: [
      pkgs.gcc.cc.lib # libgomp (OpenMP runtime for llama.cpp)
    ];
  };
in
{
  imports = [ ../log-retention.nix ];

  # LM Studio on adeck: llmster only (no GUI/AppImage).
  # Installed via `curl` — Nix manages dirs, settings, and server config.
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
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
  home.file.".lmstudio/.internal/user-concrete-model-default-config/lmstudio-community/granite-4.0-h-tiny-GGUF/granite-4.0-h-tiny-Q4_K_M.gguf.json" = {
    source = ./user-concrete-model-default-config/lmstudio-community/granite-4.0-h-tiny-GGUF/granite-4.0-h-tiny-Q4_K_M.gguf.json;
    force = true;
  };

  # Start llmster daemon on boot.
  systemd.user.services.llmster = {
    Unit = {
      Description = "LM Studio daemon (llmster)";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "forking";
      ExecStart = "${lms}/bin/lms daemon up";
      ExecStop = "${lms}/bin/lms daemon down";
      TimeoutStopSec = "20s";
      KillMode = "control-group";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Keep the public API stable; gate inference on the router-LAN WoL relay.
  systemd.user.services.inference-wake = {
    Unit = {
      Description = "Wake zrrh before local inference";
      After = [ "network-online.target" "llmster.service" ];
      Requires = [ "llmster.service" ];
    };
    Service = {
      ExecStart = "${pkgs.python3.withPackages (p: [ p.aiohttp ])}/bin/python ${./inference-wake.py}";
      Environment = [ "LMS=${lms}/bin/lms" ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
