-- keybinds.nix: bind / bindm / bindel / bindl

local n = _G.nxiz
local mainMod = n.mainMod

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(n.terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(n.editor))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(n.editorAlt))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(n.menu))

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(n.search))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + D", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" })) -- maximize
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(n.notes))
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + C", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(n.fileManager))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(n.browser))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a")) -- troubleshooting needed
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprpanel -q; hyprpanel"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("kitty --class tui-float --title emoji -e fzf-emoji"))
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("kitty --class tui-float -e btop"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Images/Screenshots"))
hl.bind(mainMod .. " + Home", hl.dsp.exec_cmd("hyprshot -z -m region -o ~/Images/Screenshots"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Workspaces 1-10 (key 0 is workspace 10) and move-to-workspace
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- bindm: move and resize with the mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- bindel: volume, repeating and active on the lock screen
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })

-- bindl: media keys, active on the lock screen
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
