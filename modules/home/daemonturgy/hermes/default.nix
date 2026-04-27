{
  config,
  pkgs,
  inputs,
  ...
}:

let
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ hermes ];

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
}
