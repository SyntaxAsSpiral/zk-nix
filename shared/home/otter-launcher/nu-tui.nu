# Search nushell's built-in commands in a nushell tui: filter on the left, the help page of
# the highlighted command on the right. Click, scroll and drag the divider with the mouse.
# Keys: / search, tab move focus, enter open the full page in less, q or esc quit.
$env.config.tui = {
  border: {fg: "#6c7086"}
  border_focused: {fg: "#cba6f7"}
  header: {fg: "#a6e3a1", attr: b}
  highlight: {fg: "#eba0ac", attr: b}
  selected: {fg: "#1e1e2e", bg: "#cba6f7"}
  muted: {fg: "#6c7086"}
  border_type: rounded
}

let result = (
  help commands
  | select category name description
  | tui split --sizes [46% 1fr] [
      (tui box "nushell commands" [
        (tui search --placeholder "category or name" --bind "/" --fuzzy --focus)
        (tui table --id cmds --columns [category name])
      ])
      (tui preview --from cmds --title help {|row| help $row.name })
    ]
  | tui run
)

if $result.action == "submit" and ($result.selected | is-not-empty) {
  $env.config.use_ansi_coloring = true
  help $result.selected.name | ^less -R
}
