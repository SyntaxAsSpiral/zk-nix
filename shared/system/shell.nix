# Core shell kit for remote use. Headless hosts (seed, tm20) do not build
# themselves. No Wayland tools. btop's own config is not managed.
# btop compiles GPU support by default. cudaSupport adds the NVIDIA driver
# runpath. rocmSupport adds the ROCm SMI rpath, and that library is x86_64-only,
# so tm20 does not get it.
{
  pkgs,
  inputs,
  ...
}:

let
  btop = pkgs.btop.override {
    cudaSupport = true;
    rocmSupport = pkgs.stdenv.hostPlatform.isx86_64;
  };

  esoBase = pkgs.writeText "eso-base.jsonc" (builtins.toJSON {
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
  });

  esofetch = pkgs.writeShellApplication {
    name = "esofetch";
    runtimeInputs = with pkgs; [
      fastfetch
      jq
      chafa
    ];
    text = ''
      mapfile -t ICONS < <(find ${inputs.esotericons} -maxdepth 1 -type f -name '*.png')
      if [ "''${#ICONS[@]}" -eq 0 ]; then
        echo "esofetch: no icons found in ${inputs.esotericons}" >&2
        exit 1
      fi

      RANDOM_ICON="''${ICONS[$RANDOM % ''${#ICONS[@]}]}"

      # Pick a logo protocol the terminal draws. SSH carries TERM on its own, but TERM_PROGRAM
      # only if the client sends it, and kitty does not set it.
      case "''${TERM_PROGRAM:-}:''${TERM:-}" in
        kitty:*|ghostty:*|WezTerm:*|*:xterm-kitty|*:xterm-ghostty) LOGO_TYPE="kitty-direct" ;;
        iTerm.app:*|konsole:*)                                     LOGO_TYPE="iterm" ;;
        *)                                                         LOGO_TYPE="text" ;;
      esac
      # Over ssh the graphics image came out blank in kitty, so ssh gets the block-symbol logo.
      if [ -n "''${SSH_CONNECTION:-}" ]; then LOGO_TYPE="text"; fi

      if [ "$LOGO_TYPE" = text ]; then
        # Everything else gets block symbols, in a kmscon or kernel console and a herdr pane too.
        # fastfetch's own chafa logo needs the terminal's pixel size, and a console reports none:
        # it then drops to its built-in logo. So chafa draws the icon and fastfetch prints the text.
        art=$(mktemp)
        chafa --format=symbols --size=20x10 --fg-only --symbols=block+border+space "$RANDOM_ICON" |
          sed 's/\x1b\[?25[lh]//g' > "$art"
        jq --arg src "$art" '.logo.type = "file-raw" | .logo.source = $src | del(.logo.width)' ${esoBase} > /tmp/eso-fetch.jsonc
        fastfetch -c /tmp/eso-fetch.jsonc
        rm -f "$art"
      else
        jq --arg src "$RANDOM_ICON" --arg type "$LOGO_TYPE" '.logo.source = $src | .logo.type = $type' ${esoBase} > /tmp/eso-fetch.jsonc
        exec fastfetch -c /tmp/eso-fetch.jsonc
      fi
    '';
  };
in
{
  environment.systemPackages = [
    esofetch
    pkgs.git
    pkgs.eza
    btop
    pkgs.yazi
    pkgs.fastfetch
    pkgs.gum
    pkgs.nano
    pkgs.tmux
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.file
    # yazi previews and sqlite for anything that reads a database
    pkgs.sqlite
    pkgs.imagemagick
    pkgs.poppler-utils
    pkgs.ffmpegthumbnailer
  ];
}
