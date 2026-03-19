# System packages not managed in Home Manager
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core POSIX
    coreutils
    file
    findutils
    gawk
    gnugrep
    gnused
    less
    which

    # Shells
    bash
    fish
    nushell
    zsh

    # Archives
    gnutar
    gzip
    p7zip
    unzip
    zip

    # Terminfo
    kitty.terminfo

    # Network
    curl
    mosh
    openssh
    rsync
    sshfs
    wget

    # Network GUI/TUI
    bluetuith
    networkmanagerapplet
    wakeonlan

    # Media
    alsa-utils
    pamixer
    pulsemixer
    ffmpeg

    # File/text tools
    bat
    chafa
    eza
    fd
    jq
    ripgrep
    tree
    yq
    ncdu

    # System monitors
    duf
    dust
    fastfetch
    procs

    # Dev toolchains
    nodejs
    # python is in python module

    # Dev tools
    direnv
    just
    tmux

    # Nix tooling
    manix
    nh
    # agenix added via flake specialArgs inputs
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default

    # FHS compat wrapper for non-Nix binaries
    steam-run
  ];
}
