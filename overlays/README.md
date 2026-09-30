# Overlays and pins

This directory is where package behavior diverges from upstream nixpkgs and flake inputs. The tables are the registry. A new hold gets a row in the same change, including the condition that removes it.

`nix flake update` moves branch inputs (`nixpkgs`, `home-manager`, `llm-agents`, and the rest of that set). An input whose URL names a commit or a tag stays where `flake.nix` put it. Bump those by replacing the rev or tag, then `nix flake update <input>` so the lock refreshes the hash.

## Files

- `default.nix` is the host map. Start here when deciding which host gets an overlay.
- `nixpkgs-fixes.nix` is for local `overrideAttrs` fixes on nixpkgs packages.
- `flake-packages.nix` wraps flake-input packages with local patches.
- `patches/` holds `.patch` files referenced from overlay code.

## Inputs that stay put

| Input | Locked to | Hosts | Why | Drop when |
| --- | --- | --- | --- | --- |
| `nixpkgs-llm` | `e73de5be` (2026-06-26) | zrrh | CUDA `llama-cpp`. `hosts/zrrh/configuration.nix` sets `cudaCapabilities = [ "8.9" ]` so the build is the 4090 kernel only. | A CUDA rebuild is acceptable. Replace the rev, then `nix flake update nixpkgs-llm`. |
| `nixpkgs-hyprland` | `34ab99075` (2026-08-31) | nxiz | Hyprland 0.56.2 while the nxiz config is still hyprlang. | The nxiz config leaves hyprlang. |
| `nix-cachyos-kernel` | `26da04e` | nxiz, zrrh | Kernel patches are bound to that flake's own nixpkgs. It has no `follows`. | A newer kernel pin is worth the rebuild. |
| `noctalia` | tag `v4.7.7` | zrrh | The bar package stays on the config it was written against. | The zrrh config is updated for a newer tag. |

## Package holds

| Hold | Where | Hosts | Why | Drop when |
| --- | --- | --- | --- | --- |
| HyprPanel `1961ba86` (2026-04-23) | `nixpkgs-fixes.nix`, `hyprpanel-package.nix` | overlay on nxiz and zrrh; nxiz installs it | On nixpkgs 2026-07-21 the hyprpanel alias throws. Upstream archived the project for wayle. | nxiz leaves HyprPanel, or nixpkgs packages a build this config can use. |
| astal-cava input map | `nixpkgs-fixes.nix`, `patches/astal-cava-input-map.patch` | nxiz, zrrh (the HyprPanel overlay) | astal `fd94e333` casts `AstalCavaInput` onto libcava 1.0.0. Pipewire is 2 in Astal and coreaudio is 2 in libcava, so startup calls `strlen` on a null source and the panel dumps core. | nixpkgs astal maps the input through `astal_input_to_cava` (upstream `main` already does). |
| tumbler without libgepub | `nixpkgs-fixes.nix` | nxiz, zrrh | The EPUB thumbnailer pulls webkitgtk. | EPUB thumbnails are worth that build. |
| LM Studio `/etc/nixos` bind | `nixpkgs-fixes.nix` | nxiz, zrrh | Upstream bwrap skips `/etc`, so `~/.lmstudio` symlinks into the flake fail. The old rpath patchelf workaround came off after nixpkgs#511533. | The upstream wrapper binds `/etc`, or those symlinks leave `/etc/nixos`. |
| fsel desktop-entry cache | `flake-packages.nix`, `patches/fsel-disable-desktop-entry-cache.patch` | adeck, nxiz | The cache hides newly installed desktop files. | Upstream fsel stops serving a stale file list. |
| sonic-pi `doCheck = false` | `hosts/nxiz/home.nix` | nxiz | Uses root nixpkgs. Ruby 3.3 and Boost 1.86 are upstream since nixpkgs#514802. The checkPhase still starts `jackd`, which the sandbox cannot do. | The upstream check stops requiring a live JACK server. |
| Codex from `llm-agents.packages` | `hosts/adeck/configuration.nix`, `hosts/zrrh/configuration.nix` | adeck, zrrh | The Rust workspace is too expensive to rebuild on every nixpkgs bump. This takes the build numtide published for llm-agents' own nixpkgs. pi, gemini-cli, crush, and grok stay on `shared-nixpkgs`. | Codex leaves the system packages, or a nixpkgs bump is worth compiling it again. |

## Other build holds

| Hold | Where | Why |
| --- | --- | --- |
| numtide substituter priority 100 | `modules/system.nix` | numtide advertises priority 30, which would beat cache.nixos.org. CUDA substitutes come from `cache.nixos-cuda.org` after the cuda-maintainers Cachix started returning 401. |
| `NIX_CURL_FLAGS=--user-agent Nixpkgs` | `modules/system.nix` | crates.io/Fastly returns 403 for User-Agents that start with `curl/`. |
| llama-tts `b11077` Vulkan binary | `modules/llama-tts.nix` on adeck | Prebuilt tarball. adeck does not compile llama.cpp. |

## Host map

- `adeck`: llm-agents, cached Codex, fsel, llama-tts binary.
- `nxiz`: CachyOS kernel, Hyprland pin, HyprPanel, tumbler, LM Studio, fsel, sonic-pi checks disabled.
- `zrrh`: CachyOS kernel, llm-agents, cached Codex, HyprPanel overlay, tumbler, LM Studio, `nixpkgs-llm`, noctalia tag.
- `tm20`: tm20-cli. `tm20-source` is a branch input and moves on `nix flake update`.
