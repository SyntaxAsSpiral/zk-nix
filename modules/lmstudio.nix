{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.lmstudio;

  # Downloads the dedicated llmster CLI tarball (llmster.lmstudio.ai), NOT the AppImage.
  #
  # Why not pkgs.lmstudio? It extracts lms from the AppImage and runs autoPatchelfHook,
  # which uses patchelf --set-rpath. Bun-compiled binaries (lms, llmster, node) embed
  # runtime data AFTER their ELF sections. Rearranging ELF sections to grow .dynamic/.dynstr
  # shifts that appended data → SIGSEGV. This approach only patches the interpreter
  # and injects library paths via LD_LIBRARY_PATH wrapper, which is safe.
  #
  # Derivation pattern from: https://github.com/mirkolenz/nixos/tree/main/pkgs/derivations/llmster-bin
  llmster-pkg = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "llmster";
    version = "0.0.11+1";

    src = pkgs.fetchurl {
      url = "https://llmster.lmstudio.ai/download/0.0.11-1-linux-x64.full.tar.gz";
      sha512 = "2bf718f5c02884987e97fcf9febf33f8ffc80b83deea2f62f90fc5fa17db55e17e22a30cfa0ca31c534d8e235c6ce4d7fa49ec7e8c5447d05153b05ff7a9fe27";
    };

    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    buildInputs = [
      pkgs.stdenv.cc.cc
      pkgs.libxcrypt-legacy
    ];

    nativeBuildInputs = [
      pkgs.makeBinaryWrapper
      pkgs.addDriverRunpath
      pkgs.patchelf
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec $out/bin
      mv llmster .bundle $out/libexec/
      makeWrapper $out/libexec/llmster $out/bin/llmster
      makeWrapper $out/libexec/llmster $out/bin/lms
      runHook postInstall
    '';

    # Only patch the interpreter on ELF executables — never --add-rpath / --set-rpath.
    # Libraries injected via LD_LIBRARY_PATH wrapper instead (safe for Bun binaries).
    # .so / .node files are standard ELF without appended data, so rpath patching is safe there.
    postFixup = ''
      local interpreter="$(cat $NIX_CC/nix-support/dynamic-linker)"
      local rpath="${lib.makeLibraryPath (finalAttrs.buildInputs ++ [ pkgs.addDriverRunpath.driverLink ])}"
      find $out/libexec -type f \( -executable -o -name '*.so' -o -name '*.so.*' -o -name '*.node' \) | while read -r file; do
        if patchelf --print-interpreter "$file" &>/dev/null; then
          patchelf --set-interpreter "$interpreter" "$file"
          wrapProgram "$file" \
            --prefix LD_LIBRARY_PATH : "$rpath"
        elif patchelf --print-rpath "$file" &>/dev/null; then
          patchelf --add-rpath "$rpath" "$file"
        fi
      done
    '';

    meta = {
      description = "CLI tool for LM Studio - discover, download, and run local LLMs";
      homepage = "https://lmstudio.ai";
      license = lib.licenses.unfree;
      mainProgram = "llmster";
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    };
  });

in {
  options.my.lmstudio = {
    enable = mkEnableOption "LM Studio";
    headless = mkOption {
      type = types.bool;
      default = false;
      description = "Only install CLI (llmster/lms), no GUI.";
    };
    daemon = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable llmster daemon.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      [ llmster-pkg ]
      ++ optional (!cfg.headless) pkgs.lmstudio;

    systemd.user.services.llmster = mkIf cfg.daemon.enable {
      description = "LM Studio daemon (llmster)";
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${llmster-pkg}/bin/lms daemon up";
        ExecStop = "${llmster-pkg}/bin/lms daemon down";
        Restart = "on-failure";
        RestartSec = 5;
      };
      wantedBy = [ "default.target" ];
    };
  };
}
