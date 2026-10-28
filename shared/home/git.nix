{ pkgs, ... }:
let
  ghHelper = "!${pkgs.gh}/bin/gh auth git-credential";
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Z⟁ch";
        email = "SyntaxAsSpiral@gmail.com";
      };
      init.defaultBranch = "trunk";
      pull.ff = "only";
      push.autoSetupRemote = true;
      fetch.prune = true;
      merge.conflictStyle = "zdiff3";
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };
      credential = {
        "https://github.com".helper = ghHelper;
        "https://gist.github.com".helper = ghHelper;
      };
    };
    ignores = [ "**/.claude/settings.local.json" ];
  };
}
