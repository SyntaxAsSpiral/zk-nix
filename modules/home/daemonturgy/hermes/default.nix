{
  config,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  hermesInputs = inputs.hermes-agent.inputs;
  hermesDesktopCliPatch = pkgs.writeText "hermes-desktop-use-nix-package.patch" ''
    --- a/hermes_cli/main.py
    +++ b/hermes_cli/main.py
    @@ -7497,6 +7497,26 @@
 
     def cmd_gui(args: argparse.Namespace):
         """Build and launch the native Electron desktop GUI."""
    +    source_mode = getattr(args, "source", False)
    +    nix_desktop = os.environ.get("HERMES_DESKTOP_BIN") or shutil.which("hermes-desktop")
    +    if nix_desktop and not source_mode:
    +        env = os.environ.copy()
    +        if getattr(args, "fake_boot", False):
    +            env["HERMES_DESKTOP_BOOT_FAKE"] = "1"
    +        if getattr(args, "ignore_existing", False):
    +            env["HERMES_DESKTOP_IGNORE_EXISTING"] = "1"
    +        if getattr(args, "hermes_root", None):
    +            env["HERMES_DESKTOP_HERMES_ROOT"] = str(Path(args.hermes_root).expanduser().resolve())
    +        if getattr(args, "cwd", None):
    +            env["HERMES_DESKTOP_CWD"] = str(Path(args.cwd).expanduser().resolve())
    +
    +        if getattr(args, "build_only", False):
    +            print(f"Nix-built Hermes Desktop available: {nix_desktop} (not launching; --build-only)")
    +            return
    +
    +        print(f"Launching Nix-built Hermes Desktop: {nix_desktop}")
    +        launch_result = subprocess.run([nix_desktop], env=env, check=False)
    +        sys.exit(launch_result.returncode)
         desktop_dir = PROJECT_ROOT / "apps" / "desktop"
         if not (desktop_dir / "package.json").exists():
             print(f"Desktop GUI source not found at: {desktop_dir}")
    @@ -7518,7 +7538,6 @@
         if getattr(args, "cwd", None):
             env["HERMES_DESKTOP_CWD"] = str(Path(args.cwd).expanduser().resolve())
 
    -    source_mode = getattr(args, "source", False)
         skip_build = getattr(args, "skip_build", False)
         force_build = getattr(args, "force_build", False)
   '';
  hermesSource = pkgs.applyPatches {
    name = "hermes-agent-desktop-cli-source";
    src = inputs.hermes-agent;
    patches = [ hermesDesktopCliPatch ];
  };
  hermes = pkgs.callPackage (hermesSource + "/nix/hermes-agent.nix") {
    inherit (hermesInputs) uv2nix pyproject-nix pyproject-build-systems;
    npm-lockfile-fix = hermesInputs.npm-lockfile-fix.packages.${system}.default;
    rev = inputs.hermes-agent.rev or null;
  };
  hermesDesktop = hermes.hermesDesktop;
in
{
  home.packages = [
    hermes
    hermesDesktop
  ];

  home.sessionVariables.HERMES_DESKTOP_BIN = "${hermesDesktop}/bin/hermes-desktop";

  xdg.desktopEntries.hermes-desktop = {
    name = "Hermes";
    genericName = "AI Agent Desktop";
    comment = "Native desktop shell for Hermes Agent";
    exec = "${pkgs.coreutils}/bin/env HERMES_DESKTOP_BIN=${hermesDesktop}/bin/hermes-desktop ${hermes}/bin/hermes desktop";
    icon = "${hermesDesktop}/share/hermes-desktop/dist/hermes.png";
    terminal = false;
    type = "Application";
    categories = [
      "Development"
      "Utility"
    ];
  };

  # Keep SOUL.md declarative, but leave config.yaml mutable.
  # modules/home/daemonturgy/hermes/config.yaml is only a snapshot copy.
  home.activation.hermesConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.home.homeDirectory}/.hermes
    ln -sfT /etc/nixos/modules/home/daemonturgy/hermes/SOUL.md ${config.home.homeDirectory}/.hermes/SOUL.md
  '';

  systemd.user.services.hermes-gateway = {
    Unit = {
      Description = "Hermes Agent messaging gateway";
      After = [ "llmster.service" ];
      Wants = [ "llmster.service" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${hermes}/bin/hermes gateway run --replace --accept-hooks";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "HERMES_HOME=${config.home.homeDirectory}/.hermes"
        "HERMES_ACCEPT_HOOKS=1"
      ];
    };
  };

  systemd.user.services.hermes-dashboard = {
    Unit = {
      Description = "Hermes Agent web dashboard";
      After = [ "hermes-gateway.service" ];
      Wants = [ "hermes-gateway.service" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${hermes}/bin/hermes dashboard --host 100.89.32.9 --port 9119 --no-open --insecure";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "HERMES_HOME=${config.home.homeDirectory}/.hermes"
      ];
    };
  };
}
