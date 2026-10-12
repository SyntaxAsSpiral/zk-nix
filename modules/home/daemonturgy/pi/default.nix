# Declarative pi local-provider config. Does not install the binary:
# nxiz keeps its npx wrapper; adeck/zrrh/tm20 install llm-agents.pi themselves;
# seed uses the nushell npx function.
# OpenRouter is built-in; the key is OPENROUTER_API_KEY from /run/secrets.
{
  home.file.".pi/agent/models.json" = {
    source = ./models.json;
    force = true;
  };

  home.sessionVariablesExtra = ''
    if [ -r /run/secrets/pi-openrouter-api-key ]; then
      OPENROUTER_API_KEY=$(tr -d '\n' < /run/secrets/pi-openrouter-api-key)
      export OPENROUTER_API_KEY
    fi
  '';
}
