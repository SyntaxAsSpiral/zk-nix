# Git configuration
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git-lfs
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
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

      # Keep GH credential helper stable across nix-store path churn.
      credential = {
        "https://github.com".helper = "!/etc/profiles/per-user/zk/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!/etc/profiles/per-user/zk/bin/gh auth git-credential";
      };

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
