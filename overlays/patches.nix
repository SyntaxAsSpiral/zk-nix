[
  # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
  (_final: prev: {
    tumbler = prev.tumbler.overrideAttrs (old: {
      buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
    });
  })

  # Expose /etc/nixos inside lmstudio bwrap sandbox so flake-anchored symlinks
  # (e.g. ~/.lmstudio/config-presets -> /etc/nixos/modules/.../config-presets)
  # resolve from within LMStudio. --bind-try is a no-op on hosts without /etc/nixos.
  # Note: the old --set-rpath patchelf workaround was removed; fixed upstream in
  # nixpkgs PR #511533 (merged 2026-04-20).
  (_final: prev: {
    lmstudio = prev.lmstudio.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        prev.coreutils
        prev.gnugrep
      ];

      buildCommand = (old.buildCommand or "") + ''
        bwrap_target="$(readlink -f "$out/bin/lm-studio")"

        # Expose /etc/nixos inside the bwrap sandbox so flake-anchored symlinks
        # (e.g. ~/.lmstudio/config-presets -> /etc/nixos/modules/.../config-presets)
        # resolve from within LMStudio. Upstream's wrapper excludes /etc from
        # auto-bind, producing ENOENT on any /etc/nixos-rooted path. --bind-try
        # keeps this a no-op on hosts where /etc/nixos is absent.
        rm "$out/bin/lm-studio"
        cp "$bwrap_target" "$out/bin/lm-studio"
        chmod +w "$out/bin/lm-studio"
        # Inject before the ro_mounts expansion - unique anchor that doesn't depend
        # on whitespace of earlier --tmpfs lines.
        sed -i 's|"''${ro_mounts\[@\]}"|--bind-try /etc/nixos /etc/nixos \\\n    "''${ro_mounts[@]}"|' "$out/bin/lm-studio"
        chmod 555 "$out/bin/lm-studio"
        if ! grep -q -- '--bind-try /etc/nixos /etc/nixos' "$out/bin/lm-studio"; then
          echo "lmstudio build fix: failed to inject /etc/nixos bind into wrapper" >&2
          echo "---wrapper tail---" >&2
          tail -30 "$out/bin/lm-studio" >&2
          exit 1
        fi
      '';
    });
  })
]
