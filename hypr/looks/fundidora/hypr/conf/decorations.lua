local c = require("wallust.wallust-hyprland")
-- Look fundidora: lámina de acero con bordes de óxido y cobre. Sin blur: plano y pesado.
-- Paleta fija (no sigue al wallpaper).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 2,
    gaps_in = 4,
    gaps_out = 10,

    col = {
        active_border = { colors = { c.acc2, c.acc, c.rust }, angle = 90 },
        inactive_border = c.line,
    },
} })

hl.config({ decoration = {
    rounding = 2,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.94,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.06,
    dim_special = 0.5,

    shadow = {
        enabled = true,
        range = 18,
        render_power = 3,
        offset = "0 10",
        sharp = false,
        color = "rgba(000000aa)",
        color_inactive = "rgba(00000022)",
    },

    blur = {
        enabled = false,
        size = 6,
        passes = 2,
        noise = 0.02,
        brightness = 0.9,
        vibrancy = 0.15,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.acc,
        border_inactive = c.line,
    },

    groupbar = {
        col = {
            active = c.acc,
            inactive = c.line,
        },
    },
} })

hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })
