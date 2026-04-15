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

  ];
}
