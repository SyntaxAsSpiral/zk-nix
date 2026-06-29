{
  tailscale = _final: prev: {
    # Pin away from Tailscale 1.98.0: upstream marked it test-only, and it
    # regressed MagicDNS resolver programming on systemd-resolved hosts.
    tailscale = prev.tailscale.overrideAttrs (
      finalAttrs: _previousAttrs: {
        version = "1.96.5";
        src = prev.fetchFromGitHub {
          owner = "tailscale";
          repo = "tailscale";
          tag = "v${finalAttrs.version}";
          hash = "sha256-vYYb+2OtuXftjGGG0zWJesHccrClB8YZpclv9KzNN/c=";
        };
        vendorHash = "sha256-rhuWEEN+CtumVxOw6Dy/IRxWIrZ2x6RJb6ULYwXCQc4=";
        ldflags = [
          "-w"
          "-s"
          "-X tailscale.com/version.longStamp=${finalAttrs.version}"
          "-X tailscale.com/version.shortStamp=${finalAttrs.version}"
        ];
      }
    );
  };
}
