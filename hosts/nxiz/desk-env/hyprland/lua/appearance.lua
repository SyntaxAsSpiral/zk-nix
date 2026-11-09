-- appearance: layout, decoration, animations
-- hyprpaper is not used. nxiz wallpapers come from awww.

hl.config({
    general = {
        gaps_in     = 15,
        gaps_out    = 20,
        border_size = 2,

        col = {
            active_border   = { colors = { "rgb(cba6f7)", "rgb(89b4fa)", "rgb(94e2d5)", "rgb(f5e0dc)", "rgb(f2cdcd)", "rgb(eba0ac)" }, angle = 45 },
            inactive_border = "rgb(363a4f)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 10,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.8,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgb(24273a)",
        },

        dim_inactive = true,
        dim_strength = 0.1,
        dim_special  = 0.2,

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
            xray     = true,
            special  = true,
        },
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        -- nixpkgs does not package hyprland-guiutils yet. Remove when it does.
        disable_hyprland_guiutils_check = true,
        disable_splash_rendering = false,
        font_family              = "RecMonoCasual Nerd Font",
        splash_font_family       = "Recursive",
    },

    dwindle = {
        preserve_split       = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",           enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",           enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",          enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",           enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4,    bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 7,    bezier = "quick" })
