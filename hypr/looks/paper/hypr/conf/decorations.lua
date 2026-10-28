local c = require("wallust.wallust-hyprland")
-- Look paper: e-ink — fondo claro, tinta oscura, líneas finas, cero sombras
-- y cero blur. Colores de wallust (paleta light16).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 1,
    gaps_in = 3,
    gaps_out = 8,

    col = {
        active_border = c.foreground,
        inactive_border = c.color8,
    },
} })

hl.config({ decoration = {
    rounding = 3,

    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.2,

    shadow = {
        enabled = false,
    },

    blur = {
        enabled = false,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.foreground,
        border_inactive = c.color8,
    },

    groupbar = {
        col = {
            active = c.foreground,
            inactive = c.color8,
        },
    },
} })
