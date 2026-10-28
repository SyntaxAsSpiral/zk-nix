# Core shell kit for remote use. Headless hosts (seed, tm20) do not build
# themselves. No Wayland tools. btop's own config is not managed.
# btop compiles GPU support by default. cudaSupport adds the NVIDIA driver
# runpath. rocmSupport adds the ROCm SMI rpath, and that library is x86_64-only,
# so tm20 does not get it.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Home Manager writes this same file on the other hosts. tm20 has no Home Manager.
  nushellConfig = import ../home/nushell-config.nix;
  perHost = {
    nxiz.installNushellConfig = false;
    zrrh.installNushellConfig = false;
    adeck.installNushellConfig = false;
    seed.installNushellConfig = false;
    tm20.installNushellConfig = true;
  };
  installNushellConfig = perHost.${config.my.host}.installNushellConfig;
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

      # The getty at boot is the Linux console. It cannot draw the icon.
      case "''${TERM:-}" in
        linux|dumb)
          exec fastfetch
          ;;
      esac
      tty_path=$(tty 2>/dev/null || true)
      case "$tty_path" in
        /dev/tty[0-9]|/dev/tty[0-9][0-9])
          exec fastfetch
          ;;
      esac

      # A remote session has no local terminal. Pick a logo protocol the client can draw.
      if [ -n "''${SSH_CONNECTION:-}" ]; then
        case "''${TERM_PROGRAM:-}" in
          kitty|ghostty|WezTerm) LOGO_TYPE="kitty-direct" ;;
          iTerm.app|konsole)     LOGO_TYPE="iterm" ;;
          *)                     LOGO_TYPE="chafa" ;;
        esac
        jq --arg src "$RANDOM_ICON" --arg type "$LOGO_TYPE" '.logo.source = $src | .logo.type = $type' ${esoBase} > /tmp/eso-fetch.jsonc
      else
        jq --arg src "$RANDOM_ICON" '.logo.source = $src' ${esoBase} > /tmp/eso-fetch.jsonc
      fi

      exec fastfetch -c /tmp/eso-fetch.jsonc
    '';
  };
in
{
  environment.systemPackages = [
    pkgs.nushell
    esofetch
    pkgs.git
    pkgs.gh
    pkgs.eza
    pkgs.bat
    pkgs.fzf
    btop
    pkgs.yazi
    pkgs.fastfetch
  ];

  system.activationScripts.shellKit = lib.mkIf installNushellConfig {
    deps = [ "users" ];
    text = ''
      install -d -m 0755 -o zk -g users /home/zk/.config/nushell
      install -m 0644 -o zk -g users ${pkgs.writeText "config.nu" nushellConfig} /home/zk/.config/nushell/config.nu
    '';
  };
}
