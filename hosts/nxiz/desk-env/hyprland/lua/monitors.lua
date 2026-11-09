-- monitors: monitors, input, per-device settings

hl.monitor({ output = "HDMI-A-2", mode = "2560x1080",           position = "1440x1260", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144.00000", position = "0x0",       scale = 1, transform = 1 })

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
