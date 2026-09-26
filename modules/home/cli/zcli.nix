# zcli — mesh build/deploy wrapper. Flake path comes from the system-level
# my.flakePath option (osConfig), so it never needs to be passed per host.
{ pkgs, osConfig, ... }:

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
    text = ''exec bash ${./zcli-sync.sh} "$@"'';
  };
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "zcli" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          VERSION="0.5.0"
          HOSTNAME="$(${pkgs.nettools}/bin/hostname)"
          CONTROL_HOST="zrrh"
          FLAKE_PATH="${osConfig.my.flakePath}"

          # adeck's DNS is Mullvad. Mesh names do not resolve there; SSH by tailnet IP.
          # nixos-rebuild runs SSH as root, which does not have zk's known_hosts.
          export NIX_SSHOPTS="-o UserKnownHostsFile=/home/zk/.ssh/known_hosts -o StrictHostKeyChecking=accept-new"
          mesh_addr() {
            local name="$1"
            if [[ "$HOSTNAME" != "adeck" ]]; then
              printf '%s' "$name"
              return
            fi
            case "$name" in
              nxiz) printf '%s' 100.115.135.104 ;;
              zrrh) printf '%s' 100.77.90.79 ;;
              adeck) printf '%s' 100.89.32.9 ;;
              tm20) printf '%s' 100.123.184.5 ;;
              *) fail "no tailscale address for $name" ;;
            esac
          }

          usage() {
            cat <<EOF
      zcli $VERSION — mesh build/deploy wrapper

      Usage:
        zcli sync [host|all] [host ...] [--dry]
        zcli build <host|all> [host ...] [--dry]
        zcli deploy <host|all> [host ...] [--dry]
        zcli image tm20 [--dry]

      Behavior:
        - sync defaults to this host; adeck:/mnt/echo/nix-os is always the source
        - sync all includes adeck/nxiz/zrrh flake files + secrets, and tm20 secrets only
        - sync publishes committed + staged content; other local files stay local
        - on nxiz/adeck: evaluation happens locally, builds happen on zrrh
        - on zrrh: build/deploy runs locally on zrrh
        - local flake changes are used directly; nothing is pushed or synced to git remotes
        - build/deploy/image auto-run: git -C <flake> add -A
        - deploy prepares the next boot; it does not switch the running system

      Examples:
        zcli sync --dry
        zcli sync all
        zcli build nxiz --dry
        zcli build nxiz adeck
        zcli deploy nxiz
        zcli deploy nxiz --dry
        zcli deploy all
        zcli image tm20 --dry
      EOF
          }

          fail() {
            echo "Error: $*" >&2
            exit 1
          }

          require_cmd() {
            command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
          }

          ensure_flake_path() {
            [[ -d "$FLAKE_PATH" ]] || fail "flake path does not exist: $FLAKE_PATH"
          }

          stage_flake() {
            exec 9>"$FLAKE_PATH/.git/zcli.lock"
            ${pkgs.util-linux}/bin/flock -n 9 || fail "another sync/build/deploy is using $FLAKE_PATH"
            [[ ! -e "$FLAKE_PATH/.git/zcli-sync-incomplete" ]] || fail "interrupted sync; complete it before building"
            if [[ -f "$FLAKE_PATH/.git/zcli-sync-receipt" ]]; then
              cat "$FLAKE_PATH/.git/zcli-sync-receipt"
            fi
            ${pkgs.git}/bin/git -C "$FLAKE_PATH" add -A
          }

          validate_host() {
            case "$1" in
              nxiz|zrrh|adeck|tm20) ;;
              *) fail "unknown host: $1 (valid: nxiz zrrh adeck tm20 all)" ;;
            esac
          }

          expand_hosts() {
            local mode="$1"
            shift
            local raw=("$@")
            local out=()
            local h
            local seen_key
            declare -A seen=()

            for h in "''${raw[@]}"; do
              if [[ "$h" == "all" ]]; then
                if [[ "$mode" == "deploy" ]]; then
                  for seen_key in nxiz adeck zrrh; do
                    if [[ -z "''${seen[$seen_key]+x}" ]]; then
                      out+=("$seen_key")
                      seen[$seen_key]=1
                    fi
                  done
                else
                  for seen_key in nxiz adeck zrrh; do
                    if [[ -z "''${seen[$seen_key]+x}" ]]; then
                      out+=("$seen_key")
                      seen[$seen_key]=1
                    fi
                  done
                fi
              else
                validate_host "$h"
                if [[ -z "''${seen[$h]+x}" ]]; then
                  out+=("$h")
                  seen[$h]=1
                fi
              fi
            done

            printf '%s\n' "''${out[@]}"
          }

          parse_build_args() {
            BUILD_DRY=false
            BUILD_HOSTS=()

            while [[ $# -gt 0 ]]; do
              case "$1" in
                --dry)
                  BUILD_DRY=true
                  shift ;;
                -h|--help)
                  usage
                  exit 0 ;;
                -*)
                  fail "unknown flag for build: $1" ;;
                *)
                  BUILD_HOSTS+=("$1")
                  shift ;;
              esac
            done

            [[ ''${#BUILD_HOSTS[@]} -gt 0 ]] || fail "build requires at least one host"
          }

          parse_deploy_args() {
            DEPLOY_DRY=false
            DEPLOY_HOSTS=()

            while [[ $# -gt 0 ]]; do
              case "$1" in
                --dry)
                  DEPLOY_DRY=true
                  shift ;;
                -h|--help)
                  usage
                  exit 0 ;;
                -*)
                  fail "unknown flag for deploy: $1" ;;
                *)
                  DEPLOY_HOSTS+=("$1")
                  shift ;;
              esac
            done

            [[ ''${#DEPLOY_HOSTS[@]} -gt 0 ]] || fail "deploy requires at least one host"
          }

          ensure_builder_reachable_if_needed() {
            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              ${pkgs.tailscale}/bin/tailscale ping -c 1 --timeout 2s "$CONTROL_HOST" >/dev/null 2>&1 || \
                fail "$CONTROL_HOST is unreachable via Tailscale"
            fi
          }

          ensure_target_reachable_if_remote() {
            local target="$1"
            if [[ "$target" != "$HOSTNAME" ]]; then
              ${pkgs.tailscale}/bin/tailscale ping -c 1 --timeout 2s "$target" >/dev/null 2>&1 || \
                fail "$target is unreachable via Tailscale"
            fi
          }

          run_build() {
            local target="$1"
            local mode
            local -a cmd

            if [[ "$BUILD_DRY" == "true" ]]; then
              mode="dry-build"
            else
              mode="build"
            fi

            cmd=(
              sudo
              --preserve-env=NIX_SSHOPTS
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$mode"
              --flake "$FLAKE_PATH#$target"
              --use-substitutes
            )

            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              cmd+=(--build-host "zk@$(mesh_addr "$CONTROL_HOST")")
            fi

            echo "==> $mode $target"
            if [[ "$HOSTNAME" == "$CONTROL_HOST" ]]; then
              echo "    eval host: $HOSTNAME"
              echo "    build host: local ($CONTROL_HOST)"
            else
              echo "    eval host: $HOSTNAME"
              echo "    build host: $CONTROL_HOST"
            fi
            echo "    flake: $FLAKE_PATH#$target"
            "''${cmd[@]}"

          }

          run_deploy() {
            local target="$1"
            local mode
            local -a cmd

            if [[ "$DEPLOY_DRY" == "true" ]]; then
              mode="dry-activate"
            else
              mode="boot"
            fi

            cmd=(
              sudo
              --preserve-env=NIX_SSHOPTS
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$mode"
              --flake "$FLAKE_PATH#$target"
              --use-substitutes
            )

            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              cmd+=(--build-host "zk@$(mesh_addr "$CONTROL_HOST")")
            fi

            if [[ "$target" != "$HOSTNAME" ]]; then
              cmd+=(--target-host "zk@$(mesh_addr "$target")" --sudo)
            fi

            # nixos-rebuild-ng re-execs the target's nixos-rebuild. For aarch64
            # tm20 that is a qemu binary on x86_64 and nix sandbox then dies:
            # "this system does not support the kernel namespaces".
            if [[ "$target" == "tm20" ]]; then
              cmd+=(--no-reexec)
            fi

            if [[ "$DEPLOY_DRY" == "true" ]]; then
              echo "==> dry-activate $target"
            else
              echo "==> deploy $target"
            fi
            if [[ "$HOSTNAME" == "$CONTROL_HOST" ]]; then
              echo "    eval host: $HOSTNAME"
              echo "    build host: local ($CONTROL_HOST)"
            else
              echo "    eval host: $HOSTNAME"
              echo "    build host: $CONTROL_HOST"
            fi
            if [[ "$target" == "$HOSTNAME" ]]; then
              echo "    target host: local"
            else
              echo "    target host: $target"
            fi
            echo "    flake: $FLAKE_PATH#$target"
            "''${cmd[@]}"

            if [[ "$DEPLOY_DRY" != "true" && "$target" != "$HOSTNAME" ]]; then
              local system_path
              system_path="$(${pkgs.nix}/bin/nix eval --raw "$FLAKE_PATH#nixosConfigurations.$target.config.system.build.toplevel.outPath")"
              if [[ "$HOSTNAME" == "$CONTROL_HOST" ]]; then
                sudo ${pkgs.nix}/bin/nix-store --realise "$system_path" --add-root "/nix/var/nix/gcroots/zcli-$target"
              else
                ${pkgs.openssh}/bin/ssh "zk@$(mesh_addr "$CONTROL_HOST")" sudo nix-store --realise "$system_path" --add-root "/nix/var/nix/gcroots/zcli-$target"
              fi
            fi
          }

          parse_image_args() {
            IMAGE_DRY=false
            IMAGE_HOSTS=()

            while [[ $# -gt 0 ]]; do
              case "$1" in
                --dry)
                  IMAGE_DRY=true
                  shift ;;
                -h|--help)
                  usage
                  exit 0 ;;
                -*)
                  fail "unknown flag for image: $1" ;;
                *)
                  IMAGE_HOSTS+=("$1")
                  shift ;;
              esac
            done

            [[ ''${#IMAGE_HOSTS[@]} -gt 0 ]] || fail "image requires at least one host"
          }

          validate_image_host() {
            case "$1" in
              tm20) ;;
              *) fail "sd image is only defined for tm20 (got: $1)" ;;
            esac
          }

          run_image() {
            local target="$1"
            local -a cmd

            validate_image_host "$target"

            cmd=(
              ${pkgs.nix}/bin/nix
              build
              "$FLAKE_PATH#nixosConfigurations.$target.config.system.build.sdImage"
              --out-link "$FLAKE_PATH/result-sd-$target"
            )

            if [[ "$IMAGE_DRY" == "true" ]]; then
              cmd+=(--dry-run)
            fi

            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              cmd+=(
                --builders "ssh://zk@$(mesh_addr "$CONTROL_HOST") aarch64-linux,x86_64-linux - 8 1 kvm,nixos-test,benchmark,big-parallel"
                --max-jobs 0
              )
            fi

            echo "==> sd-image $target"
            if [[ "$HOSTNAME" == "$CONTROL_HOST" ]]; then
              echo "    eval/build host: local ($CONTROL_HOST)"
            else
              echo "    eval host: $HOSTNAME"
              echo "    build host: $CONTROL_HOST (aarch64 via binfmt)"
            fi
            echo "    flake: $FLAKE_PATH#nixosConfigurations.$target.config.system.build.sdImage"
            "''${cmd[@]}"
          }

          # Sync/help work independently of the local flake and builder.
          case "''${1:-}" in
            sync)
              shift
              exec ${sync}/bin/zcli-sync "$@"
              ;;
            help|--help|-h)
              usage
              exit 0
              ;;
          esac

          require_cmd sudo
          require_cmd ${pkgs.nixos-rebuild}/bin/nixos-rebuild
          require_cmd ${pkgs.git}/bin/git
          require_cmd ${pkgs.tailscale}/bin/tailscale
          ensure_flake_path

          [[ $# -gt 0 ]] || {
            usage
            exit 1
          }

          case "$1" in
            build)
              shift
              parse_build_args "$@"
              mapfile -t hosts < <(expand_hosts build "''${BUILD_HOSTS[@]}")
              ensure_builder_reachable_if_needed
              stage_flake
              for host in "''${hosts[@]}"; do
                run_build "$host"
              done
              ;;
            deploy)
              shift
              parse_deploy_args "$@"
              mapfile -t hosts < <(expand_hosts deploy "''${DEPLOY_HOSTS[@]}")
              ensure_builder_reachable_if_needed
              stage_flake
              for host in "''${hosts[@]}"; do
                ensure_target_reachable_if_remote "$host"
                run_deploy "$host"
              done
              ;;
            image)
              shift
              parse_image_args "$@"
              mapfile -t hosts < <(expand_hosts build "''${IMAGE_HOSTS[@]}")
              ensure_builder_reachable_if_needed
              stage_flake
              for host in "''${hosts[@]}"; do
                run_image "$host"
              done
              ;;
            help|--help|-h)
              usage
              ;;
            *)
              fail "unknown command: $1"
              ;;
          esac
    '')
  ];
}
