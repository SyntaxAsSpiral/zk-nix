{ config, pkgs, ... }:

let
  lms = pkgs.buildFHSEnv {
    name = "lms";
    runScript = "${config.home.homeDirectory}/.lmstudio/bin/lms";
    targetPkgs = pkgs: [
      pkgs.gcc.cc.lib  # libgomp (OpenMP runtime for llama.cpp)
    ];
    # CUDA driver libs are at /run/opengl-driver/lib on NixOS.
    # buildFHSEnv mounts /run into the FHS namespace, so llmster
    # finds libcuda.so via the standard /run/opengl-driver path.
  };
in
{
  # LM Studio on zrrh: llmster (CUDA inference node).
  home.activation.ensureLmstudioDirsZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  home.packages = [ lms ];

  home.file.".lmstudio/settings.json".source = ./settings.json;
  home.file.".lmstudio/config-presets".source = ../config-presets;

  # Start llmster daemon on boot
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
}
