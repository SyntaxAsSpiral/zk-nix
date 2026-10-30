{ pkgs, ... }:
let
  # yatline 0.5.0 still reads Url.is_search, which yazi 26.9 flags as deprecated with a popup.
  yatline = pkgs.yaziPlugins.yatline.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace main.lua --replace-fail "cwd.is_search" "cwd.spec.is_search"
    '';
  });
  # yazi's preset icon table with its hex colours mapped to ANSI names.
  iconTheme = pkgs.runCommand "yazi-icon-theme.toml" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./icon-ansi.py} ${pkgs.yazi-unwrapped.srcs.code_src}/yazi-config/preset/theme-dark.toml > $out
  '';
in
{
  # yazi itself comes from the shell kit (shared/system/shell.nix).
  # Everything else stays at yazi's defaults; add a setting only on purpose.
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;
    shellWrapperName = "yy";

    settings = {
      mgr.ratio = [
        1
        2
        4
      ];
      # Previews match the otter launcher's: eza tree for directories, glow for markdown, bat for csv.
      plugin.prepend_previewers = [
        {
          url = "*/";
          run = "piper -- eza --tree --level=2 --icons=always --color=always \"$1\"";
        }
        {
          url = "*.md";
          run = "piper -- CLICOLOR_FORCE=1 glow -w=$w -s=\"$HOME/.config/glow/styles/catppuccin-macchiato-custom.json\" \"$1\"";
        }
        {
          url = "*.csv";
          run = "piper -- bat --color=always --style=numbers --line-range=:200 \"$1\"";
        }
        {
          mime = "application/sqlite3";
          run = "piper -- sqlite3 \"$1\" \".schema --indent\"";
        }
      ];
      # git.yazi: status signs in the file list.
      plugin.prepend_fetchers = [
        {
          url = "*";
          run = "git";
          group = "git";
        }
        {
          url = "*/";
          run = "git";
          group = "git";
        }
      ];
    };

    keymap.mgr.prepend_keymap = [
      {
        on = "l";
        run = "plugin smart-enter";
        desc = "Enter the child directory, or open the file";
      }
      {
        on = [
          "g"
          "i"
        ];
        run = "plugin lazygit";
        desc = "run lazygit";
      }
      {
        on = "T";
        run = "plugin toggle-pane max-preview";
        desc = "Maximize or restore the preview pane";
      }
    ];

    plugins = {
      inherit (pkgs.yaziPlugins)
        full-border
        git
        lazygit
        piper
        smart-enter
        toggle-pane
        ;
      inherit yatline;
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
      require("smart-enter"):setup { open_multi = true }
      -- yatline: ANSI colours only, so the bar follows the terminal. It keeps yazi's own header.
      -- The count always shows the files in the directory, and selected and yanked ones only when there are any
      -- (params: filter, zero_check).
      -- Its extension icon calls a deprecated yazi API, so params = { false } leaves it off.
      require("yatline"):setup({
        display_header_line = false,
        show_background = false,
        -- pixel-step ends (Nerd Font U+E0C6 and U+E0C4)
        section_separator = { open = "", close = "" },
        inverse_separator = { open = "░", close = "░" },
        style_a = {
          fg = "black",
          bg = "blue",
          bg_mode = { normal = "blue", select = "red", un_set = "red" },
        },
        style_b = { fg = "white", bg = "brightblack" },
        style_c = { fg = "reset", bg = "reset" },
        status_line = {
          left = {
            section_a = { { type = "string", name = "tab_mode" } },
            section_b = { { type = "string", name = "hovered_size" } },
            section_c = {
              { type = "string", name = "hovered_path" },
              { type = "coloreds", name = "count", params = { true, true } },
            },
          },
          right = {
            section_a = { { type = "string", name = "cursor_position" } },
            section_b = { { type = "string", name = "cursor_percentage" } },
            section_c = {
              { type = "string", name = "hovered_file_extension", params = { false } },
              { type = "coloreds", name = "permissions" },
            },
          },
        },
      })
    '';
  };

  xdg.configFile."yazi/theme.toml".source = iconTheme;
}
