# One Nushell config for every host. Compositor startup stays in nushell.nix login files.
''
  $env.config.show_banner = false
  $env.config.render_right_prompt_on_last_line = true

  def create_left_prompt [] {
    let cwd = (pwd | str replace $env.HOME "~")
    let is_root = (id -u | str trim) == "0"
    let success = $env.LAST_EXIT_CODE == 0
    let c1 = if $is_root { ansi { fg: "#f9e2af" } } else if $success { ansi { fg: "#89b4fa" } } else { ansi { fg: "#fab387" } }
    let c2 = if $is_root { ansi { fg: "#eba0ac" } } else if $success { ansi { fg: "#cba6f7" } } else { ansi { fg: "#f5c2e7" } }
    let c3 = if $is_root { ansi { fg: "#f38ba8" } } else if $success { ansi { fg: "#94e2d5" } } else { ansi { fg: "#f38ba8" } }
    let reset = (ansi reset)
    $"(char newline)(ansi { fg: "#b4befe" })($cwd)($c1)❱($c2)❱($c3)❱($reset) "
  }

  def create_right_prompt [] {
    let hour = (date now | format date "%H" | into int)
    let emoji = if $hour < 7 { "🌄" } else if $hour < 12 { "🌇" } else if $hour < 18 { "🌆" } else if $hour < 22 { "🌃" } else { "🌉" }
    let time = (date now | format date "%H:%M")
    $"(ansi { fg: "#6c7086" })($time) ($emoji)(ansi reset)"
  }

  $env.PROMPT_COMMAND = { || create_left_prompt }
  $env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }
  $env.PROMPT_INDICATOR = ""

  $env.PATH = ($env.PATH | append "/home/zk/.local/bin")

  esofetch
  echo ""
''
