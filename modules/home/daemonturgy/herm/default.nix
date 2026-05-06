{
  pkgs,
  config,
  inputs,
  ...
}:

let
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hermVersion = "1.2.1";
  opentuiVersion = "0.2.2";

  hermTarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/herm-tui/-/herm-tui-${hermVersion}.tgz";
    hash = "sha512-lJm6VFvYJfvxbBKG1b53Mh9sEU6bioRgSSBa+ztu7zGOWvpfsax4QSvNayc9EnUAPZvRnApFtc+dlfBiQS19kA==";
  };

  opentuiNative = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opentui/core-linux-x64/-/core-linux-x64-${opentuiVersion}.tgz";
    hash = "sha512-ucVwUtUYeOYGVFPBLbPoxzbrPdhD0PDyKNQ2X4n1AJ9jlQX4gqBZRcXMEF8hiXDjFxsikZwef7De0ciCcWvAMg==";
  };

  herm = pkgs.stdenv.mkDerivation {
    pname = "herm-tui";
    version = hermVersion;

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    buildPhase = ''
      runHook preBuild
      mkdir -p pkg/node_modules/@opentui/core-linux-x64
      tar -xzf ${hermTarball} -C pkg --strip-components=1
      tar -xzf ${opentuiNative} -C pkg/node_modules/@opentui/core-linux-x64 --strip-components=1
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      cp -r pkg $out/lib/herm
      hermPy=$(grep -oP "(?<=HERMES_PYTHON=')[^']+" ${hermes}/bin/hermes)
      makeWrapper ${pkgs.bun}/bin/bun $out/bin/herm \
        --add-flags "$out/lib/herm/index.js" \
        --set HERMES_HOME "${config.home.homeDirectory}/.hermes" \
        --set HERMES_PYTHON "$hermPy"
      runHook postInstall
    '';
  };
in
{
  home.packages = [ herm ];
}
