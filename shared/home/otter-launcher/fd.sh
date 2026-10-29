# fd over $HOME and every mounted data drive on this host, hidden and ignored files included.
# Usage: otter-fd [fd options] [pattern]
roots=("$HOME")
while read -r target fstype; do
  target=$(printf '%b' "$target")
  case $fstype in
    autofs | btrfs | ext[234] | xfs | f2fs | zfs | bcachefs | vfat | exfat | ntfs | ntfs3 | fuseblk) ;;
    *) continue ;;
  esac
  case $target in
    / | /boot* | /nix* | /var* | /home* | /etc* | /usr* | /tmp* | /run/*) continue ;;
  esac
  roots+=("$target")
done < <(findmnt -rno TARGET,FSTYPE)

# autofs and btrfs list the same target twice
mapfile -t roots < <(printf '%s\n' "${roots[@]}" | sort -u)

exec fd --hidden --no-ignore \
  --exclude node_modules --exclude .cache --exclude result --exclude lost+found \
  "$@" "${roots[@]}"
