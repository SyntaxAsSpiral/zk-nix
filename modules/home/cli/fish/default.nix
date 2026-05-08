# Fish shell config (zrrh) — styled to loosely match Nushell UX
_:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      set -gx PATH $HOME/.local/bin $PATH
      fastfetch
      echo
    '';

    shellAliases = {
      # Hermes TUI/CLI on adeck
      herm = "ssh -t zk@adeck herm";
      hermes = "ssh -t zk@adeck hermes";
    };

    functions = {
      gemini = "npx --yes @google/gemini-cli@latest $argv";
      codex = "npx --yes @openai/codex@latest $argv";
      crush = "npx --yes @charmland/crush@latest $argv";

      fish_prompt = ''
        set -l last_status $status
        set -l cwd (string replace -r "^$HOME" "~" (pwd))

        # success: pink → teal → orange
        set -l c1 eb6f92
        set -l c2 9ccfd8
        set -l c3 FFA066

        if test (id -u) -eq 0
          # root: gold → orange → red
          set c1 E6C384
          set c2 FFA066
          set c3 C34043
        else if test $last_status -ne 0
          # error: sanguis solix — muted slate navy → dusty crimson → soft violet
          set c1 6070B0
          set c2 B86878
          set c3 8A60A8
        end

        printf "\n"
        set_color DCD7BA
        printf "%s" $cwd
        set_color $c1
        printf "❱"
        set_color $c2
        printf "❱"
        set_color $c3
        printf "❱ "
        set_color normal
      '';

      fish_right_prompt = ''
        set -l hour (date "+%H")
        set -l emoji "🌉"

        if test $hour -lt 7
          set emoji "🌄"
        else if test $hour -lt 12
          set emoji "🌇"
        else if test $hour -lt 18
          set emoji "🌆"
        else if test $hour -lt 22
          set emoji "🌃"
        end

        set_color 6e738d
        printf "%s %s" (date "+%H:%M") $emoji
        set_color normal
      '';
    };
  };

  # Catppuccin Macchiato syntax colors
  xdg.configFile."fish/conf.d/10-catppuccin-macchiato.fish".text = ''
    set -g fish_color_normal cad3f5
    set -g fish_color_command 8aadf4
    set -g fish_color_param f0c6c6
    set -g fish_color_keyword ed8796
    set -g fish_color_quote a6da95
    set -g fish_color_redirection f5bde6
    set -g fish_color_end f5a97f
    set -g fish_color_comment 8087a2
    set -g fish_color_error ed8796
    set -g fish_color_selection --background=363a4f
    set -g fish_color_search_match --background=363a4f
    set -g fish_color_operator f5bde6
    set -g fish_color_escape ee99a0
    set -g fish_color_autosuggestion 6e738d
    set -g fish_color_cwd eed49f
    set -g fish_color_user 8bd5ca
    set -g fish_color_host 8aadf4
    set -g fish_color_status ed8796
  '';
}
