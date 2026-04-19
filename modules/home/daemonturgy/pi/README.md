# Pi Agent (Stub)

The `pi` daemon is currently excluded from a formal Nix store derivation to maintain update flexibility through `npx`.

## Current Architecture

**1. The Runner**  
The `pi` executable is provisioned as an inline shell wrapper within host-level definitions (`hosts/nxiz/home.nix`, `hosts/zrrh/home.nix`). It executes directly via `npx`.
```nix
(writeShellApplication {
  name = "pi";
  runtimeInputs = [ nodejs ];
  text = "exec npx --yes @mariozechner/pi-coding-agent \"$@\"";
})
```

**2. State & Configuration**  
Pi's state domain is `~/.pi`.  
On `nxiz`, this is tracked declaratively via an out-of-store symlink in `home.nix`:
```nix
".pi".source = config.lib.file.mkOutOfStoreSymlink "/mnt/repository/daemonturgy/pi/.pi";
```
*(Keeper's Note: Check your `nxiz/home.nix` out-of-store path; it currently points to `/mnt/repository/daemonturgy/pi/.pi` instead of the full repository path `/mnt/repository/nix-os/modules/home/daemonturgy/pi/.pi`).*

**3. Dormant Blueprint**  
A blueprint for mapping `pi` into the Nix ecosystem as a standalone binary derivation exists in `tmp/nixos/pkgs/derivations/pi-agent-bin/`. It can be resurrected when you desire full declarative control over the daemon's binaries.
