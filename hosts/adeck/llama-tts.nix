{
  pkgs,
  ...
}:

let
  llama-tts-bin = pkgs.stdenvNoCC.mkDerivation {
    pname = "llama-tts-bin";
    version = "b11077";

    src = pkgs.fetchurl {
      url = "https://github.com/ggml-org/llama.cpp/releases/download/b11077/llama-b11077-bin-ubuntu-vulkan-x64.tar.gz";
      hash = "sha256-4CD6RpvJFuqLZIbooUarx2+s3BedWjHTfc9m6hRqdGk=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.openssl
      pkgs.vulkan-loader
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/libexec/llama-tts
      cp -a llama-tts lib*.so* $out/libexec/llama-tts/
      makeWrapper $out/libexec/llama-tts/llama-tts $out/bin/llama-tts \
        --set GGML_BACKEND_PATH $out/libexec/llama-tts/libggml-vulkan.so

      runHook postInstall
    '';

    meta = {
      description = "Prebuilt llama.cpp TTS tool with Vulkan support";
      homepage = "https://github.com/ggml-org/llama.cpp";
      license = pkgs.lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "llama-tts";
    };
  };
in
{
  environment.systemPackages = [ llama-tts-bin ];
}
