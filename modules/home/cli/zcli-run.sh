#!/usr/bin/env bash
# zcli build/deploy/image/wake. Canonical source is adeck; nh runs on zrrh.
set -euo pipefail
shopt -s inherit_errexit

HOST=$(hostname)
NH=${ZCLI_NH:-/run/current-system/sw/bin/nh}
NIX=${ZCLI_NIX:-/run/current-system/sw/bin/nix}
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

section() { printf '\n%s%s%s\n' "$c_cyan" "$1" "$c_off"; }

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
  banner 'ZCLI DAEMON'
  printf '%s%s%s · %smesh build/deploy%s %s0.6.0%s\n' \
    "$c_magenta" zcli "$c_off" "$c_cyan" "$c_off" "$c_dim" "$c_off"
  section NAME
  printf '    %szcli%s — canonical snapshot, evaluated and built on zrrh\n' "$c_magenta" "$c_off"
  section SYNOPSIS
  printf '    %szcli%s %s<command>%s %s[host] [flags]%s\n' \
    "$c_magenta" "$c_off" "$c_yellow" "$c_off" "$c_dim" "$c_off"
  section COMMANDS
  printf '    %szcli sync%s [host|all] [--dry]\n' "$c_yellow" "$c_off"
  printf '        committed + staged files and secrets; tm20 gets secrets only\n'
  printf '    %szcli wake%s\n' "$c_yellow" "$c_off"
  printf '        wake zrrh and wait until nix answers\n'
  printf '    %szcli build <host>%s builds that host'\''s system closure on zrrh and stops\n' "$c_yellow" "$c_off"
  printf '    %szcli deploy <host>%s boots that closure, schedules a reboot, and returns\n' "$c_yellow" "$c_off"
  printf '        success line: reboot scheduled on <host>\n'
  printf '    %szcli image tm20%s builds the flashable SD card .img. zcli build tm20 does not.\n' "$c_yellow" "$c_off"
  printf '        zcli image -h prints how to write the card. --dry resolves the image only\n'
  section NOTES
  printf '    canonical source is adeck:/mnt/echo/nix-os\n'
  printf '    build, deploy, and image wake zrrh, then sync that snapshot to zrrh:/etc/nixos\n'
  printf '    direct nh os stays on the machine where you run it\n'
  printf '    build and deploy take one host\n'
  printf '    stage changes you want included; unstaged files stay local\n'
  section EXAMPLES
  printf '    %szcli wake%s\n' "$c_dim" "$c_off"
  printf '    %szcli build nxiz%s\n' "$c_dim" "$c_off"
  printf '    %szcli build tm20%s\n' "$c_dim" "$c_off"
  printf '    %szcli image tm20%s\n' "$c_dim" "$c_off"
  printf '    %szcli deploy nxiz%s\n' "$c_dim" "$c_off"
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

# Run argv on zrrh. tty requests a remote tty so nh can draw its build graph.
run_on_zrrh() {
  local mode=$1
  shift
  if [[ "$HOST" == zrrh ]]; then
    "$@"
    return
  fi
  local -a ssh=("${SSH_RUN[@]}")
  [[ "$mode" == tty && -t 1 ]] && ssh+=(-t)
  "${ssh[@]}" "zk@$(address zrrh)" "$@"
}

zrrh_ready() {
  local err status
  set +e
  err=$("${SSH_PROBE[@]}" "zk@$(address zrrh)" "$NIX" store info 2>&1 >/dev/null)
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
    "${SSH_RUN[@]}" "zk@$(address adeck)" "$WAKE" -i "$WOL_BCAST" "$WOL_MAC"
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
  local unit now
  now=$(date +%s)
  unit="zcli-reboot-${target}-${now}"
  local -a reboot_cmd=(sudo -n systemd-run --collect --unit="$unit" --on-active=2 systemctl reboot)
  if [[ "$target" == "$HOST" ]]; then
    "${reboot_cmd[@]}"
  else
    "${SSH_RUN[@]}" "zk@$(address "$target")" "${reboot_cmd[@]}"
  fi
  echo "reboot scheduled on $target"
}

nh_os() {
  local action=$1
  local -a nh_cmd=("$NH" os "$action" -H "$target" "$ZRRH_FLAKE" -e passwordless)
  if [[ "$action" == boot && "$target" != zrrh ]]; then
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
hosts=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry)
      [[ "$cmd" == image ]] || fail "$cmd does not take --dry"
      dry=true ;;
    -h|--help)
      if [[ "$cmd" == image ]]; then
        image_usage
      else
        usage
      fi
      exit 0 ;;
    all)
      if [[ "$cmd" == deploy ]]; then
        fail "deploy all is not settled; pass one host"
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
  build|deploy)
    [[ ${#hosts[@]} -eq 1 ]] || fail "$cmd requires exactly one host"
    target=${hosts[0]}
    valid_host "$target"
    if [[ "$cmd" == deploy && "$target" != zrrh && "$target" != "$HOST" ]]; then
      "${SSH_PROBE[@]}" "zk@$(address "$target")" true || fail "$target is unreachable via Tailscale"
    fi
    prepare
    if [[ "$cmd" == build ]]; then
      echo "==> build $target"
      nh_os build
    else
      echo "==> deploy $target"
      nh_os boot
      schedule_reboot
    fi
    ;;
  image)
    [[ ${#hosts[@]} -eq 1 && "${hosts[0]}" == tm20 ]] || fail "sd image is only defined for tm20"
    target=tm20
    prepare
    build_image
    ;;
  *)
    echo "Error: unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
