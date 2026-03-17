{ ... }: {
  programs.gh = {
    enable = true;
    # Avoid baking ephemeral /nix/store gh paths into git credential helper config.
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
