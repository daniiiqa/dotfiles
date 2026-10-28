local c = require("wallust.wallust-hyprland")
-- Look brutalist: editorial y afilado — esquinas rectas, líneas de 2px,
-- sombra dura corta, cero blur. Colores de wallust (paleta harddark16).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 2,
    gaps_in = 3,
    gaps_out = 8,

    col = {
        active_border = c.color12,
        inactive_border = "rgba(ffffff14)",
    },
} })

hl.config({ decoration = {
    rounding = 0,

    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.12,
    dim_special = 0.6,

    shadow = {
        enabled = true,
        range = 1,
        render_power = 1,
        sharp = true,
        offset = "4 4",
        color = "rgba(000000cc)",
        color_inactive = "rgba(00000066)",
    },

    blur = {
        enabled = false,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.color12,
        border_inactive = "rgba(ffffff14)",
    },

    groupbar = {
        col = {
            active = c.color12,
            inactive = c.color0,
        },
    },
} })
