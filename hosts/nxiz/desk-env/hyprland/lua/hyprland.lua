-- nxiz Hyprland config, hand-written Lua. hyprland.nix feeds this file to home-manager
-- as extraConfig and writes the four modules it requires as extraLuaFiles.
-- Reference: Hyprland's example/hyprland.lua and wiki.hypr.land/configuring.

---------------------
---- MY PROGRAMS ----
---------------------

local terminal   = "kitty"
local fileManager = "thunar"
local menu       = "kitty --class launcher -e fsel -d"
local search     = "kitty --class launcher -e otter-launcher"
local browser    = "firefox"
local editor     = "zeditor"
local editorAlt  = "kitty --class tui-float -e nano"
local notes      = "obsidian"
local mainMod    = "SUPER"

-- Was defined in hyprland.nix, bound to nothing there either. The hyprlang form
-- called `hyprctl dispatch exec "[rules] cmd"`; a Lua session wants a Lua
-- expression, so this runs the same thing through hl.dsp.exec_cmd's rules.
local screensaver = [[bash -c 'for ws in $(hyprctl monitors -j | jq -r ".[].activeWorkspace.id"); do hyprctl dispatch "hl.dsp.exec_cmd(\"kitty --class hypr-screensaver -e neo --colormode=32 -C ~/.config/neo/frappe-sapphire.cfg\", { fullscreen = true, workspace = \"$ws silent\" })"; done']]

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "30")
hl.env("HYPRCURSOR_SIZE", "30")
hl.env("XCURSOR_THEME", "catppuccin-mocha-blue-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-blue-cursors")
hl.env("TZDIR", "/etc/zoneinfo")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-------------------
---- AUTOSTART ----
-------------------

-- exec-once: hyprland.nix (hyprpanel) and awww.nix (awww-daemon)
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpanel")
    hl.exec_cmd("awww-daemon")
end)

-- The sections share the locals above through this table, since each require()d
-- file has its own scope.
_G.nxiz = {
    terminal    = terminal,
    fileManager = fileManager,
    menu        = menu,
    search      = search,
    browser     = browser,
    editor      = editor,
    editorAlt   = editorAlt,
    notes       = notes,
    mainMod     = mainMod,
    screensaver = screensaver,
}

require("monitors")
require("appearance")
require("windowrules")
require("keybinds")

-- In a Lua session `hyprctl dispatch` takes a Lua expression, not a hyprlang dispatcher.
-- hypridle.nix and hyprpanel/config.json use that form.
