_:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [
      {
        layer = "top";
        position = "bottom";
        height = 60;
        spacing = 16;

        modules-left = [ ];

        modules-center = [
          "network"
          "bluetooth"
          "battery"
          "tray"
        ];

        modules-right = [ ];

        network = {
          format-wifi = "󰤨  {signalStrength}%";
          format-ethernet = "󰈀  wired";
          format-disconnected = "󰤮  offline";
          tooltip-format = "{ifname}\n{ipaddr}/{cidr}\n{essid}";
        };

        bluetooth = {
          format = "  {status}";
          format-disabled = "󰂲  disabled";
          format-connected = "  {device_alias}";
          tooltip-format = "{controller_alias}\n{controller_address}";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󰂄  {capacity}%";
          format-plugged = "󰚥  {capacity}%";
          format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
          tooltip-format = "{timeTo}\n{power}W";
        };

        tray = {
          icon-size = 24;
          spacing = 14;
        };

      }
    ];

    style = ''
      * {
        border: none;
        border-radius: 16px;
        min-height: 0;
        font-family: "Recursive Mono Casual", "Symbols Nerd Font Mono";
        font-size: 18px;
      }

      window#waybar {
        background: transparent;
        color: #ECEFF4;
        border: none;
      }

      #network,
      #bluetooth,
      #battery,
      #tray {
        background: rgba(59, 66, 82, 0.8);
        color: #ECEFF4;
        padding: 10px 16px;
        margin: 6px 4px;
        min-width: 52px;
      }

      #network.disconnected,
      #battery.warning,
      #battery.critical {
        color: #F38BA8;
      }
    '';
  };
}
