{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "RecMonoCasual Nerd Font Mono";
      size = 11;
    };
    settings = {
      background_opacity = "0.95";
      window_padding_width = "0 7";
      tab_bar_style = "powerline";
      cursor_shape = "underline";
      cursor_underline_thickness = "7.0";
      cursor_trail = 1;
      # cursor set in extraConfig after theme include
      remember_window_size = "no";
      initial_window_width = "90c";
      initial_window_height = "35c";
      scrollback_lines = 10000;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      allow_remote_control = true;
      detect_urls = true;
      shell = "${pkgs.nushell}/bin/nu";
    };
    shellIntegration.enableFishIntegration = true;
    shellIntegration.mode = "enabled";
    extraConfig = ''
      url_prefixes file ftp ftps gemini git gopher http https irc ircs kitty sftp ssh
      include themes.conf
      cursor #74c7ec
      cursor_trail_color #74c7ec
    '';
  };
}
