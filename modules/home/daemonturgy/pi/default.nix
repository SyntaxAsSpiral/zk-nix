# Declarative pi local-provider config. Does not install the binary:
# nxiz keeps its npx wrapper; adeck/zrrh/tm20 install llm-agents.pi themselves;
# seed uses the nushell npx function.
# OpenRouter is built-in; the key is OPENROUTER_API_KEY from /run/secrets.
#
# packages is the whole list. A rebuild replaces it. pi update --extensions
# reconciles each checkout to the pinned ref and installs its npm deps.
# It does not move the ref. Bump the rev here. tm20 has no Home-Manager.
#
# nix flake update does not touch these. They are strings, not flake inputs.
# flake update moves llm-agents (the pi binary). To move an extension:
# replace the hash below, switch, then run pi update --extensions.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  piPackages = [
    # v0.77.0. typebox is a peer. The v0.24.3 checkout listed it as a dependency.
    "git:github.com/nicobailon/pi-subagents@8fcc3c787a6e7d9da0f21bafb604fe937084c21b"
    # Already at origin. No host-package warning.
    "git:github.com/burggraf/pi-teams@d01336d0b3f948988ffda76a7a06021ea82c212a"
  ];
in
{
  home.file.".pi/agent/models.json" = {
    source = ./models.json;
    force = true;
  };

  home.activation.piPackages = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    settings="${config.home.homeDirectory}/.pi/agent/settings.json"
    mkdir -p "$(dirname "$settings")"
    if [ ! -f "$settings" ]; then
      printf '%s\n' '{}' > "$settings"
    fi
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson packages ${lib.escapeShellArg (builtins.toJSON piPackages)} \
      '.packages = $packages' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';

  home.sessionVariablesExtra = ''
    if [ -r /run/secrets/pi-openrouter-api-key ]; then
      OPENROUTER_API_KEY=$(tr -d '\n' < /run/secrets/pi-openrouter-api-key)
      export OPENROUTER_API_KEY
    fi
  '';
}
