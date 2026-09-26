#!/usr/bin/env bash
# Publish adeck's Git index plus secrets. Also runnable from the checkout.
set -euo pipefail
shopt -s inherit_errexit

SOURCE=/mnt/echo/nix-os
DEST=/etc/nixos
HOST=$(hostname)
SSH=(ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=5
  -o ServerAliveInterval=5 -o ServerAliveCountMax=2)

fail() { echo "Error: $*" >&2; exit 1; }
address() {
  case "$1" in
    adeck) echo 100.89.32.9 ;;
    nxiz) echo 100.115.135.104 ;;
    zrrh) echo 100.77.90.79 ;;
    tm20) echo 100.123.184.5 ;;
    *) fail "unknown host: $1 (valid: adeck nxiz zrrh tm20 all)" ;;
  esac
}

# Inspect managed destination files without absorbing unrelated local files.
tree() {
  local repo=$1 index=$2 base=$3
  GIT_INDEX_FILE="$index" git -C "$repo" read-tree "$base"
  GIT_INDEX_FILE="$index" git -C "$repo" add -u
  GIT_INDEX_FILE="$index" git -C "$repo" write-tree
}

receive() (
  local stage=$1 kind=$2 commit=$3 expected=$4 dry=$5
  [[ "$stage" =~ ^/tmp/zcli-sync\.[a-zA-Z0-9_]+$ && -d "$stage" && ! -L "$stage" ]] || fail "invalid staging directory"
  trap 'rm -rf -- "$stage"' EXIT
  [[ "$commit" =~ ^[a-f0-9]{40,64}$ && "$expected" =~ ^[a-f0-9]{40,64}$ ]] || fail "invalid snapshot identity"
  [[ "$dry" == true || "$dry" == false ]] || fail "invalid preview mode"
  [[ -d "$DEST" && ! -L "$DEST" ]] || fail "$DEST must be a real directory"

  if [[ "$kind" == secrets ]]; then
    address "$HOST" >/dev/null
    [[ -d "$DEST/secrets" && ! -L "$DEST/secrets" ]] || fail "missing secrets directory"
    exec 9>"/run/lock/zcli-sync-secrets.lock"
    flock -n 9 || fail "another secrets sync is running"
    local flags=()
    [[ "$dry" == false ]] || flags+=(--dry-run)
    # No delete: retain host-local credentials. Never follow source symlinks.
    rsync -rlptc --itemize-changes "${flags[@]}" "$stage/payload/" "$DEST/secrets/"
    return
  fi

  [[ "$kind" == flake && "$HOST" != tm20 ]] || fail "invalid flake destination"
  [[ -d "$DEST/.git" && ! -L "$DEST/.git" ]] || fail "$DEST must be an existing Git checkout"
  [[ -z "$(git -C "$DEST" ls-files -- secrets)" ]] || fail "destination tracks secrets"
  exec 9>"$DEST/.git/zcli.lock"
  flock -n 9 || fail "another sync/build/deploy is using $DEST"
  local baseline current desired staged path conflict=false
  baseline=$(git -C "$DEST" rev-parse --verify refs/zcli/sync 2>/dev/null || git -C "$DEST" rev-parse 'HEAD^{tree}')
  current=$(tree "$DEST" "$stage/current-index" "$baseline")
  # Import the snapshot into this checkout's object database without copying .git.
  GIT_INDEX_FILE="$stage/incoming-index" git -C "$DEST" read-tree --empty
  GIT_INDEX_FILE="$stage/incoming-index" git --git-dir="$DEST/.git" --work-tree="$stage/payload" add -Af
  desired=$(GIT_INDEX_FILE="$stage/incoming-index" git -C "$DEST" write-tree)
  [[ "$desired" == "$expected" ]] || fail "received snapshot hash does not match"
  staged=$(git -C "$DEST" write-tree)
  if [[ -f "$DEST/.git/zcli-sync-incomplete" ]]; then
    [[ "$(cat "$DEST/.git/zcli-sync-incomplete")" == "$desired" ]] || fail "interrupted sync: retry its original snapshot first"
  fi
  while IFS= read -r -d '' path; do
    if ! git -C "$DEST" diff --quiet "$current" "$desired" -- "$path"; then
      printf 'conflict: %s\n' "$path" >&2
      conflict=true
    fi
  done < <(git -C "$DEST" diff --name-only -z "$baseline" "$current")
  while IFS= read -r -d '' path; do
    if ! git -C "$DEST" diff --quiet "$staged" "$desired" -- "$path"; then
      printf 'staged conflict: %s\n' "$path" >&2
      conflict=true
    fi
  done < <(git -C "$DEST" diff --name-only -z "$baseline" "$staged")
  # Leave unrelated local files alone; refuse collisions with incoming files.
  while IFS= read -r -d '' path; do
    if [[ -e "$stage/payload/$path" || -L "$stage/payload/$path" ]]; then
      printf 'unmanaged destination path: %s\n' "$path" >&2
      conflict=true
    fi
  done < <(git -C "$DEST" ls-files --others -z)
  [[ "$conflict" == false ]] || fail "destination has local edits; reconcile them with adeck before syncing"

  git -C "$DEST" diff --stat "$current" "$desired"
  [[ "$dry" == false ]] || return 0
  printf '%s\n' "$desired" >"$DEST/.git/zcli-sync-incomplete"
  # Delete only previously managed files. Ignored files and secrets stay intact.
  while IFS= read -r -d '' path; do
    rm -f -- "$DEST/$path"
    rmdir -p --ignore-fail-on-non-empty -- "$(dirname "$DEST/$path")" 2>/dev/null || true
  done < <(git -C "$DEST" diff --name-only --diff-filter=D -z "$current" "$desired")
  rsync -rlptc --delay-updates "$stage/payload/" "$DEST/"
  [[ "$(tree "$DEST" "$stage/verify-index" "$desired")" == "$desired" ]] || fail "destination changed during sync"
  # Include new files for Nix's Git source filter; HEAD/history remain untouched.
  git -C "$DEST" read-tree "$desired"
  git -C "$DEST" update-ref refs/zcli/sync "$desired"
  printf 'source_commit=%s\nsource_tree=%s\n' "$commit" "$desired" >"$DEST/.git/zcli-sync-receipt"
  rm -- "$DEST/.git/zcli-sync-incomplete"
)

if [[ "${1:-}" == --receive ]]; then
  shift
  [[ $# == 5 ]] || fail "invalid receiver arguments"
  receive "$@"
  exit
fi

dry=false
targets=()
for arg in "$@"; do
  case "$arg" in
    --dry) dry=true ;;
    -h|--help)
      echo 'Usage: zcli sync [host|all] [host ...] [--dry]'
      echo 'Default: invoking host. Source: adeck:/mnt/echo/nix-os.'
      echo 'Flake hosts receive committed + staged content and secrets; tm20 receives only secrets.'
      exit 0 ;;
    all) targets+=(adeck nxiz zrrh tm20) ;;
    *) address "$arg" >/dev/null; targets+=("$arg") ;;
  esac
done
address "$HOST" >/dev/null
[[ ${#targets[@]} != 0 ]] || targets=("$HOST")
# Forward explicit targets so a bare invocation still means the original host.
if [[ "$HOST" != adeck ]]; then
  args=("${targets[@]}")
  [[ "$dry" == false ]] || args+=(--dry)
  exec "${SSH[@]}" zk@100.89.32.9 /etc/profiles/per-user/zk/bin/zcli sync "${args[@]}"
fi

[[ -d "$SOURCE/.git" && ! -L "$SOURCE" && ! -L "$SOURCE/.git" ]] || fail "canonical checkout is missing"
[[ "$(git -C "$SOURCE" rev-parse --show-toplevel)" == "$SOURCE" ]] || fail "invalid canonical checkout"
[[ -z "$(git -C "$SOURCE" ls-files -- secrets)" ]] || fail "canonical checkout tracks secrets"
stage=$(mktemp -d /tmp/zcli-sync.XXXXXXXXXX)
trap 'rm -rf -- "$stage"' EXIT
mkdir "$stage/objects" "$stage/flake" "$stage/secrets"
commit=$(git -C "$SOURCE" rev-parse HEAD)
# Temporary objects as well as a temporary index: even a preview leaves Git alone.
export GIT_OBJECT_DIRECTORY="$stage/objects"
export GIT_ALTERNATE_OBJECT_DIRECTORIES="$SOURCE/.git/objects"
cp -- "$(git -C "$SOURCE" rev-parse --path-format=absolute --git-path index)" "$stage/source-index"
snapshot=$(GIT_INDEX_FILE="$stage/source-index" git -C "$SOURCE" write-tree)
GIT_INDEX_FILE="$stage/source-index" git -C "$SOURCE" checkout-index --all --prefix="$stage/flake/"
unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
[[ -d "$SOURCE/secrets" && ! -L "$SOURCE/secrets" ]] || fail "missing canonical secrets directory"
[[ -z "$(find "$SOURCE/secrets" -type l -print -quit)" ]] || fail "canonical secrets contains symlinks"
rsync -rpt "$SOURCE/secrets/" "$stage/secrets/"
echo "Source: adeck:$SOURCE (commit $commit, staged tree $snapshot; secrets copied separately)"

seen=' '
failed=false
for target in "${targets[@]}"; do
  [[ "$seen" != *" $target "* ]] || continue
  seen+="$target "
  echo "==> sync $target (preview=$dry)"
  set +e
  (
    set -e
    kinds=(flake secrets)
    [[ "$target" != tm20 ]] || kinds=(secrets)
    for kind in "${kinds[@]}"; do
      payload="$stage/$kind"
      if [[ "$target" == adeck ]]; then
        incoming=$(mktemp -d /tmp/zcli-sync.XXXXXXXXXX)
        trap 'rm -rf -- "$incoming"' EXIT
        mkdir "$incoming/payload"
        rsync -rlpt "$payload/" "$incoming/payload/"
        if [[ "$kind" == secrets ]]; then
          sudo -n bash "${BASH_SOURCE[0]}" --receive "$incoming" "$kind" "$commit" "$snapshot" "$dry"
        else
          receive "$incoming" "$kind" "$commit" "$snapshot" "$dry"
        fi
      else
        remote="zk@$(address "$target")"
        incoming=$("${SSH[@]}" "$remote" mktemp -d /tmp/zcli-sync.XXXXXXXXXX)
        [[ "$incoming" =~ ^/tmp/zcli-sync\.[a-zA-Z0-9]+$ ]] || fail "invalid remote staging directory"
        trap '"${SSH[@]}" "$remote" rm -rf -- "$incoming" >/dev/null 2>&1 || true' EXIT
        rsync -rlpt -e "${SSH[*]}" "$payload/" "$remote:$incoming/payload/"
        receiver=(bash -s --)
        [[ "$kind" != secrets ]] || receiver=(sudo -n bash -s --)
        "${SSH[@]}" "$remote" "${receiver[@]}" --receive "$incoming" "$kind" "$commit" "$snapshot" "$dry" <"${BASH_SOURCE[0]}"
      fi
    done
  )
  result=$?
  set -e
  if [[ "$result" == 0 ]]; then
    echo "    $target: OK"
  else
    echo "    $target: FAILED (other targets will still be attempted)" >&2
    failed=true
  fi
done
[[ "$failed" == false ]]
