[
  # nixpkgs 2026-07-21: hyprpanel alias throws (upstream archived for wayle).
  # Keep the last packaged revision so nxiz's existing panel/config still builds.
  # astal fd94e333 casts AstalCavaInput onto libcava's enum. Pipewire is 2 in
  # Astal and coreaudio is 2 in libcava 1.0.0, so get_input strlens a null source.
  (final: prev: {
    astal = prev.astal.overrideScope (
      _final: prevScope: {
        cava = prevScope.cava.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/astal-cava-input-map.patch
          ];
        });
      }
    );

    hyprpanel = prev.callPackage ./hyprpanel-package.nix {
      inherit (final) astal;
    };
  })

  # pywal16 (HyprPanel dep) passes "--prefix PATH : …" as one makeWrapperArgs
  # string. Under structuredAttrs it is no longer word-split, so split it here.
  (_final: prev: {
    pywal16 = prev.pywal16.overrideAttrs (old: {
      makeWrapperArgs = prev.lib.concatMap (prev.lib.splitString " ") old.makeWrapperArgs;
    });
  })

  # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
  (_final: prev: {
    tumbler = prev.tumbler.overrideAttrs (old: {
      buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
    });
  })
]