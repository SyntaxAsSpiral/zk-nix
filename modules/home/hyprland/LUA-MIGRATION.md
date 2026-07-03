# Hyprland Lua migration — field notes (2026-07-03)

Status: **attempted, rolled back, deferred.** hyprlang remains active; the
stateVersion deprecation warning is left loud on purpose until this lands.

## What was tried

`configType = "lua"` with variables emitted as `hl["$name"](value)` via
`extraLuaFiles` (see `lua-draft.hyprland.nix.txt` — the full attempted
hyprland.nix; `lua-draft.generated.lua.txt` — what home-manager generated).
Deployed to nxiz; Hyprland started but registered **zero binds**.

## Why it failed (verified via `hyprctl configerrors` on the live session)

```
require("vars"): vars.lua:1: attempt to call a nil value (field '$browser')
hyprland.lua:10: attempt to call a nil value (field 'animations')
```

1. `hl` is NOT a flat "any keyword is a callable field" table. String-indexed
   calls (`hl["$browser"]`) are nil. No engine-side `$var` mechanism found yet.
2. **home-manager's own auto-translation is wrong too**: it renders top-level
   settings sections as `hl.animations(...)`, `hl.general(...)` — all nil.
   The module docs' example nests sections under `settings.config.<section>`,
   suggesting the real API is `hl.config({ general = {...}, ... })`.
3. The Lua API is namespaced: `hl.config`, `hl.dsp.*` (dispatchers — even
   `hyprctl dispatch exit` fails in a lua session; wants `hl.dsp.exit()` style),
   `hl.on("hyprland.start", fn)`, `hl.exec_cmd`, `hl.bind` (untested — session
   died at line 10 before reaching binds).

## Additional traps found

- `settings."exec-once"` renders as `hl.exec-once(...)` — dash is also an
  illegal Lua identifier. awww.nix contributes to that key, so any port must
  handle the merge (draft used mkForce [] + replay via hl.on startup hook).
- `_var` in settings makes Lua *locals*, not engine variables — attr name
  becomes the local name, so `$`-prefixed attrs are equally illegal there.
- Syntax-checking with luajit is insufficient: the drafts all parsed clean.
  The failure is API-semantic. Test = live session + `hyprctl configerrors`.

## Next steps

1. Read Hyprland's actual Lua API docs (wiki.hypr.land, lua config section)
   — establish the real forms for: variables, sections, binds, windowrules,
   exec-once, monitors, submaps.
2. Restructure `settings` to match (likely everything under `config`),
   or write the port as hand-authored lua via extraLuaFiles and shrink
   `settings` to nothing.
3. Rebuild, deploy to nxiz with `zcli deploy nxiz` (action=boot → reboot),
   verify with `hyprctl configerrors` (works over ssh with
   XDG_RUNTIME_DIR=/run/user/1000 + HYPRLAND_INSTANCE_SIGNATURE from
   /run/user/1000/hypr/) BEFORE trusting the session.
4. Rollback path if bad: `sudo nixos-rebuild switch --rollback` on nxiz,
   restart session (Ctrl+Alt+F-key TTY works when binds are dead).
