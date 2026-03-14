{ pkgs, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Turn off display before suspend (critical for NVIDIA)
        before_sleep_cmd = "hyprctl dispatch dpms off";
        # Restore display and clean up after wake
        after_sleep_cmd = "hyprctl dispatch dpms on; pkill -x neo 2>/dev/null; true";
      };
      listener = [
        {
          # 15 min: dim screen to 10%
          timeout = 900;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        {
          # 18 min: turn off display
          timeout = 1080;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          # 20 min: suspend
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
