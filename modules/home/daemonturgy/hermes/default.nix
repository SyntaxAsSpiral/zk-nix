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

  # Mutable symlinks — hermes rewrites its config, so we force link to the repo.
  # The repo is stored at /etc/nixos on adeck.
  home.activation.hermesConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.home.homeDirectory}/.hermes
    ln -sfT /etc/nixos/modules/home/daemonturgy/hermes/config.yaml ${config.home.homeDirectory}/.hermes/config.yaml
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
