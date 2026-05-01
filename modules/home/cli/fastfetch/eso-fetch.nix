{ pkgs, inputs, ... }:

let
  esoFetch = pkgs.writeShellApplication {
    name = "eso-fetch";
    runtimeInputs = with pkgs; [
      fastfetch
      jq
    ];
    text = ''
      mapfile -t ICONS < <(find ${inputs.esotericons} -maxdepth 1 -type f -name '*.png')
      if [ "''${#ICONS[@]}" -eq 0 ]; then
        echo "eso-fetch: no icons found in ${inputs.esotericons}" >&2
        exit 1
      fi

      RANDOM_ICON="''${ICONS[$RANDOM % ''${#ICONS[@]}]}"

      # auto can't detect the client terminal over SSH — use TERM_PROGRAM (forwarded via SendEnv)
      if [ -n "''${SSH_CONNECTION:-}" ]; then
        case "''${TERM_PROGRAM:-}" in
          kitty|ghostty|WezTerm) LOGO_TYPE="kitty-direct" ;;
          iTerm.app|konsole)     LOGO_TYPE="iterm" ;;
          *)                     LOGO_TYPE="chafa" ;;
        esac
        jq --arg src "$RANDOM_ICON" --arg type "$LOGO_TYPE" '.logo.source = $src | .logo.type = $type' "$HOME/.config/fastfetch/eso-base.jsonc" > /tmp/eso-fetch.jsonc
      else
        jq --arg src "$RANDOM_ICON" '.logo.source = $src' "$HOME/.config/fastfetch/eso-base.jsonc" > /tmp/eso-fetch.jsonc
      fi

      exec fastfetch -c /tmp/eso-fetch.jsonc
    '';
  };
in
{
  xdg.configFile."fastfetch/eso-base.jsonc".text = builtins.toJSON {
    display = { separator = "  "; };
    logo = {
      type = "auto";
      width = 20;
      padding = {
        top = 2;
        left = 2;
      };
    };
    modules = [
      "break"
      "break"
      "break"
      { type = "colors"; symbol = "circle"; }
      "break"
      "title"
      { type = "os"; key = "os    "; keyColor = "38;2;243;139;168"; }
      { type = "kernel"; key = "kernel"; keyColor = "38;2;166;227;161"; }
      {
        type = "command";
        key = "hw    ";
        keyColor = "38;2;249;226;175";
        text = "fastfetch --json --structure CPU:GPU --logo none | jq -r '(.[] | select(.type == \"CPU\") | .result.cpu | sub(\"AMD Ryzen (?<v>[0-9]) \"; \"R\\(.v) \") | sub(\" [0-9]+-Core Processor\"; \"\") | sub(\"AMD Custom APU \"; \"Deck \")) + \" / \" + (.[] | select(.type == \"GPU\") | .result[0].name | sub(\"GeForce \"; \"\") | sub(\"NVIDIA \"; \"\") | sub(\"AMD Radeon \"; \"\") | sub(\"AMD Custom GPU\"; \"RDNA2\"))'";
      }
      { type = "packages"; key = "pkgs  "; keyColor = "38;2;116;199;236"; }
      { type = "uptime"; key = "uptime"; keyColor = "38;2;203;166;247"; format = "{?days}{days}d {?}{hours}h {minutes}m"; }
      "break"
    ];
  };

  home.packages = [
    esoFetch
  ];
}
