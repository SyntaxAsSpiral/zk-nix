# Git configuration
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git-lfs
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null; # Silence HM deprecation warning
    settings = {
      user.name = "Zach Battin";
      user.email = "zach@example.com";
      init.defaultBranch = "main";
      core = {
        autocrlf = "input";
        editor = "nvim"; # follows $EDITOR convention
      };

      # Workflow
      push.default = "simple";
      push.autoSetupRemote = true;
      pull.rebase = false;

      # Diffs & Merge
      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";

      # Logging
      log.date = "iso";
      log.decorate = "full";

      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch --sort=-committerdate"; # Sort by recent
        ci = "commit";
        df = "diff";
        gp = "pull";
        gs = "stash";
        # Pretty log with graph, colors, relative dates
        lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
        last = "log -1 HEAD";
      };
    };
  };
}
