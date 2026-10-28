-- Look nord: paleta Nord fija (no sigue al wallpaper) — tonos fríos y calmos,
-- esquinas medias, escarcha ligera. https://www.nordtheme.com/docs/colors-and-palettes

local nord0 = "rgb(2E3440)"
local nord1 = "rgb(3B4252)"
local nord3 = "rgb(4C566A)"
local nord8 = "rgb(88C0D0)"
local nord9 = "rgb(81A1C1)"

hl.config({ general = {
    border_size = 2,
    gaps_in = 3,
    gaps_out = 6,

    col = {
        active_border = { colors = { nord8, nord9 }, angle = 90 },
        inactive_border = nord1,
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
        border_active = nord8,
        border_inactive = nord1,
    },

    groupbar = {
        col = {
            active = nord8,
            inactive = nord3,
        },
    },
} })
