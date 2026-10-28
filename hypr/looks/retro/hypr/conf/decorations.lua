local c = require("wallust.wallust-hyprland")
-- Look retro: terminal de fósforo — un solo color (el acento de wallust) sobre
-- fondo oscuro, bordes de 1px, sin sombras ni blur, foco por atenuación.

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 1,
    gaps_in = 2,
    gaps_out = 4,

    col = {
        active_border = c.color12,
        inactive_border = c.color0,
    },
} })

hl.config({ decoration = {
    rounding = 0,

    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.25,
    dim_special = 0.7,

    shadow = {
        enabled = false,
    },

    blur = {
        enabled = false,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.color12,
        border_inactive = c.color0,
    },

    groupbar = {
        col = {
            active = c.color12,
            inactive = c.color0,
        },
    },
} })
