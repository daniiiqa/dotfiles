local c = require("wallust.wallust-hyprland")
-- Look neon: borde fino de dos tonos a media opacidad y un halo tenue del
-- acento alrededor de la ventana activa (discreto: el neón vive en la barra). Colores de wallust (harddark16 +
-- saturación).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 1,
    gaps_in = 3,
    gaps_out = 8,

    col = {
        active_border = { colors = { c.color12_soft, c.color13_soft }, angle = 45 },
        inactive_border = c.color0,
    },
} })

hl.config({ decoration = {
    rounding = 4,

    active_opacity = 1.0,
    inactive_opacity = 0.92,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.1,
    dim_special = 0.6,

    -- halo: sombra sin desplazamiento en el color de acento
    shadow = {
        enabled = true,
        range = 12,
        render_power = 3,
        offset = "0 0",
        color = c.color12_glow,
        color_inactive = "rgba(00000000)",
    },

    blur = {
        enabled = true,
        size = 4,
        passes = 2,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = { colors = { c.color12_soft, c.color13_soft }, angle = 45 },
        border_inactive = c.color0,
    },

    groupbar = {
        col = {
            active = c.color12,
            inactive = c.color0,
        },
    },
} })
