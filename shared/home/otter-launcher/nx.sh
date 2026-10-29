# Search nixpkgs as you type: fzf over nh search, enter opens nix shell with the package.
# Usage: otter-nx [query]         start the picker, optionally with a first query
#        otter-nx --list query    package lines, best match first (fzf reload)
#        otter-nx --preview name  the details nh prints for one package (fzf preview)
strip() { sed 's/\x1b\[[0-9;]*m//g'; }

case "${1:-}" in
  --list)
    [ -n "${2:-}" ] || exit 0
    nh search packages "$2" --limit 50 2> /dev/null | strip |
      awk 'NF && !/^[ \t]/ && !/^(Querying|Took|Most relevant)/' | tac
    exit 0
    ;;
  --preview)
    nh search packages "$2" --limit 10 2> /dev/null | strip |
      awk -v n="$2" 'BEGIN { RS = ""; FS = "\n" } index($1, n " (") == 1 { print; exit }'
    exit 0
    ;;
esac

export FZF_DEFAULT_OPTS="--reverse --padding 1,3 --cycle --gutter ' ' --pointer ' ▌' --color 'bg+:-1,pointer:1,info:8,separator:8,scrollbar:0'"
# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
sel=$(otter-nx --list "${1:-}" | fzf --disabled --query "${1:-}" --prompt '❱ ' \
  --delimiter ' ' --with-nth 1.. \
  --header 'type to search nixpkgs, enter nix shell' \
  --info-command 'printf " packages ($FZF_POS/$FZF_TOTAL_COUNT)"' \
  --bind 'change:reload:otter-nx --list {q}' \
  --preview 'otter-nx --preview {1}' --preview-window 'right,55%,wrap') || exit 0
exec nix shell "nixpkgs#${sel%% *}"
