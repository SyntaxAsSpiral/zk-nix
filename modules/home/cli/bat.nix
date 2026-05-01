{
  pkgs,
  ...
}:
{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      # other styles available and cane be combined
      #  style = "numbers,changes,headers,rule,grid";
      style = "full";
      # theme managed by catppuccin module
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
      batgrep
    ];
  };
  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
