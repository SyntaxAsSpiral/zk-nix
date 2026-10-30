# Pick a process: preview its command and children, keys to terminate or kill.
# Usage: otter-ps                 start the picker
#        otter-ps --list          process lines, busiest first (fzf reload)
#        otter-ps --preview pid   full command and children for one process (fzf preview)
case "${1:-}" in
  --list)
    ps -ww -eo pid,user,%cpu,%mem,etime,args --sort=-%cpu
    exit 0
    ;;
  --preview)
    tr '\0' ' ' < "/proc/$2/cmdline" 2> /dev/null
    printf '\n\n'
    ps -ww --forest -o pid,user,etime,args --ppid "$2" 2> /dev/null
    exit 0
    ;;
esac

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
otter-ps --list | fzf --header-lines 1 --header 'enter terminate  ctrl-k kill -9  ctrl-r refresh (both ask first)' \
  --info-command 'printf " processes ($FZF_POS/$FZF_TOTAL_COUNT)"' \
  --preview 'otter-ps --preview {1}' --preview-window 'down,40%,wrap' \
  --bind 'enter:execute(gum confirm "Terminate {1}?" && { kill {1} || sudo kill {1}; })+reload(otter-ps --list)' \
  --bind 'ctrl-k:execute(gum confirm "Kill -9 {1}?" && { kill -9 {1} || sudo kill -9 {1}; })+reload(otter-ps --list)' \
  --bind 'ctrl-r:reload(otter-ps --list)' > /dev/null
