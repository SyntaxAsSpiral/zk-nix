# Pi coding agent

Shared local-provider config: `models.json` → `~/.pi/agent/models.json`.

- Endpoint: `http://100.89.32.9:1234/v1`
- `api`: `openai-completions`, `apiKey`: `lms`, `contextWindow`: 100000
- Models: `qwen/qwen3.8-27b`, `google/gemma-4-31b`, `meta/muse-glimmer`

OpenRouter is Pi's built-in provider. The API key is not in Nix. It lives in
gitignored `secrets/pi-openrouter-api-key` (Pi's OpenRouter key only; plain key,
no `KEY=` prefix), stages to `/run/secrets/pi-openrouter-api-key`, and is
exported as `OPENROUTER_API_KEY` at login. Hosts: nxiz, zrrh, adeck, tm20. Not seed.

Imported by `profiles/base.nix` (nxiz, zrrh, adeck) and `hosts/seed/home.nix`
(local models only). tm20 has no Home-Manager; `hosts/tm20/configuration.nix`
installs the same JSON via `/etc/pi/agent/models.json` and a tmpfiles symlink.

Binaries stay host-local:

- nxiz: npx wrapper in `hosts/nxiz/home.nix`
- adeck, zrrh, tm20: `pkgs.llm-agents.pi`
- seed: nushell `npx` function in `modules/home/nushell.nix`

OpenRouter fallback is the moving alias `~z-ai/glm-latest`. `stealth/` ids are temporary and stay unpinned.

```bash
pi --provider local --model qwen/qwen3.8-27b
pi --provider openrouter --model ~z-ai/glm-latest
```
