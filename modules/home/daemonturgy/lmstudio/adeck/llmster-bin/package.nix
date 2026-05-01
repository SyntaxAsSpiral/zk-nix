{
  lib,
  config,
  stdenv,
  fetchurl,
  addDriverRunpath,
  patchelf,
  writeScript,
  appVariant ? "full",
  cudaSupport ? config.cudaSupport or false,
  manifestFile ? ./manifest.json,
}:
let
  manifest = lib.importJSON manifestFile;
  versionParts = lib.splitString "-" manifest.version;
  version = lib.head versionParts;
  build = lib.last versionParts;
  platforms = {
    aarch64-darwin = "darwin-arm64";
    aarch64-linux = "linux-arm64";
    x86_64-linux = "linux-x64";
  };
  platform = platforms.${stdenv.hostPlatform.system};
  variants = [ "full" ];
  # Upstream ships a separate CUDA 12 bundle for linux-x64 (requires NVIDIA driver >= 550.54.14)
  bundleSuffix = lib.optionalString (cudaSupport && platform == "linux-x64") "+cuda12";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "llmster";
  version = "${version}+${build}";

  src = fetchurl {
    url = "https://llmster.lmstudio.ai/download/${version}-${build}-${platform}.${appVariant}${bundleSuffix}.tar.gz";
    sha512 = manifest.checksums."${platform}.${appVariant}${bundleSuffix}";
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  # stdenv.cc.cc provides libstdc++, libatomic, and libgomp (all required at runtime)
  nativeBuildInputs = [ ];
  buildInputs = [ ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec $out/bin
    cp -r llmster .bundle $out/libexec/
    ln -s $out/libexec/llmster $out/bin/llmster
    ln -s $out/libexec/.bundle/lms $out/bin/lms
    runHook postInstall
  '';

  dontFixup = true;

  doInstallCheck = false;

  strictDeps = true;

  passthru.updateScript = writeScript "update-llmster" ''
    #!/usr/bin/env nix-shell
    #!nix-shell --pure -i bash -p curl jq cacert gawk

    set -euo pipefail

    version="$(curl -fsSL "https://lmstudio.ai/install.sh" | awk -F'"' '/^APP_VERSION=/ {print $2; exit}')"
    manifest="$(jq -n --arg v "$version" '{version: $v, checksums: {}}')"

    for platform in ${toString (lib.attrValues platforms)}; do
      for variant in ${toString variants}; do
        if checksum="$(curl -fsSL "https://llmster.lmstudio.ai/download/$version-$platform.$variant.sha512" 2>/dev/null)"; then
          manifest="$(echo "$manifest" | jq --arg p "$platform.$variant" --arg c "$checksum" '.checksums[$p] = $c')"
        fi
        if [ "$platform" = "linux-x64" ]; then
          if checksum="$(curl -fsSL "https://llmster.lmstudio.ai/download/$version-$platform.$variant+cuda12.sha512" 2>/dev/null)"; then
            manifest="$(echo "$manifest" | jq --arg p "$platform.$variant+cuda12" --arg c "$checksum" '.checksums[$p] = $c')"
          fi
        fi
      done
    done

    echo "$manifest" > "${toString manifestFile}"
  '';

  meta = {
    description = "CLI tool for LM Studio - discover, download, and run local LLMs";
    homepage = "https://lmstudio.ai";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ mirkolenz ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "llmster";
    platforms = lib.attrNames platforms;
    hydraPlatforms = [ ];
  };
})
