# One otter-launcher for every host. The modules use only shell kit tools.
{ pkgs, lib, inputs, ... }:
let
  # The saved chafa logo. Rows 0-4 sit beside the header text; row 5 becomes part of the
  # prompt line in config.toml, with its escapes written as TOML \u001B.
  esc = builtins.fromJSON ''"\u001b"'';
  logoRows = lib.splitString "\n" (lib.removeSuffix "\n" (builtins.readFile ../../assets/otter-logo.ansi));
  configToml = builtins.replaceStrings [ "@LOGO_ROW@" ] [
    (builtins.replaceStrings [ esc ] [ "\\u001B" ] (lib.last logoRows))
  ] (builtins.readFile ./otter-launcher/config.toml);

  # The header text beside the logo: name, date and time.
  otterHeader = pkgs.writeShellApplication {
    name = "otter-header";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      LOGO_ANSI=${../../assets/otter-logo.ansi}
      ${builtins.readFile ./otter-launcher/header.sh}
    '';
  };

  # fd over $HOME and every drive mounted on this host.
  otterFd = pkgs.writeShellApplication {
    name = "otter-fd";
    runtimeInputs = with pkgs; [
      coreutils
      fd
      util-linux
    ];
    text = builtins.readFile ./otter-launcher/fd.sh;
  };

  # Every live beads issue on this host, across all workspaces.
  otterBdList = pkgs.writeShellApplication {
    name = "otter-bd-list";
    runtimeInputs = [
      otterFd
    ]
    ++ (with pkgs; [
      coreutils
      gnused
      jq
    ]);
    text = builtins.readFile ./otter-launcher/bd-list.sh;
  };

  # Search jolt's energy history (adeck only; the script says so elsewhere).
  otterJolt = pkgs.writeShellApplication {
    name = "otter-jolt";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      jq
    ];
    text = builtins.readFile ./otter-launcher/jolt.sh;
  };

  # Pick a tailnet host and ssh in.
  otterSsh = pkgs.writeShellApplication {
    name = "otter-ssh";
    runtimeInputs = with pkgs; [
      fzf
      jq
      tailscale
    ];
    text = builtins.readFile ./otter-launcher/ssh.sh;
  };

  # Render text in every figlet and toilet font, with filters and a terminal text effect.
  otterFig = pkgs.writeShellApplication {
    name = "otter-fig";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gum
      terminaltexteffects
      toilet
    ];
    text = ''
      FIGLET_FONTS=${pkgs.figlet}/share/figlet
      TOILET_FONTS=${pkgs.toilet}/share/figlet
      ${builtins.readFile ./otter-launcher/fig.sh}
    '';
  };

  # Say something as a cow: any cow, any face.
  otterCow = pkgs.writeShellApplication {
    name = "otter-cow";
    runtimeInputs = with pkgs; [
      coreutils
      cowsay
      fortune
      fzf
      gnused
      gum
    ];
    text = ''
      COWS=${pkgs.cowsay}/share/cowsay/cows
      ${builtins.readFile ./otter-launcher/cow.sh}
    '';
  };

  # Search nixpkgs as you type.
  otterNx = pkgs.writeShellApplication {
    name = "otter-nx";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gawk
      gnused
      nh
      nix
    ];
    text = builtins.readFile ./otter-launcher/nx.sh;
  };

  # Search nushell's built-in commands in a nushell tui (the tui command is built in).
  otterNu = pkgs.writeShellApplication {
    name = "otter-nu";
    runtimeInputs = with pkgs; [
      less
      nushell
    ];
    text = "exec nu -n ${./otter-launcher/nu-tui.nu}";
  };

  # Ask a model about a file: pick it, type a prompt, pipe both to mods.
  otterAsk = pkgs.writeShellApplication {
    name = "otter-ask";
    runtimeInputs = [
      otterFd
    ]
    ++ (with pkgs; [
      bat
      fzf
      gum
    ]);
    text = builtins.readFile ./otter-launcher/ask.sh;
  };

  # Read one beads issue as markdown in glow.
  otterBdRead = pkgs.writeShellApplication {
    name = "otter-bd-read";
    runtimeInputs = with pkgs; [
      glow
      jq
    ];
    text = builtins.readFile ./otter-launcher/bd-read.sh;
  };

  # Pick a systemd unit: status, journal, restart, stop.
  otterSd = pkgs.writeShellApplication {
    name = "otter-sd";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gum
    ];
    text = builtins.readFile ./otter-launcher/sd.sh;
  };

  # Explore a JSON file with a live jq filter.
  otterJq = pkgs.writeShellApplication {
    name = "otter-jq";
    runtimeInputs = [
      otterFd
    ]
    ++ (with pkgs; [
      fzf
      jq
      less
    ]);
    text = builtins.readFile ./otter-launcher/jq.sh;
  };

  # Pick a process and end it.
  otterPs = pkgs.writeShellApplication {
    name = "otter-ps";
    runtimeInputs = with pkgs; [
      fzf
      gum
    ];
    text = builtins.readFile ./otter-launcher/ps.sh;
  };
in
{
  imports = [
    ./bat.nix
    ./fzf.nix
    ./fun.nix
    ./gh.nix
    ./glow.nix
    ./lazygit.nix
    ./mods/default.nix
    ./zoxide.nix
  ];

  home.packages = [
    inputs.otter-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
    otterHeader
    otterFd
    otterBdList
    otterBdRead
    otterJolt
    otterSsh
    otterNx
    otterFig
    otterCow
    otterSd
    otterJq
    otterPs
    otterNu
    otterAsk
  ];

  xdg.configFile."otter-launcher/config.toml".text = configToml;
}
