local c = require("wallust.wallust-hyprland")
-- Look pastel: redondo y suave — borde con degradado de dos tonos,
-- sombra difusa, blur ligero. Colores de wallust (paleta softdark16).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 2,
    gaps_in = 3,
    gaps_out = 8,

    col = {
        active_border = { colors = { c.color12, c.color13 }, angle = 45 },
        inactive_border = "rgba(00000000)",
    },
} })

hl.config({ decoration = {
    rounding = 14,
    rounding_power = 2.6,

    active_opacity = 1.0,
    inactive_opacity = 0.96,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.3,

    shadow = {
        enabled = true,
        range = 24,
        render_power = 3,
        offset = "0 6",
        color = "rgba(00000044)",
        color_inactive = "rgba(00000022)",
    },

    blur = {
        enabled = true,
        size = 5,
        passes = 2,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
        vibrancy = 0.2,
    },
} })

hl.config({ group = {
    col = {
        border_active = { colors = { c.color12, c.color13 }, angle = 45 },
        border_inactive = "rgba(00000000)",
    },

    groupbar = {
        col = {
            active = c.color12,
            inactive = c.color0,
        },
    },
} })
