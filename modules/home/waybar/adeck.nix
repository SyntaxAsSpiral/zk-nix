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
          "custom/netmgr"
          "custom/btmgr"
          "custom/powermgr"
          "network"
          "bluetooth"
          "battery"
          "tray"
        ];

        modules-right = [ ];

        "custom/netmgr" = {
          format = "{}";
          return-type = "json";
          interval = 10;
          exec = ''
            sh -c '
              state="$(systemctl is-active NetworkManager.service 2>/dev/null || true)"
              if [ "$state" = "active" ]; then
                echo "{\"text\":\"󰛳 NM\",\"class\":\"ok\",\"tooltip\":\"NetworkManager: active\"}"
              else
                echo "{\"text\":\"󰲛 NM\",\"class\":\"warn\",\"tooltip\":\"NetworkManager: $state\"}"
              fi
            '
          '';
          on-click = "alacritty -e sh -lc 'systemctl status NetworkManager.service --no-pager'";
          on-click-right = "alacritty -e nmtui";
        };

        "custom/btmgr" = {
          format = "{}";
          return-type = "json";
          interval = 10;
          exec = ''
            sh -c '
              state="$(systemctl is-active bluetooth.service 2>/dev/null || true)"
              if [ "$state" = "active" ]; then
                echo "{\"text\":\" BT\",\"class\":\"ok\",\"tooltip\":\"bluetooth.service: active\"}"
              else
                echo "{\"text\":\"󰂲 BT\",\"class\":\"warn\",\"tooltip\":\"bluetooth.service: $state\"}"
              fi
            '
          '';
          on-click = "alacritty -e sh -lc 'systemctl status bluetooth.service --no-pager'";
        };

        "custom/powermgr" = {
          format = "{}";
          return-type = "json";
          interval = 10;
          exec = ''
            sh -c '
              up="$(systemctl is-active upower.service 2>/dev/null || true)"
              ppd="$(systemctl is-active power-profiles-daemon.service 2>/dev/null || true)"
              if [ "$up" = "active" ] && [ "$ppd" = "active" ]; then
                echo "{\"text\":\" PWR\",\"class\":\"ok\",\"tooltip\":\"upower: active\\npower-profiles-daemon: active\"}"
              else
                echo "{\"text\":\" PWR\",\"class\":\"warn\",\"tooltip\":\"upower: $up\\npower-profiles-daemon: $ppd\"}"
              fi
            '
          '';
          on-click = "alacritty -e sh -lc 'systemctl status upower.service power-profiles-daemon.service --no-pager'";
        };

        network = {
          format-wifi = "󰤨  {signalStrength}%";
          format-ethernet = "󰈀  wired";
          format-disconnected = "󰤮  offline";
          tooltip-format = "{ifname}\n{ipaddr}/{cidr}\n{essid}";
          on-click = "alacritty -e nmtui";
        };

        bluetooth = {
          format = "  {status}";
          format-disabled = "󰂲  disabled";
          format-connected = "  {device_alias}";
          tooltip-format = "{controller_alias}\n{controller_address}";
          on-click = "alacritty -e sh -lc 'bluetoothctl devices Connected; echo; bluetoothctl show'";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󰂄  {capacity}%";
          format-plugged = "󰚥  {capacity}%";
          format-icons = [
            "󰁺"
            "󰁼"
            "󰁾"
            "󰂀"
            "󰁹"
          ];
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

      #custom-netmgr,
      #custom-btmgr,
      #custom-powermgr,
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

      #custom-netmgr,
      #custom-btmgr,
      #custom-powermgr {
        background: rgba(67, 76, 94, 0.8);
        color: #D8DEE9;
      }

      #custom-netmgr.ok,
      #custom-btmgr.ok,
      #custom-powermgr.ok {
        color: #A6E3A1;
      }

      #custom-netmgr.warn,
      #custom-btmgr.warn,
      #custom-powermgr.warn,
      #network.disconnected,
      #battery.warning,
      #battery.critical {
        color: #F38BA8;
      }

      #workspaces button:hover,
      #custom-netmgr:hover,
      #custom-btmgr:hover,
      #custom-powermgr:hover,
      #network:hover,
      #bluetooth:hover,
      #battery:hover,
      #tray:hover {
        background: #4C566A;
      }
    '';
  };
}
