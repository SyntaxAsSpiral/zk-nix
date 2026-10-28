# One-shot: if a path is still a symlink into /etc/nixos, copy that target
# over the symlink and stop. A regular file is the app's, and later
# activations leave it alone. zcli sync no longer reaches it.
{ lib, paths }:
''
  unhook_etc_nixos() {
    dest="$1"
    if [ ! -L "$dest" ]; then
      return 0
    fi
    link=$(readlink "$dest")
    case "$link" in
      /etc/nixos/*) ;;
      *) return 0 ;;
    esac
    if [ ! -e "$link" ]; then
      return 0
    fi
    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"
    cp -a "$link" "$dest"
  }
''
+ lib.concatMapStrings (p: "unhook_etc_nixos ${lib.escapeShellArg p}\n") paths
