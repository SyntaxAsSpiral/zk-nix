# Pi coding agent

The `pi` command is currently enabled on `nxiz` as an inline Home Manager wrapper.
It deliberately runs the upstream package through `npx` instead of pinning a
Nix derivation, so the agent can be updated independently of the system
configuration.

```nix
(writeShellApplication {
  name = "pi";
  runtimeInputs = [ nodejs ];
  text = ''
    set -euo pipefail
    exec npx --yes @earendil-works/pi-coding-agent "$@"
  '';
})
```

The wrapper is defined in `hosts/nxiz/home.nix`. `seed` gets the same `npx`
command as a `pi` function in the `seed` block of `modules/home/nushell.nix`.
There is currently no Pi wrapper or declarative `~/.pi` state mapping in the
`zrrh` or `adeck` Home Manager configuration, and this directory contains
documentation only.
