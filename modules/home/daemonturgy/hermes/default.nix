{
  config,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  hermesPackages = inputs.hermes-agent.packages.${system};
  hermes = hermesPackages.default;
  hermesDesktop = hermesPackages.desktop;
in
{
  home.packages = [
    hermes
    hermesDesktop
  ];

  xdg.desktopEntries.hermes-desktop = {
    name = "Hermes";
    genericName = "AI Agent Desktop";
    comment = "Native desktop shell for Hermes Agent";
    exec = "${hermesDesktop}/bin/hermes-desktop";
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
    Install.WantedBy = [ "default.target" ];
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
    # Loopback bind: --insecure is a no-op since June 2026, and binding
    # 100.89.32.9 without auth crash-loops. Mesh access is tailscale serve.
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${hermes}/bin/hermes dashboard --host 127.0.0.1 --port 9119 --no-open";
      ExecStartPost = "-${pkgs.tailscale}/bin/tailscale serve --bg --https=9119 http://127.0.0.1:9119";
      ExecStopPost = "-${pkgs.tailscale}/bin/tailscale serve --https=9119 off";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "HERMES_HOME=${config.home.homeDirectory}/.hermes"
      ];
    };
  };
}
