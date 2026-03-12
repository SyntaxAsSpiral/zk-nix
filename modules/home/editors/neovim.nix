# Neovim + vim
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    vim
  ];
}
