_: {
  # nano itself comes from the shell kit (shared/system/shell.nix).
  # Colours are named ANSI colours, so they follow the terminal's palette.
  # Every nanorc option is listed; a leading "#" marks the ones left off.
  home.file.".nanorc".text = ''
    # Syntax highlighting files from NixOS path
    include /run/current-system/sw/share/nano/*.nanorc

    # Navigation
    set linenumbers
    unset jumpyscrolling
    # set solosidescroll
    set mouse
    set constantshow
    # set positionlog
    # set colonparsing
    # set showcursor
    # set quickblank

    # Editing Assistance
    set softwrap
    # set atblanks
    set autoindent
    set whitespace "»·"
    set matchbrackets "(<[{)>]}"
    # set smarthome
    # set cutfromcursor
    # set zap
    # set afterends
    # set wordbounds
    # set wordchars "characters"
    # set tabsize 4
    # set tabstospaces
    # set breaklonglines
    # set fill 72
    # set trimblanks
    # set bookstyle
    # set brackets "characters"
    # set punct "characters"
    # set quotestr "regex"

    # Search and Replace
    unset casesensitive
    # set regexp
    # set historylog

    # File Management
    set newbuffer
    # set backup
    # set backupdir "directory"
    # set locking
    # set preserve
    # set saveonexit
    # set unix
    # set noconvert
    # set nonewlines
    # set magic
    # set operatingdir "directory"
    # set speller "program [argument ...]"

    # Interface
    # set minibar
    # set nohelp
    # set indicator
    # set zero
    # set stateflags
    # set emptyline
    # set boldtext
    # set guidestripe 80
    set titlecolor white,brightblack
    set statuscolor white,brightblack
    set errorcolor white,brightblack
    set selectedcolor white,brightblack
    set numbercolor brightblack
    set keycolor blue
    set functioncolor magenta
    set promptcolor white,brightblack
    # set minicolor white,brightblack
    # set stripecolor white,brightblack
    # set spotlightcolor black,lightyellow
    # set scrollercolor white,brightblack

    # Terminal quirks
    # set rebinddelete
    # set rawsequences

    # Key bindings
    bind ^S savefile main
  '';
}
