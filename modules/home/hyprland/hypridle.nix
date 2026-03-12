{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "pkill -x neo 2>/dev/null; true";
      };
      listener = [
        {
          # 20 min: suspend
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
