stale=()
stale_output=$(printf '%s\n' "${stale[@]}")
echo "stale length: ${#stale_output}"
if [[ -z "$stale_output" ]]; then
    echo "empty"
else
    echo "not empty"
fi
