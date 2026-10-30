# fzf reads its options from a file, so no escaping rides through an environment variable.
# HM's defaultOptions would write them into FZF_DEFAULT_OPTS, which Nushell's config.nu cannot hold.
{ config, lib, pkgs, ... }:
let
  # The nushell prompt's three arrows, in the ANSI blue, magenta and cyan that follow the terminal palette.
  esc = builtins.fromJSON ''"\u001b"'';
  prompt = "${esc}[34m❱${esc}[35m❱${esc}[36m❱${esc}[0m ";
  options = [
    "--color=16,bg+:-1,pointer:1,info:8,separator:8,scrollbar:0"
    "--padding=1,3"
    "--gutter=' '"
    "--pointer=' ▌'"
    "--layout=reverse"
    "--border=rounded"
    "--cycle"
    "--multi"
    "--info=inline-right"
    "--scheme=path"
    "--prompt='${prompt}'"
    "--preview-window=right,60%,wrap,border-left"
    "--bind='ctrl-/:toggle-preview'"
  ];
in
{
  programs.fzf = {
    enable = true;
    defaultCommand = "${lib.getExe pkgs.fd} --type f --hidden --exclude .git";
  };

  xdg.configFile."fzf/fzf.opts".text = lib.concatLines options;
  home.sessionVariables.FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/fzf.opts";
}
