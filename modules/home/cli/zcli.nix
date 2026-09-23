# zcli — mesh build/deploy wrapper. Flake path comes from the system-level
# my.flakePath option (osConfig), so it never needs to be passed per host.
{ pkgs, osConfig, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "zcli" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          VERSION="0.4.0"
          HOSTNAME="$(${pkgs.nettools}/bin/hostname)"
          CONTROL_HOST="zrrh"
          FLAKE_PATH="${osConfig.my.flakePath}"

          usage() {
            cat <<EOF
      zcli $VERSION — mesh build/deploy wrapper

      Usage:
        zcli build <host|all> [host ...] [--dry]
        zcli deploy <host|all> [host ...] [--dry]
        zcli image tm20 [--dry]

      Behavior:
        - on nxiz/adeck: evaluation happens locally, builds happen on zrrh
        - on zrrh: build/deploy runs locally on zrrh
        - local flake changes are used directly; nothing is pushed or synced to git remotes
        - zcli auto-runs: git -C <flake> add -A

      Examples:
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
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$mode"
              --flake "$FLAKE_PATH#$target"
              --use-substitutes
            )

            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              cmd+=(--build-host "zk@$CONTROL_HOST")
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
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$mode"
              --flake "$FLAKE_PATH#$target"
              --use-substitutes
            )

            if [[ "$HOSTNAME" != "$CONTROL_HOST" ]]; then
              cmd+=(--build-host "zk@$CONTROL_HOST")
            fi

            if [[ "$target" != "$HOSTNAME" ]]; then
              cmd+=(--target-host "zk@$target" --sudo)
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
                ${pkgs.openssh}/bin/ssh "zk@$CONTROL_HOST" sudo nix-store --realise "$system_path" --add-root "/nix/var/nix/gcroots/zcli-$target"
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
                --builders "ssh://zk@$CONTROL_HOST aarch64-linux,x86_64-linux - 8 1 kvm,nixos-test,benchmark,big-parallel"
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
