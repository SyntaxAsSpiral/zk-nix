# tm20-cli from https://github.com/bjornpagen/tm20 — tm20 + tm20-set.
# Only on the tm20 host overlay. Do not install on other mesh boxes.
_final: prev: {
  tm20-cli = prev.rustPlatform.buildRustPackage rec {
    pname = "tm20-cli";
    version = "1.0.0";

    src = prev.fetchFromGitHub {
      owner = "bjornpagen";
      repo = "tm20";
      rev = "2fa493f0b1f3985c3bd552bfd147b452b9ef3166";
      hash = "sha256-Qs3UiBpjoOulQ1lrsZNj/tZKvaOyGBl08lZ6kBYZjx8=";
    };

    cargoLock.lockFile = "${src}/Cargo.lock";

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
