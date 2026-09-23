{
  pkgs,
  config,
  inputs,
  ...
}:

let
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  bun2nix = inputs.bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hermSource = inputs.herm-source;
  hermPackage = builtins.fromJSON (builtins.readFile "${hermSource}/package.json");
  releaseLine = builtins.head (builtins.split "\n" (builtins.readFile "${hermSource}/CHANGELOG.md"));
  releaseMatch = builtins.match "# .([0-9]+[.][0-9]+[.][0-9]+).*" releaseLine;
  hermVersion =
    if releaseMatch != null then
      builtins.elemAt releaseMatch 0
    else
      "0-unstable-${builtins.substring 0 8 hermSource.rev}";
  eikonRef = builtins.match "github:([^/]+)/([^#]+)#([0-9a-f]+)" hermPackage.dependencies.eikon;
  eikonRev = builtins.elemAt eikonRef 2;
  opentuiVersion = hermPackage.dependencies."@opentui/core";
  bunNix =
    pkgs.runCommand "herm-bun-nix"
      {
        nativeBuildInputs = [
          bun2nix
          pkgs.nodejs
        ];
      }
      ''
        node - ${hermSource}/bun.lock > bun.lock <<'JS'
        const fs = require("node:fs");
        const lock = JSON.parse(fs.readFileSync(process.argv[2], "utf8").replace(/,\s*([}\]])/g, "$1"));
        delete lock.packages.eikon;
        process.stdout.write(JSON.stringify(lock));
        JS
        mkdir -p $out
        bun2nix -l bun.lock -o $out/packages.nix
        cat > $out/default.nix <<'NIX'
        { copyPathToStore, fetchFromGitHub, fetchgit, fetchurl, runCommand, ... }:
        (import ./packages.nix { inherit copyPathToStore fetchFromGitHub fetchgit fetchurl; }) // {
          "github:${builtins.elemAt eikonRef 0}-${builtins.elemAt eikonRef 1}-${
            builtins.substring 0 7 eikonRev
          }" = runCommand "herm-eikon-source" {
            src = (builtins.fetchTree {
              type = "github";
              owner = "${builtins.elemAt eikonRef 0}";
              repo = "${builtins.elemAt eikonRef 1}";
              rev = "${eikonRev}";
            }).outPath;
          } "mkdir -p $out; cp -r $src/. $out";
        }
        NIX
      '';
  bunDeps = bun2nix.fetchBunDeps { bunNix = "${bunNix}/default.nix"; };

  herm = bun2nix.mkDerivation {
    pname = "herm-tui";
    version = hermVersion;
    src = hermSource;
    inherit bunDeps;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.autoPatchelfHook
      pkgs.jq
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    buildPhase = ''
      runHook preBuild
      jq --arg version ${hermVersion} '.version = $version' package.json > package.tmp
      mv package.tmp package.json
      bun scripts/build.ts
      runHook postBuild
    '';

    installPhase = ''
            runHook preInstall
            mkdir -p $out/lib $out/bin
            cp -r dist $out/lib/herm
            mkdir -p $out/lib/herm/node_modules/@opentui
            cp -rL ${bunDeps}/share/bun-cache/@opentui/core-linux-x64@${opentuiVersion}@@@1 $out/lib/herm/node_modules/@opentui/core-linux-x64
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
