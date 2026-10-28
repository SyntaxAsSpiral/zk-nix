{
  osConfig,
  ...
}:

let
  # tty1 starts the compositor. The config text is shared/home/nushell-config.nix.
  perHost = {
    nxiz.loginFile = ''
      if (tty) == "/dev/tty1" {
        sleep 2sec
        start-hyprland
      }
    '';
    adeck.loginFile = ''
      if (tty) == "/dev/tty1" {
        niri-session
      }
    '';
    zrrh.loginFile = ''
      if (tty) == "/dev/tty1" {
        niri-session
      }
    '';
    seed.loginFile = "";
    tm20.loginFile = "";
  };
in
{
  programs.nushell = {
    enable = true;
    loadSessionVariables = true;
    configFile.text = import ./nushell-config.nix;
    loginFile.text = perHost.${osConfig.my.host}.loginFile;
  };
}
