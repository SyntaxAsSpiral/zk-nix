# zcli — mesh sync plus build/deploy. Canonical source is adeck:/mnt/echo/nix-os.
# Build, deploy, and image eval on zrrh via nh. Direct nh os stays local.
{ pkgs, ... }:

let
  sync = pkgs.writeShellApplication {
    name = "zcli-sync";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      findutils
      git
      openssh
      rsync
      util-linux
    ];
    text = ''exec bash ${../../../scripts/zcli/zcli-sync.sh} "$@"'';
  };
  contextPython = pkgs.python3.withPackages (ps: [
    ps.pyyaml
    ps.python-frontmatter
  ]);
  context = pkgs.writeShellApplication {
    name = "zcli-context";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      git
      openssh
      rsync
    ];
    text = ''exec env ZCLI_CONTEXT_PYTHON=${contextPython}/bin/python bash ${../../../scripts/zcli/zcli-context.sh} "$@"'';
  };
  run = pkgs.writeShellApplication {
    name = "zcli-run";
    runtimeInputs = [
      sync
      pkgs.bash
      pkgs.coreutils
      pkgs.nettools
      pkgs.openssh
      pkgs.figlet
      pkgs.toilet
      pkgs.lolcat
    ];
    text = ''exec bash ${../../../scripts/zcli/zcli-run.sh} "$@"'';
  };
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "zcli" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      case "''${1:-}" in
        help|--help|-h)
          exec ${run}/bin/zcli-run help ;;
        "")
          ${run}/bin/zcli-run help
          exit 1 ;;
        sync)
          shift
          if [[ "''${1:-}" == context ]]; then
            shift
            exec ${context}/bin/zcli-context sync "$@"
          fi
          printf '☠☠☠ >>> RUNTIME·SYNC·INITIATED ☠☠☠\n'
          exec ${sync}/bin/zcli-sync "$@" ;;
        assemble)
          shift
          exec ${context}/bin/zcli-context assemble "$@" ;;
        deploy)
          if [[ "''${2:-}" == context ]]; then
            shift 2
            exec ${context}/bin/zcli-context deploy "$@"
          fi
          printf '☠☠☠ >>> DEPLOY·PROTOCOL·INITIATED ☠☠☠\n'
          exec ${run}/bin/zcli-run "$@" ;;
        build|image|wake)
          printf '☠☠☠ >>> %s·PROTOCOL·INITIATED ☠☠☠\n' "''${1^^}"
          exec ${run}/bin/zcli-run "$@" ;;
        *)
          echo "☠ Unknown protocol: $1" >&2
          ${run}/bin/zcli-run help >&2
          exit 1 ;;
      esac
    '')
  ];
}
