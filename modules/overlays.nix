{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default

    # Yazi plugins from yazi-rs/plugins monorepo
    (_final: _prev: {
      yaziPlugins = {
        lazygit = inputs.yazi-plugins + "/lazygit.yazi";
        full-border = inputs.yazi-plugins + "/full-border.yazi";
        git = inputs.yazi-plugins + "/git.yazi";
        smart-enter = inputs.yazi-plugins + "/smart-enter.yazi";
      };
    })

    # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
    (_final: prev: {
      tumbler = prev.tumbler.overrideAttrs (old: {
        buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
      });
    })

    # Fix lmstudio lms CLI: preserve Bun binary layout.
    # --set-rpath on this Bun binary corrupts ELF section mapping and crashes in ld.so.
    (_final: prev: {
      lmstudio = prev.lmstudio.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ [
            prev.coreutils
            prev.gnugrep
            prev.patchelf
          ];

        buildCommand = (old.buildCommand or "") + ''
          bwrap_target="$(readlink -f "$out/bin/lm-studio")"
          init_script="$(grep -Eo '/nix/store/[^[:space:]]+-lmstudio-[^[:space:]]+-init' "$bwrap_target" | head -n 1)"
          extracted_path="$(grep -Eo '/nix/store/[^[:space:]]+-lmstudio-[^[:space:]]+-extracted' "$init_script" | head -n 1)"

          if [ -z "$init_script" ] || [ ! -r "$init_script" ]; then
            echo "lmstudio build fix: failed to resolve init script from $bwrap_target" >&2
            exit 1
          fi

          if [ -z "$extracted_path" ] || [ ! -x "$extracted_path/resources/app/.webpack/lms" ]; then
            echo "lmstudio build fix: failed to resolve extracted lms payload from $init_script" >&2
            exit 1
          fi

          # Restore pristine upstream lms, then patch interpreter only.
          install -m 755 "$extracted_path/resources/app/.webpack/lms" "$out/bin/lms"
          patchelf --set-interpreter "${prev.stdenv.cc.bintools.dynamicLinker}" "$out/bin/lms"
        '';
      });
    })

  ];
}
