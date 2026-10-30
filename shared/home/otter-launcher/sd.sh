# Pick a systemd unit: preview its status and recent journal, keys to restart, stop or follow.
# Usage: otter-sd                 start the picker
#        otter-sd --list          unit lines (fzf reload)
#        otter-sd --preview unit  status and journal for one unit (fzf preview)
case "${1:-}" in
  --list)
    systemctl list-units --all --plain --no-legend --no-pager | tac
    exit 0
    ;;
  --preview)
    SYSTEMD_COLORS=1 systemctl status --no-pager -n 20 "$2" 2>&1
    exit 0
    ;;
esac

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
otter-sd --list | fzf --ansi --header 'enter follow logs  ctrl-r restart  ctrl-x stop (both ask first)' \
  --info-command 'printf " units ($FZF_POS/$FZF_TOTAL_COUNT)"' \
  --preview 'otter-sd --preview {1}' --preview-window 'right,60%,wrap' \
  --bind 'enter:execute(journalctl -u {1} -f -n 100)' \
  --bind 'ctrl-r:execute(gum confirm "Restart {1}?" && sudo systemctl restart {1})+reload(otter-sd --list)' \
  --bind 'ctrl-x:execute(gum confirm "Stop {1}?" && sudo systemctl stop {1})+reload(otter-sd --list)' > /dev/null
