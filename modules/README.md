# Modules

Modules hold shared system policy for the mesh.

Start here when asking:

- Is this behavior shared by more than one host?
- Does this need a reusable option?
- Is this a system concern rather than a Home Manager concern?

## Boundaries

- `modules/*.nix` is for NixOS system behavior.
- `modules/home/**` is for Home Manager user behavior.
- `hosts/<host>/**` is for host-only composition and host-only exceptions.
- `overlays/**` is for package pins, input overlays, and local package patches.

## Divergence Pattern

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

## Placement Rule

- One host only: keep it in that host file unless it is large enough to need its own module.
- Two or more hosts: consider a shared module with a `perHost` map.
- Package version or package surgery: put it in `overlays/`.
- User apps and dotfiles: put it under `modules/home/` and import from `hosts/<host>/home.nix`.

Keep modules boring and named by ownership. Future edits should answer "where do I go?" before they answer "how clever can this be?"
