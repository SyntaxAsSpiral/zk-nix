{
  pkgs,
  config,
  inputs,
  ...
}:

let
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hermPackage = builtins.fromJSON (builtins.readFile inputs.herm-tui-npm);
  opentuiNativeRegistry = builtins.fromJSON (builtins.readFile inputs.opentui-core-linux-x64-npm);
  opentuiNativeName = "@opentui/core-linux-x64";
  opentuiNativeVersion = hermPackage.optionalDependencies.${opentuiNativeName};
  opentuiNativePackage = opentuiNativeRegistry.versions.${opentuiNativeVersion};

  hermTarball = pkgs.fetchurl {
    url = hermPackage.dist.tarball;
    hash = hermPackage.dist.integrity;
  };

  opentuiNative =
    assert opentuiNativePackage.name == opentuiNativeName;
    assert opentuiNativePackage.version == opentuiNativeVersion;
    pkgs.fetchurl {
      url = opentuiNativePackage.dist.tarball;
      hash = opentuiNativePackage.dist.integrity;
    };

  herm = pkgs.stdenv.mkDerivation {
    pname = "herm-tui";
    version = hermPackage.version;

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
      hermSite=$("$hermPy" - <<'PY'
import site

print(site.getsitepackages()[0])
PY
)
      makeWrapper ${pkgs.bun}/bin/bun $out/bin/herm \
        --add-flags "$out/lib/herm/index.js" \
        --run 'export HERMES_CWD="''${HERMES_CWD:-$PWD}"' \
        --set HERMES_HOME "${config.home.homeDirectory}/.hermes" \
        --set HERMES_AGENT_ROOT "$hermSite" \
        --set HERMES_BUNDLED_SKILLS "${hermes}/share/hermes-agent/skills" \
        --set HERMES_BUNDLED_PLUGINS "${hermes}/share/hermes-agent/plugins" \
        --set HERMES_WEB_DIST "${hermes}/share/hermes-agent/web_dist" \
        --set HERMES_TUI_DIR "${hermes}/ui-tui" \
        --set HERMES_PYTHON "$hermPy"
      runHook postInstall
    '';
  };
in
{
  home.packages = [ herm ];
}
