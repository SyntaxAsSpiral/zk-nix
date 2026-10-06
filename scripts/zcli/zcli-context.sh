#!/usr/bin/env bash
# Run ConSensus workshop commands at their canonical adeck checkout.
set -euo pipefail

HOST=${ZCLI_CONTEXT_HOST:-$(hostname -s)}
ROOT=${ZCLI_CONTEXT_ROOT:-/mnt/echo/consensus}
PYTHON=${ZCLI_CONTEXT_PYTHON:-/etc/profiles/per-user/zk/bin/python}

usage() {
  printf 'Usage: zcli assemble [--dry-run] [--verbose]\n'
  printf '       zcli sync context [--dry-run] [--verbose]\n'
  printf '       zcli deploy context [--dry-run] [--verbose]\n'
  printf 'Runs the ConSensus workshop on adeck.\n'
  printf 'Sync and deploy both deploy staging, then commit and push.\n'
  printf '--dry-run previews and does not commit.\n'
}

fail() { printf '☠ Context protocol failed: %s\n' "$*" >&2; exit 1; }

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  assemble|sync|deploy) action=$1; shift ;;
  *) usage >&2; fail 'expected assemble, sync, or deploy' ;;
esac

flags=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|--verbose) flags+=("$arg") ;;
    *) fail "unknown option: $arg" ;;
  esac
done

if [[ "$HOST" != adeck ]]; then
  case "$action" in
    assemble) remote_args=(assemble) ;;
    sync) remote_args=(sync context) ;;
    deploy) remote_args=(deploy context) ;;
  esac
  exec ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=10 \
    zk@100.89.32.9 /etc/profiles/per-user/zk/bin/zcli "${remote_args[@]}" "${flags[@]}"
fi

case "$action" in
  assemble) script=assemble.py ;;
  sync|deploy) script=sync.py ;;
esac
[[ -f "$ROOT/workshop/src/$script" ]] || fail "missing workshop script: $script"
printf '☠☠☠ >>> CONTEXT·%s·INITIATED ☠☠☠\n' "${action^^}"
if [[ "$action" == sync ]]; then
  exec "$PYTHON" "$ROOT/workshop/src/sync.py" "${flags[@]}"
fi
if [[ "$action" == deploy ]]; then
  exec "$PYTHON" "$ROOT/workshop/src/sync.py" "${flags[@]}"
fi
exec "$PYTHON" "$ROOT/workshop/src/assemble.py" "${flags[@]}"
