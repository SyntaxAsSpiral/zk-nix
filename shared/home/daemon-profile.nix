{ config, ... }:

let
  daemonProfile = "${config.home.homeDirectory}/.local/state/daemon-profile";
in
{
  home.sessionVariables = {
    DAEMON_PROFILE = daemonProfile;
  };

  # Ensures the daemon's installed tools are immediately executable
  home.sessionPath = [ "${daemonProfile}/bin" ];
}
