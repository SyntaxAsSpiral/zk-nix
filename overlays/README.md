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
| `nixpkgs-hyprland` | `34ab99075` (2026-08-31) | nxiz | Hyprland 0.56.2 while the nxiz config is still hyprlang. Its `bin/Hyprland` is a wrapProgram script, which the nixpkgs 2026-10-20 wrapper ELF check rejects. `hosts/nxiz/configuration.nix` points `security.wrappers.Hyprland.source` at `.Hyprland-wrapped`. That wrapper drops the script's PATH additions (binutils, hyprland-qtutils, pciutils, pkgconf). | The nxiz config leaves hyprlang. |
| `nix-cachyos-kernel` | `02ba4db` (2026-10-22) | nxiz, zrrh | Kernel patches are bound to that flake's own nixpkgs. It has no `follows`. Its nixpkgs must be no older than root nixpkgs' kernel build: since nixpkgs 2026-10-17 the module aggregator copies `modules.cer`, which older kernel builds lack. | A newer kernel pin is worth the rebuild. |

## Package holds

| Hold | Where | Hosts | Why | Drop when |
| --- | --- | --- | --- | --- |
| HyprPanel `1961ba86` (2026-04-23) | `nixpkgs-fixes.nix`, `hyprpanel-package.nix` | overlay on nxiz and zrrh; nxiz installs it | On nixpkgs 2026-07-21 the hyprpanel alias throws. Upstream archived the project for wayle. | nxiz leaves HyprPanel, or nixpkgs packages a build this config can use. |
| astal-cava input map | `nixpkgs-fixes.nix`, `patches/astal-cava-input-map.patch` | nxiz, zrrh (the HyprPanel overlay) | astal `fd94e333` casts `AstalCavaInput` onto libcava 1.0.0. Pipewire is 2 in Astal and coreaudio is 2 in libcava, so startup calls `strlen` on a null source and the panel dumps core. | nixpkgs astal maps the input through `astal_input_to_cava` (upstream `main` already does). |
| pywal16 split wrapper args | `nixpkgs-fixes.nix` | nxiz, zrrh (HyprPanel dep) | nixpkgs passes `"--prefix PATH : …"` as one `makeWrapperArgs` string. Since structuredAttrs (nixpkgs 2026-10-20), makeWrapper gets it unsplit and dies. Master is still unfixed on 2026-10-23. | nixpkgs pywal16 lists the wrapper args separately. |
| tumbler without libgepub | `nixpkgs-fixes.nix` | nxiz, zrrh | The EPUB thumbnailer pulls webkitgtk. | EPUB thumbnails are worth that build. |
| LM Studio `/etc/nixos` bind | `nixpkgs-fixes.nix` | nxiz, zrrh | Upstream bwrap skips `/etc`, so `~/.lmstudio` symlinks into the flake fail. The old rpath patchelf workaround came off after nixpkgs#511533. | The upstream wrapper binds `/etc`, or those symlinks leave `/etc/nixos`. |
| fsel desktop-entry cache | `flake-packages.nix`, `patches/fsel-disable-desktop-entry-cache.patch` | adeck, nxiz | The cache hides newly installed desktop files. | Upstream fsel stops serving a stale file list. |
| sonic-pi `doCheck = false` | `hosts/nxiz/home.nix` | nxiz | Uses root nixpkgs. Ruby 3.3 and Boost 1.86 are upstream since nixpkgs#514802. The checkPhase still starts `jackd`, which the sandbox cannot do. | The upstream check stops requiring a live JACK server. |
| Codex from `llm-agents.packages` | `hosts/adeck/configuration.nix`, `hosts/zrrh/configuration.nix` | adeck, zrrh | The Rust workspace is too expensive to rebuild on every nixpkgs bump. This takes the build numtide published for llm-agents' own nixpkgs. pi, gemini-cli, crush, grok, and grok-bot stay on `shared-nixpkgs`. | Codex leaves the system packages, or a nixpkgs bump is worth compiling it again. |
| herdr from `llm-agents.packages` | `hosts/adeck/configuration.nix` | adeck | Rust plus Zig (`libghostty-vt`). Same cache as Codex: numtide's nixpkgs build, not `shared-nixpkgs`. | herdr leaves adeck, or a nixpkgs bump is worth compiling it again. |
| beads from `llm-agents.packages` | `hosts/adeck/configuration.nix` | adeck | Go source (`bd` 1.3.1). Same cache as Codex. | beads leaves adeck, or a nixpkgs bump is worth compiling it again. |
| OpenRGB 1.0rc3.1 | `nixpkgs-openrgb` `34ab99075` (2026-08-31), `overlays/default.nix` | zrrh | 1.0 renamed `Aura Addressable 1` and will not keep Hypnotoad's custom colors or the pump/fan segments. | 1.0 loads those segments and saves the effect's custom colors. |
| noctalia-shell 4.7.7 | `nixpkgs-openrgb` `34ab99075` (2026-08-31), `overlays/default.nix` | zrrh | On Qt 6.12, noctalia-qs 0.0.12 (archived fork of quickshell) fails `TypeIsCompleteOrVoid` on its pipewire metatypes. Hydra has no build at nixpkgs 2026-10-20. That rev has one in cache.nixos.org. | nixpkgs noctalia-qs builds on current Qt, or OpenRGB moves its rev (then repin or drop). |

## Other build holds

| Hold | Where | Why |
| --- | --- | --- |
| numtide substituter priority 100 | `modules/system.nix` | numtide advertises priority 30, which would beat cache.nixos.org. CUDA substitutes come from `cache.nixos-cuda.org` after the cuda-maintainers Cachix started returning 401. |
| `NIX_CURL_FLAGS=--user-agent Nixpkgs` | `modules/system.nix` | crates.io/Fastly returns 403 for User-Agents that start with `curl/`. |
| llama-tts `b11077` Vulkan binary | `modules/llama-tts.nix` on adeck | Prebuilt tarball. adeck does not compile llama.cpp. |

## Host map

- `adeck`: llm-agents, cached Codex, cached herdr, cached beads, fsel, llama-tts binary.
- `nxiz`: CachyOS kernel, Hyprland pin, llm-agents, HyprPanel, tumbler, LM Studio, fsel, sonic-pi checks disabled.
- `zrrh`: CachyOS kernel, llm-agents, cached Codex, HyprPanel overlay, tumbler, LM Studio, `nixpkgs-llm`, OpenRGB 1.0rc3.1, noctalia-shell from the OpenRGB rev.
- `tm20`: tm20-cli, llm-agents (pi). `tm20-source` is a branch input and moves on `nix flake update`.
- `seed`: no overlays. Stock nixpkgs kernel and packages, all from cache.nixos.org.
