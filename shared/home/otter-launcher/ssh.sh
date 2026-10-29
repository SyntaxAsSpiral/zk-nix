# Pick one of your own tailnet hosts and ssh in as zk. Online hosts come first.
# Usage: otter-ssh [host]   a host name or address skips the picker
# A name is looked up in tailscale and connected by address, so it works without MagicDNS.
if [ -n "${1:-}" ]; then
  addr=$(tailscale status --json 2> /dev/null |
    jq -r --arg h "$1" '
      [.Self, (.Peer | to_entries[].value)]
      | map(select((.HostName | ascii_downcase) == ($h | ascii_downcase)))
      | .[0].TailscaleIPs[0] // empty')
  exec ssh "zk@${addr:-$1}"
fi

export FZF_DEFAULT_OPTS="--reverse --padding 1,3 --cycle --gutter ' ' --pointer ' ▌' --color 'bg+:-1,pointer:1,info:8,separator:8,scrollbar:0'"
esc=$'\e'
# fzf expands the single-quoted info command, not the shell
# shellcheck disable=SC2016
sel=$(tailscale status --json 2> /dev/null |
  jq -r --arg on "${esc}[32m●${esc}[0m" --arg off "${esc}[90m○${esc}[0m" '
    .Self.UserID as $u
    | [.Self, (.Peer | to_entries[].value)]
    | map(select(.UserID == $u and .OS == "linux"))
    | sort_by(.Online | not)
    | .[]
    | [.TailscaleIPs[0], "\(if .Online then $on else $off end) \(.HostName)", .TailscaleIPs[0], .OS] | @tsv' |
  fzf --ansi --delimiter '\t' --with-nth 2.. --prompt '❱ ' \
    --info-command 'printf " hosts ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --header 'enter ssh' --no-preview) || exit 0
exec ssh "zk@${sel%%$'\t'*}"
