_:
{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-2, 2560x1080, 1440x1260, 1"
      "HDMI-A-1, 2560x1440@144.00000, 0x0, 1, transform, 1"
    ];

    input = {
      kb_layout    = "us";
      follow_mouse = 1;
      sensitivity  = 0;
      touchpad = {
        natural_scroll = false;
      };
    };

    device = {
      name        = "epic-mouse-v1";
      sensitivity = -0.5;
    };
  };
}
