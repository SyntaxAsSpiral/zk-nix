{ inputs, system ? "x86_64-linux" }:

[
  (_final: _prev: {
    fsel = inputs.fsel.packages.${system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./patches/fsel-disable-desktop-entry-cache.patch
      ];
    });
  })
]