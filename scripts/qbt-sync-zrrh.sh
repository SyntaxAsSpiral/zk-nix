#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="/tmp/qbt-sync-zrrh.lock"
SOURCE_DIR="/mnt/vault/@temp/torrents"
REMOTE_HOST="zk@zrrh"
REMOTE_DIR="/mnt/media/Incoming"
LOG_FILE="/var/lib/qBittorrent/qBittorrent/data/logs/sync-zrrh.log"
RSYNC_BIN="/run/current-system/sw/bin/rsync"
SSH_BIN="/run/current-system/sw/bin/ssh"
FLOCK_BIN="/run/current-system/sw/bin/flock"
DATE_BIN="/run/current-system/sw/bin/date"
DU_BIN="/run/current-system/sw/bin/du"
SLEEP_BIN="/run/current-system/sw/bin/sleep"
RM_BIN="/run/current-system/sw/bin/rm"
BASENAME_BIN="/run/current-system/sw/bin/basename"
MKDIR_BIN="/run/current-system/sw/bin/mkdir"

log() {
  local message="$1"
  "$MKDIR_BIN" -p "${LOG_FILE%/*}"
  printf '%s %s\n' "$("$DATE_BIN" '+%Y-%m-%d %H:%M:%S')" "$message" >> "$LOG_FILE"
}

size_of() {
  local size _
  read -r size _ < <("$DU_BIN" -sb --apparent-size -- "$1")
  printf '%s\n' "$size"
}

is_stable() {
  local path="$1"
  local before after

  before="$(size_of "$path")"
  "$SLEEP_BIN" 5
  after="$(size_of "$path")"
  [[ "$before" == "$after" ]]
}

sync_one() {
  local src="$1"
  local name
  name="$("$BASENAME_BIN" -- "$src")"

  if ! is_stable "$src"; then
    log "skip unstable: $src"
    return 0
  fi

  log "sync start: $src -> $REMOTE_HOST:$REMOTE_DIR/"
  if ! "$RSYNC_BIN" -a --partial --inplace --protect-args -- "$src" "$REMOTE_HOST:$REMOTE_DIR/"; then
    log "sync failed: $src"
    return 1
  fi

  if ! "$SSH_BIN" -o BatchMode=yes -- "$REMOTE_HOST" "test -e '$REMOTE_DIR/$name'"; then
    log "remote verify failed: $REMOTE_DIR/$name"
    return 1
  fi

  "$RM_BIN" -rf -- "$src"
  log "sync ok, local deleted: $src"
}

main() {
  local -a entries=()
  local entry

  if [[ ! -d "$SOURCE_DIR" ]]; then
    log "source dir missing: $SOURCE_DIR"
    exit 0
  fi

  shopt -s nullglob dotglob
  for entry in "$SOURCE_DIR"/*; do
    [[ -e "$entry" ]] || continue
    [[ "$("$BASENAME_BIN" -- "$entry")" == .* ]] && continue
    entries+=("$entry")
  done

  if [[ "${#entries[@]}" -eq 0 ]]; then
    log "nothing to sync"
    exit 0
  fi

  for entry in "${entries[@]}"; do
    sync_one "$entry"
  done
}

if [[ "${1:-}" == "--run" ]]; then
  main
  exit 0
fi

exec "$FLOCK_BIN" "$LOCK_FILE" "$0" --run
