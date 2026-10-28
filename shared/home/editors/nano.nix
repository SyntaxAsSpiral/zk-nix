_: {
  # nano itself comes from the shell kit (shared/system/shell.nix).
  # Colours are named ANSI colours, so they follow the terminal's palette.
  home.file.".nanorc".text = ''
    # Syntax highlighting files from NixOS path
    include /run/current-system/sw/share/nano/*.nanorc

    # Navigation
    set linenumbers
    unset jumpyscrolling
    set mouse
    set constantshow

    # Editing Assistance
    set softwrap
    set autoindent
    set whitespace "»·"
    set matchbrackets "(<[{)>]}"

    # Search and Replace
    unset casesensitive

    # File Management
    set multibuffer

    # Interface
    set titlecolor white,brightblack
    set statuscolor white,brightblack
    set errorcolor white,brightblack
    set selectedcolor white,brightblack
    set numbercolor brightblack
    set keycolor blue
    set functioncolor magenta
    set promptcolor white,brightblack

    # Key bindings
    bind ^S savefile main
  '';
}
