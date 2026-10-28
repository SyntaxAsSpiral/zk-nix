# Shared

`shared/` holds leaf modules used by more than one host. It does not hold profiles. The import list for a machine is `hosts/<host>/configuration.nix` and `hosts/<host>/home.nix`.

Start here when asking:

- Is this behavior shared by more than one host?
- Does this need a reusable option?
- Is this a system concern rather than a Home Manager concern?

## Boundaries

- `shared/system/` is NixOS system behavior.
- `shared/home/` is Home Manager user behavior.
- `hosts/<host>/configuration.nix` and `home.nix` are that host's profile.
- `hosts/<host>/desk-env/` is Home Manager behavior used by that host only.
- A NixOS module used by one host lives next to that host's `configuration.nix`.
- `overlays/**` is for package pins, input overlays, and local package patches.

## Divergence pattern

Prefer visible host maps over scattered conditionals:

```nix
let
  perHost = {
    nxiz = { enableThing = true; };
    adeck = { enableThing = false; };
    zrrh = { enableThing = true; };
  };
  h = perHost.${config.my.host};
in
{
  services.thing.enable = h.enableThing;
}
```

Use `my.*` options when a feature should be explicitly toggled by a host. This keeps host intent visible in `hosts/<host>/configuration.nix` while keeping the implementation reusable.

## Placement rule

- One host only: keep it in that host file unless it is large enough to need its own module.
- Two or more hosts: consider a shared module with a `perHost` map.
- Package version or package surgery: put it in `overlays/`.
- User apps and dotfiles used by two or more hosts: put them under `shared/home/` and import them from each `hosts/<host>/home.nix`. One host only: put them in that host's `desk-env/`.
