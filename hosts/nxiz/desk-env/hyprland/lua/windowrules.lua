-- windowrules: window rules

hl.window_rule({
    name       = "screensaver-fullscreen",
    match      = { class = "hypr-screensaver" },
    fullscreen = true,
    float      = true,
})

hl.window_rule({
    name      = "launcher",
    match     = { class = "^(.*launcher.*)$" },
    float     = true,
    size      = "500 430",
    center    = true,
    animation = "popin 80%",
})

hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name      = "firefox-workspace",
    match     = { class = "^(firefox)$" },
    workspace = "1",
})

hl.window_rule({
    name      = "spotify-scratchpad",
    match     = { class = "^(spotify)$" },
    workspace = "special:magic silent",
})

hl.window_rule({
    name      = "steam-scratchpad",
    match     = { class = "^(steam|Steam)$" },
    workspace = "special:magic silent",
})

hl.window_rule({
    name      = "lmstudio-scratchpad",
    match     = { class = "^(ai.elementlabs.lmstudio)$" },
    workspace = "special:magic silent",
})

hl.window_rule({
    name      = "grok-bot-scratchpad",
    match     = { class = "^(grok-bot)$" },
    workspace = "special:magic silent",
})

hl.window_rule({
    name   = "tui-float",
    match  = { class = "^(tui-float)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "gjs",
    match  = { class = "^(gjs)$" },
    float  = true,
    center = true,
})
