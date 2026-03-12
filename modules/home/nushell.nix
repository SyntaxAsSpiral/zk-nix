{
  osConfig,
  ...
}:

let
  perHost = {
    nxiz = {
      loginFile = ''
        if (tty) == "/dev/tty1" {
          sleep 2sec
          start-hyprland
        }
      '';
      extraConfig = ''
        if ($env | get -o TERM_PROGRAM | default "") == "vscode" {
          fastfetch
        } else {
          eso-fetch
        }
        echo ""
        echo ""

        # adeck screen control
        alias deck-screen-off = ssh zk@adeck 'export NIRI_SOCKET="$(ls -1 /run/user/$(id -u)/niri.*.sock | head -n1)"; niri msg output eDP-1 off'
        alias deck-screen-on = ssh zk@adeck 'export NIRI_SOCKET="$(ls -1 /run/user/$(id -u)/niri.*.sock | head -n1)"; niri msg output eDP-1 on'
        alias deck-resume = ssh zk@adeck 'uid=$(id -u); sock=$(find /run/user/$uid -maxdepth 1 -type s -name "niri.*.sock" | head -n1); [ -n "$sock" ] || { echo "No Niri socket found"; exit 1; }; NIRI_SOCKET="$sock" niri msg action power-on-monitors'

        # Wake-on-LAN helper routed through adeck (hardwired to zrrh)
        alias wake-zrrh = ssh zk@adeck 'wakeonlan -i 10.77.0.255 60:cf:84:61:d8:00'

        # Reboot all mesh workstations: remotes first, local last
        alias mesh-reboot = do {
          ssh zk@adeck 'sudo reboot'
          ssh zk@zrrh 'sudo reboot'
          sudo reboot
        }

        def build-nixos [
          --dry  # Dry-build only, no activation
        ] {
          if $dry {
            zcli rebuild --dry
          } else {
            zcli rebuild
          }
        }

        def deploy-adeck [
          --dry  # Dry-build only, no remote switch
        ] {
          if $dry {
            zcli deploy adeck --dry
          } else {
            zcli deploy adeck
          }
        }
      '';
    };

    adeck = {
      loginFile = ''
        if (tty) == "/dev/tty1" {
        niri-session
        }
      '';
      extraConfig = ''
        fastfetch
        echo ""

        # Wake-on-LAN helpers (adeck -> zrrh/nxiz)
        alias wake-zrrh = wakeonlan -i 10.77.0.255 60:cf:84:61:d8:00
        alias wake-nxiz = wakeonlan -i 192.168.0.255 fc:34:97:3b:6e:99
        def wake-mesh [] {
          wake-zrrh
          sleep 1sec
          wake-nxiz
        }
      '';
    };

    zrrh = {
      loginFile = ''
        if (tty) == "/dev/tty1" {
        niri-session
        }
      '';
      extraConfig = ''
        fastfetch
        echo ""

        # Wake-on-LAN helper (zrrh -> nxiz)
        alias wake-nxiz = wakeonlan -i 192.168.0.255 fc:34:97:3b:6e:99
      '';
    };
  };
  h = perHost.${osConfig.my.host};
in
{
  programs.nushell = {
    enable = true;
    configFile.text = ''
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
    '';

    loginFile.text = h.loginFile;

    extraConfig = ''
      $env.PATH = ($env.PATH | append "/home/zk/.local/bin")

      # Coding agents (always-latest via npx)
      def --wrapped gemini [...args] { npx --yes @google/gemini-cli@latest ...$args }
      def --wrapped codex [...args] { npx --yes @openai/codex@latest ...$args }
      def --wrapped crush [...args] { npx --yes @charmland/crush@latest ...$args }

    ''
    + h.extraConfig;
  };
}
