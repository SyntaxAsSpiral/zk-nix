# Color palette: nix-colors (base16)
#
# Sets the global colorScheme for all home modules.
# Reference colors via: config.colorScheme.palette.base0X
#
# Base16 mapping for catppuccin-macchiato:
#   base00 = background (crust)     base08 = red
#   base01 = surface0              base09 = peach
#   base02 = surface1              base0A = yellow
#   base03 = surface2              base0B = green
#   base04 = overlay0              base0C = teal
#   base05 = text                  base0D = blue
#   base06 = rosewater             base0E = mauve
#   base07 = lavender              base0F = flamingo
{ inputs, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-macchiato;
}
