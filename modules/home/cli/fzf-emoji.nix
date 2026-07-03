# Emoji picker (fzf + Wayland clipboard, no rofi)
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "fzf-emoji";
      runtimeInputs = with pkgs; [
        fzf
        jq
        wl-clipboard
        curl
        coreutils
      ];
      text = ''
        set -euo pipefail

        data_url="https://raw.githubusercontent.com/github/gemoji/0eca75db9301421efc8710baf7a7576793ae452a/db/emoji.json"
        cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/fzf-emoji"
        data_file="$cache_dir/emoji.json"

        mkdir -p "$cache_dir"
        if [ ! -s "$data_file" ]; then
          curl -fsSL "$data_url" -o "$data_file"
        fi

        jq -r '.[] | (.emoji + " :" + .aliases[0] + ": " + .category + " » " + .description)' "$data_file" |
          fzf \
            --delimiter ' ' \
            --layout=reverse \
            --prompt 'emoji> ' \
            --bind 'enter:become(printf {1} | wl-copy --trim-newline)' \
            --bind 'ctrl-y:become(printf {2} | wl-copy --trim-newline)'
      '';
    })
  ];
}
