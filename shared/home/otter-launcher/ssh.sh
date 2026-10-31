# Pick one of your own tailnet hosts and ssh in as zk. Online hosts come first.
# Usage: otter-ssh [host]   a host name or address skips the picker
# A name is looked up in tailscale and connected by address, so it works without MagicDNS.
connect() {
  addr=$(tailscale status --json 2> /dev/null |
    jq -r --arg h "$1" '
      [.Self, (.Peer | to_entries[].value)]
      | map(select((.HostName | ascii_downcase) == ($h | ascii_downcase)))
      | .[0].TailscaleIPs[0] // empty')
  exec ssh "zk@${addr:-$1}"
}

if [ -n "${1:-}" ]; then
  connect "$1"
fi

# A short list, so gum choose rather than fzf. Colours are ANSI palette slots, not hexes.
export GUM_CHOOSE_CURSOR_FOREGROUND=4 GUM_CHOOSE_HEADER_FOREGROUND=8
sel=$(tailscale status --json 2> /dev/null |
  jq -r '
    .Self.UserID as $u
    | [.Self, (.Peer | to_entries[].value)]
    | map(select(.UserID == $u and .OS == "linux"))
    | sort_by(.Online | not)
    | .[]
    | "\(if .Online then "●" else "○" end) \(.HostName)"' |
  gum choose --header 'ssh to  (● online  ○ offline)' --height 12) || exit 0
connect "${sel#* }"
