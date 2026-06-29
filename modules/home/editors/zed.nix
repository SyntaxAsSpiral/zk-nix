{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;

    extensions = [
      "nix"
      "toml"
      "elixir"
      "make"
      "catppuccin-icons"
      "catppuccin-blur"
    ];

    extraPackages = with pkgs; [
      nixd
      nil
      nixfmt
      rust-analyzer
      elixir-ls
      shellcheck
    ];

    userSettings = {
      lsp = {
        nixd = {
          binary = {
            path = "nixd";
          };
        };
        rust-analyzer = {
          binary = {
            path = "rust-analyzer";
          };
        };
        elixir-ls = {
          binary = {
            path = "elixir-ls";
          };
          settings = {
            dialyzerEnabled = true;
          };
        };
      };

      languages = {
        Nix = {
          language_servers = [ "nixd" ];
          formatter = "language_server";
        };
        Elixir = {
          language_servers = [
            "!lexical"
            "elixir-ls"
            "!next-ls"
          ];
          format_on_save = "on";
        };
        HEEX = {
          language_servers = [
            "!lexical"
            "elixir-ls"
            "!next-ls"
          ];
          format_on_save = "on";
        };
      };
      outline_panel = {
        dock = "left";
      };
      collaboration_panel = {
        dock = "left";
      };

      agent = {
        default_model = {
          provider = "ZRRH";
          model = "openai/gpt-oss-20b";
          enable_thinking = false;
        };
        favorite_models = [ ];
        model_parameters = [ ];
      };

      language_models = {
        openai_compatible = {
          ZRRH = {
            api_url = "http://adeck:1234/v1";
            available_models = [
              {
                name = "openai/gpt-oss-20b";
                max_tokens = 200000;
                max_output_tokens = 32000;
                max_completion_tokens = 200000;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                  chat_completions = true;
                };
              }
              {
                name = "qwen2.5-coder-14b-instruct";
                max_tokens = 32768;
                max_output_tokens = 8192;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                  chat_completions = true;
                };
              }
              {
                name = "deepseek-coder-v2-lite-instruct";
                max_tokens = 128000;
                max_output_tokens = 8192;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                  chat_completions = true;
                };
              }
              {
                name = "mistralai/codestral-22b-v0.1";
                max_tokens = 32768;
                max_output_tokens = 8192;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                  chat_completions = true;
                };
              }
              {
                name = "mistral-small-24b-instruct-2501-heretic-i1";
                max_tokens = 32768;
                max_output_tokens = 8192;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                  chat_completions = true;
                };
              }
            ];
          };
        };
      };

      agent_servers = {
        pi-acp = {
          type = "registry";
        };
      };

      session = {
        trust_all_worktrees = true;
      };

      auto_install_extensions = {
        elixir = true;
        make = true;
        nix = true;
        toml = true;
        catppuccin-icons = true;
      };

      buffer_font_family = "RecMonoCasual Nerd Font Mono";
      buffer_font_size = 12.0;

      theme = {
        dark = "Catppuccin Frappé (Blur) [Heavy]";
        light = "Catppuccin Latte";
        mode = "dark";
      };

      ui_font_size = 14;
      icon_theme = "Catppuccin Mocha";
    };
  };
}
