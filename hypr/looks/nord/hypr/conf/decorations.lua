local c = require("wallust.wallust-hyprland")
-- Look nord: paleta Nord fija (no sigue al wallpaper) — tonos fríos y calmos,
-- esquinas medias, escarcha ligera. https://www.nordtheme.com/docs/colors-and-palettes

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 2,
    gaps_in = 3,
    gaps_out = 6,

    col = {
        active_border = { colors = { c.nord8, c.nord9 }, angle = 90 },
        inactive_border = c.nord1,
    },
} })

hl.config({ decoration = {
    rounding = 8,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.95,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.4,

    shadow = {
        enabled = true,
        range = 14,
        render_power = 3,
        offset = "0 4",
        color = "rgba(1a1e2699)",
        color_inactive = "rgba(1a1e2655)",
    },

    blur = {
        enabled = true,
        size = 6,
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
        border_active = c.nord8,
        border_inactive = c.nord1,
    },

    groupbar = {
        col = {
            active = c.nord8,
            inactive = c.nord3,
        },
    },
} })
