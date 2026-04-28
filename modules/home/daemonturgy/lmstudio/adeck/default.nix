{ config, pkgs, ... }:

let
  llmster = pkgs.callPackage ./llmster-bin/package.nix { };
  llmsterManifest = builtins.fromJSON (builtins.readFile ./llmster-bin/manifest.json);
  llmsterRuntimeDir = "${config.home.homeDirectory}/.lmstudio/llmster-nix/${llmsterManifest.version}";
  lms = pkgs.buildFHSEnv {
    name = "lms";
    runScript = "${llmster}/bin/lms";
    targetPkgs = pkgs: [
      pkgs.gcc.cc.lib # libgomp (OpenMP runtime for llama.cpp)
    ];
  };
in
{
  # LM Studio on adeck: llmster only (no GUI/AppImage).
  # Nix manages the llmster artifact; the activation copy gives upstream a
  # writable runtime tree, and the FHS wrapper lets the CLI see Vulkan correctly.
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';
  home.activation.installLlMsterRuntimeAdeck =
    config.lib.dag.entryAfter [ "ensureLmstudioDirsAdeck" ]
      ''
        if [ ! -x "${llmsterRuntimeDir}/llmster" ] || [ "$(<"${llmsterRuntimeDir}/.nix-source" 2>/dev/null || true)" != "${llmster}" ]; then
          mkdir -p "${llmsterRuntimeDir}"
          cp -R "${llmster}/libexec/." "${llmsterRuntimeDir}/"
          chmod -R u+rwX "${llmsterRuntimeDir}"
          printf '%s\n' "${llmster}" > "${llmsterRuntimeDir}/.nix-source"
        fi
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
  home.file.".lmstudio/.internal/llmster-install-location.json" = {
    text = builtins.toJSON {
      path = "${llmsterRuntimeDir}/llmster";
      argv = [ ];
      cwd = llmsterRuntimeDir;
    };
    force = true;
  };

  # Start llmster daemon on boot.
  systemd.user.services.llmster = {
    Unit = {
      Description = "LM Studio daemon (llmster)";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
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
