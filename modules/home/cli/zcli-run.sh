#!/usr/bin/env bash
# zcli build/deploy/image/wake. Canonical source is adeck; nh runs on zrrh.
set -euo pipefail
shopt -s inherit_errexit

HOST=$(hostname)
NH=${ZCLI_NH:-/run/current-system/sw/bin/nh}
NIX=${ZCLI_NIX:-/run/current-system/sw/bin/nix}
INHIBIT=${ZCLI_INHIBIT:-/run/current-system/sw/bin/systemd-inhibit}
WAKE=${ZCLI_WAKE:-/run/current-system/sw/bin/wakeonlan}
SYNC=${ZCLI_SYNC:-zcli-sync}
CANONICAL=${ZCLI_CANONICAL:-/mnt/echo/nix-os}
ZRRH_FLAKE=/etc/nixos
# Same wired-NIC packet as adeck's inference relay. This path does not call it.
WOL_MAC=60:cf:84:61:d8:00
WOL_BCAST=192.168.0.255
WAKE_INTERVAL=${ZCLI_WAKE_INTERVAL:-3}
WAKE_DEADLINE=${ZCLI_WAKE_DEADLINE:-180}

SSH_BASE=(-F /dev/null -o BatchMode=yes -o ConnectionAttempts=1)
SSH_PROBE=(ssh "${SSH_BASE[@]}" -o ConnectTimeout=3)
SSH_RUN=(ssh "${SSH_BASE[@]}" -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=20)

fail() { echo "Error: $*" >&2; exit 1; }

# Lexigon help colors: cyan sections, yellow commands, green examples.
# The slant header is toilet, tinted once by lolcat. A pipe stays plain text.
c_off='' c_dim='' c_cyan='' c_yellow='' c_green='' c_magenta=''
help_init() {
  if [[ -t 1 ]]; then
    c_off=$'\033[0m' c_dim=$'\033[2m' c_cyan=$'\033[1;36m'
    c_yellow=$'\033[1;33m' c_green=$'\033[32m' c_magenta=$'\033[1;35m'
  else
    c_off='' c_dim='' c_cyan='' c_yellow='' c_green='' c_magenta=''
  fi
}

section() { printf '\n%s☠☠☠ >>> %s·PROTOCOL%s\n' "$c_cyan" "$1" "$c_off"; }

banner() {
  [[ -t 1 ]] || return 0
  local figlet_bin font_dir
  figlet_bin=$(command -v figlet || true)
  if [[ -n "$figlet_bin" ]] && command -v toilet >/dev/null; then
    font_dir=$(dirname "$(dirname "$(readlink -f "$figlet_bin")")")/share/figlet
    if [[ -f "$font_dir/slant.flf" ]]; then
      if command -v lolcat >/dev/null; then
        toilet -d "$font_dir" -w 120 -f slant "$1" | lolcat -f
      else
        toilet -d "$font_dir" -w 120 -f slant "$1"
      fi
      return
    fi
  fi
  if [[ -n "$figlet_bin" ]]; then
    figlet -w 120 -f slant "$1" || true
  fi
}

usage() {
  help_init
  banner 'ZCLI COGITATOR'
  printf '%s%s%s · %smesh cogitator%s %s0.8.1%s\n' \
    "$c_magenta" zcli "$c_off" "$c_cyan" "$c_off" "$c_dim" "$c_off"
  section NAME
  printf '    %szcli%s — canonical snapshot, evaluated and built on zrrh\n' "$c_magenta" "$c_off"
  section SYNOPSIS
  printf '    %szcli%s %s<command>%s %s[host] [flags]%s\n' \
    "$c_magenta" "$c_off" "$c_yellow" "$c_off" "$c_dim" "$c_off"
  section COMMANDS
  printf '    %szcli sync%s [host|all] [--dry]\n' "$c_yellow" "$c_off"
  printf '        committed + staged files, local git history, and secrets; tm20 gets secrets only\n'
  printf '    %szcli assemble%s [--dry-run] [--verbose]\n' "$c_yellow" "$c_off"
  printf '    %szcli sync context%s [--dry-run] [--verbose]\n' "$c_yellow" "$c_off"
  printf '        ConSensus workshop on adeck; deploys staging without commit or push\n'
  printf '    %szcli deploy context%s [--dry-run] [--verbose]\n' "$c_yellow" "$c_off"
  printf '        same workshop deploy, then commits and pushes; --dry-run does not commit\n'
  printf '    %szcli wake%s\n' "$c_yellow" "$c_off"
  printf '        wake zrrh and wait until nix answers\n'
  printf '    %szcli build <host>%s builds that host'\''s system closure on zrrh and stops\n' "$c_yellow" "$c_off"
  printf '    %szcli deploy <host> [host ...] [--switch]%s\n' "$c_yellow" "$c_off"
  printf '        boot and schedule reboots by default; --switch activates without rebooting\n'
  printf '        follows your host order, moving the invoking host to the end\n'
  printf '    %szcli image tm20%s builds the flashable SD card .img. zcli build tm20 does not.\n' "$c_yellow" "$c_off"
  printf '        zcli image -h prints how to write the card. --dry resolves the image only\n'
  section NOTES
  printf '    canonical source is adeck:/mnt/echo/nix-os\n'
  printf '    build, deploy, and image wake zrrh, then sync that snapshot to zrrh:/etc/nixos\n'
  printf '    those jobs hold a sleep lock on zrrh so Noctalia idle does not suspend it\n'
  printf '    direct nh os stays on the machine where you run it\n'
  printf '    build takes one host; deploy takes one or more distinct hosts\n'
  printf '    deploy context stays on adeck and does not wake zrrh\n'
  printf '    stage changes you want included; unstaged files stay local\n'
  section EXAMPLES
  printf '    %szcli wake%s\n' "$c_dim" "$c_off"
  printf '    %szcli build nxiz%s\n' "$c_dim" "$c_off"
  printf '    %szcli build tm20%s\n' "$c_dim" "$c_off"
  printf '    %szcli image tm20%s\n' "$c_dim" "$c_off"
  printf '    %szcli deploy nxiz%s\n' "$c_dim" "$c_off"
  printf '    %szcli deploy nxiz zrrh adeck --switch%s\n' "$c_dim" "$c_off"
  printf '    %szcli deploy zrrh adeck%s\n' "$c_dim" "$c_off"
  printf '    %szcli assemble%s\n' "$c_dim" "$c_off"
  printf '    %szcli sync context --dry-run%s\n' "$c_dim" "$c_off"
  printf '    %szcli deploy context%s\n' "$c_dim" "$c_off"
  printf '    |001101|—|001101|—|111000| checksum stable\n'
}

image_usage() {
  help_init
  banner 'SD IMAGE'
  printf '%s%s%s · %stm20 sd image%s\n' \
    "$c_magenta" zcli "$c_off" "$c_cyan" "$c_off"
  section NAME
  printf '    %szcli image tm20%s builds the flashable .img on zrrh\n' "$c_yellow" "$c_off"
  printf '    the result link is the .img file\n'
  printf '        adeck: /mnt/echo/nix-os/result-sd-tm20\n'
  printf '        zrrh:  /etc/nixos/result-sd-tm20\n'
  printf '    --dry resolves the image and does not build it\n'
  section FLASH
  printf '    lsblk and dd are enough. of= is the whole disk that appeared when you\n'
  printf '    plugged the card in (lsblk NAME), not one of its partitions.\n'
  printf '    sdb below is that example.\n'
  printf '    %slsblk -o NAME,SIZE,MODEL,TRAN%s\n' "$c_green" "$c_off"
  printf '    %ssudo dd if=/mnt/echo/nix-os/result-sd-tm20 of=/dev/sdb bs=4M conv=fsync status=progress%s\n' \
    "$c_green" "$c_off"
  section SECRETS
  printf '    Before first boot, mount the card'\''s ext4 partition (lsblk -f; usually the\n'
  printf '    second one) and copy secrets. Activation expects them at /etc/nixos/secrets.\n'
  printf '    %ssudo mkdir -p /mnt/tm20%s\n' "$c_green" "$c_off"
  printf '    %ssudo mount /dev/sdb2 /mnt/tm20%s\n' "$c_green" "$c_off"
  printf '    %ssudo mkdir -p /mnt/tm20/etc/nixos/secrets%s\n' "$c_green" "$c_off"
  printf '    %ssudo rsync -a /mnt/echo/nix-os/secrets/ /mnt/tm20/etc/nixos/secrets/%s\n' "$c_green" "$c_off"
  printf '    %ssudo umount /mnt/tm20%s\n' "$c_green" "$c_off"
}

address() {
  case "$1" in
    adeck) printf '%s\n' 100.89.32.9 ;;
    nxiz) printf '%s\n' 100.115.135.104 ;;
    zrrh) printf '%s\n' 100.77.90.79 ;;
    tm20) printf '%s\n' 100.123.184.5 ;;
    *) fail "unknown host: $1 (valid: nxiz zrrh adeck tm20)" ;;
  esac
}

valid_host() {
  case "$1" in
    nxiz|zrrh|adeck|tm20) ;;
    *) fail "unknown host: $1 (valid: nxiz zrrh adeck tm20)" ;;
  esac
}

# Dial the Tailscale IP. known_hosts is keyed by mesh name, so the host key
# is checked as that name. probe|run|tty selects the ssh option set.
ssh_mesh() {
  local mode=$1 name=$2
  shift 2
  local -a ssh
  case "$mode" in
    probe) ssh=("${SSH_PROBE[@]}") ;;
    run) ssh=("${SSH_RUN[@]}") ;;
    tty) ssh=("${SSH_RUN[@]}" -t) ;;
    *) fail "ssh mode: $mode" ;;
  esac
  "${ssh[@]}" -o "HostKeyAlias=$name" "zk@$(address "$name")" "$@"
}

# Run argv on zrrh. tty requests a remote tty so nh can draw its build graph.
run_on_zrrh() {
  local mode=$1
  shift
  if [[ "$HOST" == zrrh ]]; then
    "$@"
    return
  fi
  if [[ "$mode" == tty && -t 1 ]]; then
    ssh_mesh tty zrrh "$@"
  else
    ssh_mesh run zrrh "$@"
  fi
}

# Noctalia suspends zrrh after 30 minutes without keyboard or mouse.
# One lock covers the whole job, including the gaps in a multi-host deploy.
# A per-command lock would drop between hosts and let a waiting suspend through.
AWAKE_PID=
release_zrrh_awake() {
  [[ -n "${AWAKE_PID:-}" ]] || return 0
  kill "$AWAKE_PID" 2>/dev/null || true
  wait "$AWAKE_PID" 2>/dev/null || true
  AWAKE_PID=
}
hold_zrrh_awake() {
  release_zrrh_awake
  local why=$1 fifo line remote
  # An SSH session is not an active seat, so logind demands a polkit prompt
  # for a blocking sleep lock. sudo -n is the same passwordless path as reboot.
  fifo=$(mktemp)
  rm -f "$fifo"
  mkfifo "$fifo"
  if [[ "$HOST" == zrrh ]]; then
    sudo -n "$INHIBIT" --what=sleep --who=zcli --why="$why" --mode=block \
      sh -c 'echo zcli-awake; exec sleep infinity' >"$fifo" &
  else
    # ssh joins its arguments and the remote shell parses that string.
    # A reason of "zcli deploy zrrh" otherwise becomes the program inhibit runs.
    printf -v remote 'sudo -n %q --what=sleep --who=zcli --why=%q --mode=block sh -c %q' \
      "$INHIBIT" "$why" 'echo zcli-awake; exec sleep infinity'
    ssh_mesh run zrrh "$remote" >"$fifo" &
  fi
  AWAKE_PID=$!
  if ! IFS= read -r line <"$fifo" || [[ "$line" != zcli-awake ]]; then
    rm -f "$fifo"
    release_zrrh_awake
    fail "zrrh refused the sleep lock"
  fi
  rm -f "$fifo"
}
trap release_zrrh_awake EXIT
trap 'release_zrrh_awake; exit 130' INT
trap 'release_zrrh_awake; exit 143' TERM

zrrh_ready() {
  local err status
  set +e
  err=$(ssh_mesh probe zrrh "$NIX" store info 2>&1 >/dev/null)
  status=$?
  set -e
  [[ "$status" -eq 0 ]] && return 0
  if [[ "$err" == *verification\ failed* || "$err" == *Permission\ denied* ]]; then
    printf '%s\n' "$err" >&2
    fail "zrrh SSH failed"
  fi
  return 1
}

send_wake() {
  if [[ "$HOST" == adeck ]]; then
    "$WAKE" -i "$WOL_BCAST" "$WOL_MAC"
  else
    ssh_mesh run adeck "$WAKE" -i "$WOL_BCAST" "$WOL_MAC"
  fi
}

wake_zrrh() {
  if [[ "$HOST" == zrrh ]]; then
    echo "zrrh: already local"
    return 0
  fi
  local deadline=$((SECONDS + WAKE_DEADLINE)) sent=false
  while (( SECONDS < deadline )); do
    if zrrh_ready; then
      if [[ "$sent" == true ]]; then
        echo "zrrh: ready"
      else
        echo "zrrh: already ready"
      fi
      return 0
    fi
    echo "zrrh: sending wake packet"
    send_wake
    sent=true
    sleep "$WAKE_INTERVAL"
  done
  fail "zrrh did not become ready within ${WAKE_DEADLINE}s"
}

prepare() {
  echo "==> wake zrrh"
  wake_zrrh
  echo "==> sync canonical snapshot to zrrh"
  "$SYNC" zrrh
}

schedule_reboot() {
  local delay=${1:-2} unit now
  now=$(date +%s)
  unit="zcli-reboot-${target}-${now}"
  local -a reboot_cmd=(sudo -n systemd-run --collect --unit="$unit" --on-active="$delay" systemctl reboot)
  if [[ "$target" == "$HOST" ]]; then
    "${reboot_cmd[@]}"
  else
    ssh_mesh run "$target" "${reboot_cmd[@]}"
  fi
  echo "reboot scheduled on $target"
}

nh_os() {
  local action=$1
  local -a nh_cmd=("$NH" os "$action" -H "$target" "$ZRRH_FLAKE" -e passwordless)
  if [[ "$action" != build && "$target" != zrrh ]]; then
    # nh's own SSH starts on zrrh, where mesh names resolve.
    nh_cmd+=(--target-host "zk@$target" --use-substitutes)
  fi
  echo "    nh os $action -H $target on zrrh"
  run_on_zrrh tty "${nh_cmd[@]}"
}

build_image() {
  local -a image_cmd=(
    "$NIX" build
    "$ZRRH_FLAKE#nixosConfigurations.tm20.config.system.build.sdImage"
  )
  if [[ "$dry" == true ]]; then
    image_cmd+=(--dry-run)
    echo "==> sd-image tm20 (dry)"
    run_on_zrrh tty "${image_cmd[@]}"
    return
  fi
  image_cmd+=(--out-link "$ZRRH_FLAKE/result-sd-tm20")
  echo "==> sd-image tm20 on zrrh"
  run_on_zrrh tty "${image_cmd[@]}"
  echo "sd image on zrrh: $ZRRH_FLAKE/result-sd-tm20"
  [[ "$HOST" == zrrh ]] && return 0
  local path link
  path=$(run_on_zrrh plain readlink -f "$ZRRH_FLAKE/result-sd-tm20")
  [[ "$path" == /nix/store/* ]] || fail "sd image path missing on zrrh"
  "$NIX" copy --from "ssh://zk@$(address zrrh)" "$path"
  if [[ "$HOST" == adeck ]]; then
    link=$CANONICAL/result-sd-tm20
  else
    link=$PWD/result-sd-tm20
  fi
  ln -sfn "$path" "$link"
  echo "sd image copied to $link"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

case "$1" in
  help|-h|--help) usage; exit 0 ;;
esac

cmd=$1
shift
dry=false
switch=false
hosts=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry)
      [[ "$cmd" == image ]] || fail "$cmd does not take --dry"
      dry=true ;;
    --switch)
      [[ "$cmd" == deploy ]] || fail "$cmd does not take --switch"
      switch=true ;;
    -h|--help)
      if [[ "$cmd" == image ]]; then
        image_usage
      else
        usage
      fi
      exit 0 ;;
    all)
      if [[ "$cmd" == deploy ]]; then
        fail "deploy requires an explicit host list"
      fi
      hosts+=("$1") ;;
    -*) fail "unknown flag for $cmd: $1" ;;
    *) hosts+=("$1") ;;
  esac
  shift
done

case "$cmd" in
  wake)
    [[ ${#hosts[@]} -eq 0 && "$dry" == false ]] || fail "wake takes no arguments"
    wake_zrrh
    ;;
  build)
    [[ ${#hosts[@]} -eq 1 ]] || fail "build requires exactly one host"
    target=${hosts[0]}
    valid_host "$target"
    prepare
    hold_zrrh_awake "zcli build $target"
    echo "==> build $target"
    nh_os build
    ;;
  deploy)
    [[ ${#hosts[@]} -gt 0 ]] || fail "deploy requires at least one host"
    ordered=()
    local_host_requested=false
    for candidate in "${hosts[@]}"; do
      valid_host "$candidate"
      for seen in "${ordered[@]}"; do
        [[ "$candidate" != "$seen" ]] || fail "duplicate deploy host: $candidate"
      done
      if [[ "$candidate" == "$HOST" ]]; then
        [[ "$local_host_requested" == false ]] || fail "duplicate deploy host: $candidate"
        local_host_requested=true
      else
        ordered+=("$candidate")
      fi
    done
    [[ "$local_host_requested" == false ]] || ordered+=("$HOST")
    for candidate in "${ordered[@]}"; do
      if [[ "$candidate" != zrrh && "$candidate" != "$HOST" ]]; then
        if ! err=$(ssh_mesh probe "$candidate" true 2>&1); then
          fail "$candidate: ${err:-ssh failed}"
        fi
      fi
    done
    prepare
    hold_zrrh_awake "zcli deploy ${ordered[*]}"
    action=boot
    [[ "$switch" == false ]] || action=switch
    echo "Deploy order: ${ordered[*]} ($action)"
    for target in "${ordered[@]}"; do
      echo "==> deploy $target"
      nh_os "$action"
    done
    if [[ "$switch" == false ]]; then
      for target in "${ordered[@]}"; do
        delay=2
        if [[ ${#ordered[@]} -gt 1 ]]; then
          delay=5
          [[ "$target" != "$HOST" ]] || delay=20
        fi
        schedule_reboot "$delay"
      done
    fi
    ;;
  image)
    [[ ${#hosts[@]} -eq 1 && "${hosts[0]}" == tm20 ]] || fail "sd image is only defined for tm20"
    target=tm20
    prepare
    hold_zrrh_awake "zcli image tm20"
    build_image
    ;;
  *)
    echo "Error: unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
