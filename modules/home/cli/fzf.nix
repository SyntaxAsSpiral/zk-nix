# Fzf is a general-purpose command-line fuzzy finder.
{
  lib,
  ...
}:
let
  # Catppuccin Frappe colors (manual)
  accent = "#8caaee"; # blue
  foreground = "#c6d0f5"; # text
  muted = "#737994"; # overlay0
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = lib.mkForce {
      "fg+" = accent;
      "bg+" = "-1";
      "fg" = foreground;
      "bg" = "-1";
      "prompt" = muted;
      "pointer" = accent;
    };
    defaultOptions = [
      "--margin=1"
      "--layout=reverse"
      "--border=none"
      "--info='hidden'"
      "--header=''"
      "--prompt='/ '"
      "-i"
      "--no-bold"
      "--bind='enter:execute(nvim {})'"
      "--preview='bat --style=numbers --color=always --line-range :500 {}'"
      "--preview-window=right:60%:wrap"
    ];
  };
}
