# Pi coding agent

Shared local-provider config: `models.json` → `~/.pi/agent/models.json`.

- Endpoint: `http://100.89.32.9:1234/v1`
- `api`: `openai-completions`, `apiKey`: `lms`
- `contextWindow`: `qwen/qwen3.8-27b` is 145000. `google/gemma-4-31b` and `meta/muse-glimmer` are 100000.
- Models: `qwen/qwen3.8-27b`, `google/gemma-4-31b`, `meta/muse-glimmer`

OpenRouter is Pi's built-in provider. The API key is not in Nix. It lives in
gitignored `secrets/pi-openrouter-api-key` (Pi's OpenRouter key only; plain key,
no `KEY=` prefix), stages to `/run/secrets/pi-openrouter-api-key`, and is
exported as `OPENROUTER_API_KEY` at login. Hosts: nxiz, zrrh, adeck. Not seed or tm20.

Imported by the home files of nxiz, zrrh, and adeck.

Pi packages are pinned git refs in `~/.pi/agent/settings.json`, written by
`home.activation.piPackages`. The list is the whole `packages` array. `pi update`
cannot move a pinned ref, and it cannot update the Pi binary when Nix provides
it. `pi update --extensions` still installs that ref's npm dependencies into
`~/.pi/agent/git`. Pi still compares a git checkout to origin, so a pin behind
origin keeps the "Package Updates Available" banner until the checkout matches.

`nix flake update` does not move these refs. They are strings in
`default.nix`, not flake inputs. That command does move the `llm-agents` input,
which is the Pi binary. To update an extension, replace its hash, switch, then
run `pi update --extensions`.

`pi-mcp-adapter` is not in the list. Pi 1.1 loads `builtin:mcp`, which reads
`~/.pi/agent/mcp.json`. The adapter registers `/mcp` and replaces that, which
is the startup warning. Herdr's integration file
(`extensions/herdr-agent-state.ts`) and Herdr marketplace plugins stay Herdr's.
Beads has no plugin list here.

Binaries stay host-local:

- nxiz, adeck, zrrh: `pkgs.llm-agents.pi` and this module
- seed, tm20: no Pi

OpenRouter fallback is the moving alias `~z-ai/glm-latest`. `stealth/` ids are temporary and stay unpinned.

```bash
pi --provider local --model qwen/qwen3.8-27b
pi --provider openrouter --model ~z-ai/glm-latest
```
