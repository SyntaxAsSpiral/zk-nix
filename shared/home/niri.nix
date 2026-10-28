# Niri compositor config, declared per host. Each host's KDL sits in its desk-env/.
{ osConfig, ... }:

let
  perHost = {
    adeck = ../../hosts/adeck/desk-env/niri-adeck-config.kdl;
    zrrh = ../../hosts/zrrh/desk-env/niri-zrrh-config.kdl;
  };
in
{
  xdg.configFile."niri/config.kdl".source = perHost.${osConfig.my.host};
}
