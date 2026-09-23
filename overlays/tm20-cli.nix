# tm20-cli from https://github.com/bjornpagen/tm20 — tm20 + tm20-set.
# Only on the tm20 host overlay. Do not install on other mesh boxes.
{ inputs }:
_final: prev: {
  tm20-cli = prev.rustPlatform.buildRustPackage {
    pname = "tm20-cli";
    version =
      (builtins.fromTOML (builtins.readFile "${inputs.tm20-source}/Cargo.toml"))
      .workspace.package.version;

    src = inputs.tm20-source;

    cargoLock.lockFile = "${inputs.tm20-source}/Cargo.lock";

    cargoBuildFlags = [
      "-p"
      "tm20-cli"
      "--bins"
    ];

    # Device-free tests live in nextest; skip in the appliance closure.
    doCheck = false;

    meta = {
      description = "ESC/POS and Markdown CLI for Epson TM-T20III";
      homepage = "https://github.com/bjornpagen/tm20";
      license = prev.lib.licenses.bsd0;
      mainProgram = "tm20-set";
    };
  };
}
