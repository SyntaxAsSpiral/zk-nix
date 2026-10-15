# System packages not managed in Home Manager
{ pkgs, ... }:

let
  # One-command Playwright: the python lib and the Nix-patched browsers come from
  # the same pkgs, so their versions cannot drift apart.
  pw-run = pkgs.writeShellApplication {
    name = "pw-run";
    runtimeInputs = [ pkgs.coreutils (pkgs.python3.withPackages (ps: [ ps.playwright ])) ];
    text = ''
      export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
      export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      if [ "''${1:-}" = --check ]; then
        python3 -c 'import importlib.metadata as m; print("playwright lib", m.version("playwright"))'
        echo "browsers: $PLAYWRIGHT_BROWSERS_PATH"; ls "$PLAYWRIGHT_BROWSERS_PATH"
        exit 0
      fi
      exec python3 "$@"
    '';
  };
in
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
    lm_sensors
    nvtopPackages.full
    procs

    # Dev toolchains
    nodejs
    # python is in python module

    # Dev tools
    direnv
    just
    tmux

    # Browser automation
    playwright-driver.browsers
    pw-run # `pw-run script.py`: Playwright with matching lib + browsers

    # Nix tooling
    manix
    nh

    # FHS compat wrapper for non-Nix binaries
    steam-run
  ];

  environment.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
