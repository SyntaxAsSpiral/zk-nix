{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.login.greetd;
in
{
  options.my.login.greetd.enable = lib.mkEnableOption "greetd login manager";

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          user = "zk";
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        };
      };
    };
  };
}
