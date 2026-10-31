# One Nushell config for every host. Compositor startup stays in nushell.nix login files.
''
  $env.config.show_banner = false
  $env.config.render_right_prompt_on_last_line = true

  # Two lines: an info line on top and the main line under it, led by a diamond, with the gloss and glyph at its right edge, and the hex digits on the main line. A ╰─ corner on the left and a ─╯ on the right tie it to the main line. Segments show only when they apply; the frame stays without them.
  # The gloss is pushed to the right edge with plain spaces, not a drawn line. The prompt is drawn once, so a resize leaves it where it was.
  # Colours are ANSI palette names, matched to Catppuccin Macchiato.
  $env.PROMPT_HOST = (sys host | get hostname)

  # One git call, parsed: branch, ahead/behind, staged, unstaged, untracked. Null outside a repo.
  def git-info [] {
    let r = (git status --porcelain=v2 --branch | complete)
    if $r.exit_code != 0 { return null }
    let l = ($r.stdout | lines)
    let head = ($l | where {|x| $x | str starts-with "# branch.head "} | get 0? | default "" | str replace "# branch.head " "")
    let ab = ($l | where {|x| $x | str starts-with "# branch.ab "} | get 0? | default "" | str replace "# branch.ab " "")
    let counts = ($ab | parse --regex '\+(?<a>\d+) -(?<b>\d+)' | get 0? | default { a: "0", b: "0" })
    let ent = ($l | where {|x| not ($x | str starts-with "#")})
    let changed = ($ent | where {|x| ($x | str starts-with "1 ") or ($x | str starts-with "2 ")})
    {
      branch: $head
      ahead: ($counts.a | into int)
      behind: ($counts.b | into int)
      staged: ($changed | where {|x| ($x | str substring 2..2) != "."} | length)
      unstaged: ($changed | where {|x| ($x | str substring 3..3) != "."} | length)
      untracked: ($ent | where {|x| $x | str starts-with "? "} | length)
    }
  }

  # Where you are: the path, led over ssh by the host. Deeper than two levels it shrinks to its last name: adeck:../nix-os, ~../src. /mnt reads as m: adeck:m../nix-os.
  def place [] {
    let dg = (ansi dark_gray)
    let rs = (ansi reset)
    let p = (pwd)
    let in_home = ($p == $env.HOME) or ($p | str starts-with $"($env.HOME)/")
    let in_mnt = ($p == "/mnt") or ($p | str starts-with "/mnt/")
    let root = if $in_home { $env.HOME } else if $in_mnt { "/mnt" } else { "" }
    let lead = if $in_home { "~" } else if $in_mnt { "m" } else { "" }
    let parts = ($p | str substring ($root | str length).. | split row "/" | where {|x| $x != ""})
    let short = ($parts | length) > (if $in_home { 2 } else if $in_mnt { 1 } else { 2 })
    let ssh = ($env.SSH_CONNECTION? | default "" | is-not-empty)
    let host = if $ssh { $"(ansi magenta)($env.PROMPT_HOST)($dg):($rs)" } else { "" }
    let path = if $short { $"(ansi light_blue)($lead)($dg)..(ansi light_blue)/($parts | last)($rs)" } else if $root == "" { $"(ansi light_blue)($p)($rs)" } else { $"(ansi light_blue)($lead)(if ($parts | is-empty) { "" } else { "/" + ($parts | str join "/") })($rs)" }
    $"($host)($path)"
  }

  # The segments on the top line, left to right. Each shows only when it applies.
  def segments [] {
    let dg = (ansi dark_gray)
    let rs = (ansi reset)
    mut segs = []

    let g = (git-info)
    if $g != null {
      mut t = $"(ansi light_blue)(char -u e0a0) ($g.branch)($rs)"
      if $g.ahead > 0 { $t = $"($t) (ansi green)↑($g.ahead)($rs)" }
      if $g.behind > 0 { $t = $"($t) (ansi yellow)↓($g.behind)($rs)" }
      if $g.staged > 0 { $t = $"($t) (ansi green)+($g.staged)($rs)" }
      if $g.unstaged > 0 { $t = $"($t) (ansi yellow)~($g.unstaged)($rs)" }
      if $g.untracked > 0 { $t = $"($t) (ansi light_red)?($g.untracked)($rs)" }
      $segs = ($segs | append $t)
    }

    if ($env.IN_NIX_SHELL? | default "" | is-not-empty) {
      $segs = ($segs | append $"(ansi cyan)(char -u f313) nix($rs)")
    }

    let ms = ($env.CMD_DURATION_MS? | default "0" | into int)
    if $ms > 3000 {
      let secs = (($ms / 1000) | math round --precision 1)
      $segs = ($segs | append $"(ansi yellow)($secs)s($rs)")
    }

    if ($env.LAST_EXIT_CODE? | default 0 | into int) != 0 {
      $segs = ($segs | append $"(ansi red)✘ ($env.LAST_EXIT_CODE)($rs)")
    }

    $segs
  }

  # The top line's right edge: the dim gloss and the alchemical glyph. Empty before the first hook runs.
  def chrono-tag [] {
    let chrono = ($env.CHRONO? | default null)
    if $chrono == null { return "" }
    $"(ansi dark_gray)\(($chrono.gloss)\)(ansi reset) (ansi green)(char -i (0x1F700 + $chrono.idx))(ansi reset)"
  }

  def create_left_prompt [] {
    let dg = (ansi dark_gray)
    let rs = (ansi reset)
    let is_root = (id -u | str trim) == "0"
    let success = ($env.LAST_EXIT_CODE? | default 0 | into int) == 0
    let c1 = if $is_root { ansi light_yellow } else if $success { ansi blue } else { ansi yellow }
    let c2 = if $is_root { ansi light_red } else { ansi magenta }
    let c3 = if $is_root or not $success { ansi red } else { ansi cyan }

    let joined = (segments | str join $" ($dg)⋅($rs) ")
    let cols = (try { (term size).columns } catch { 80 })
    let corner = $"($dg)╰─($rs)"
    let left = $"(ansi light_cyan)❖($rs) ($joined)"
    let clock = (chrono-tag)
    let used = (($left | ansi strip | str length --grapheme-clusters) + ($clock | ansi strip | str length --grapheme-clusters))
    let top = $"($left)("" | fill --width ([($cols - $used) 1] | math max))($clock)"

    $"(char newline)($top)(char newline)($corner)(place)($dg)⋅($c1)❱($c2)❱($c3)❱($rs) "
  }

  $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append { ||
    let hex = (((date now | into int) | format number).lowerhex | str substring (-6..))
    let idx = (("0x" + $hex | into int) mod 116)
    let gloss = (r#'${builtins.readFile ./alchemy.txt}'# | lines | get $idx)
    $env.CHRONO = { hex: $hex, idx: $idx, gloss: $gloss }
  })

  # The main line's right edge: the hex digits, each in an accent, and the mirror of the left corner.
  def create_right_prompt [] {
    let chrono = ($env.CHRONO? | default null)
    if $chrono == null { return "" }
    let accents = ["red" "yellow" "light_yellow" "cyan" "light_blue" "magenta"]
    let digits = ($chrono.hex | split chars | enumerate | each { |c| $"(ansi ($accents | get $c.index))($c.item)" } | str join)
    $"($digits)(ansi dark_gray)─╯(ansi reset)"
  }

  $env.PROMPT_COMMAND = { || create_left_prompt }
  $env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }
  $env.PROMPT_INDICATOR = ""

  # History collapsing: once a command is entered, its prompt shrinks to the main line alone, with no frame,
  # so scrollback stays one line per command. On the right it keeps only the dim gloss of that prompt.
  def create_transient_prompt [] {
    let dg = (ansi dark_gray)
    let rs = (ansi reset)
    let success = ($env.LAST_EXIT_CODE? | default 0 | into int) == 0
    let is_root = (id -u | str trim) == "0"
    let c1 = if $is_root { ansi light_yellow } else if $success { ansi blue } else { ansi yellow }
    let c2 = if $is_root { ansi light_red } else { ansi magenta }
    let c3 = if $is_root or not $success { ansi red } else { ansi cyan }
    $"(place)($dg)⋅($c1)❱($c2)❱($c3)❱($rs) "
  }

  def create_transient_right [] {
    let chrono = ($env.CHRONO? | default null)
    if $chrono == null { return "" }
    $"(ansi dark_gray)\(($chrono.gloss)\)(ansi reset)"
  }

  $env.TRANSIENT_PROMPT_COMMAND = { || create_transient_prompt }
  $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { || create_transient_right }

  $env.PATH = ($env.PATH | append "/home/zk/.local/bin")

  alias otter = otter-launcher
  alias zshell = otter-launcher
  alias cat = open

  # Each otter module is named for the command that runs it. do and ps are nushell built-ins, so the modules are of and sp;
  # bare ssh opens the host picker, and ssh with arguments is still ssh. help opens the launcher.
  alias help = otter-launcher
  alias lg = otter-launcher lg
  alias fo = otter-launcher fo
  alias of = otter-launcher of
  alias gr = otter-launcher gr
  alias ai = otter-launcher ai
  alias tp = otter-launcher tp
  alias sp = otter-launcher sp
  alias sd = otter-launcher sd
  alias jl = otter-launcher jl
  alias nx = otter-launcher nx
  alias bd = otter-launcher bd
  def --wrapped ssh [...args] {
    if ($args | is-empty) { otter-launcher ssh } else { ^ssh ...$args }
  }

  # eza keeps its own names so nushell's table ls stays.
  def la [path: path = "."] {
    eza $path -l -a --git --header --group-directories-first --icons=auto --git-repos --total-size --time-style=default --hyperlink --short-nix
  }
  alias lt = eza --tree --level=2 --group-directories-first --icons=auto --short-nix

  # eza --code prints nothing without a path argument, so lc supplies "."
  def lc [path: path = "."] { eza --code -l $path --short-nix }

  esofetch
  echo ""
''
