-- Look loteria: cartas: contorno negro grueso y sombra dura desplazada, como una
-- carta impresa sobre la mesa. Sin blur.
-- Paleta fija (no sigue al wallpaper).

local bg = "rgb(efe3c4)"
local line = "rgb(cdb88a)"
local ink = "rgb(1a1612)"
local acc = "rgb(c8102e)"
local acc2 = "rgb(1d4e9e)"
local alt = "rgb(f2b705)"
local rust = "rgb(b5562f)"

hl.config({ general = {
    border_size = 3,
    gaps_in = 6,
    gaps_out = 14,

    col = {
        active_border = ink,
        inactive_border = "rgba(1a161266)",
    },
} })

hl.config({ decoration = {
    rounding = 6,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.97,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_strength = 0.06,
    dim_special = 0.5,

    shadow = {
        enabled = true,
        range = 1,
        render_power = 1,
        offset = "6 6",
        sharp = true,
        color = "rgba(1a1612ff)",
        color_inactive = "rgba(1a161266)",
    },

    blur = {
        enabled = false,
        size = 6,
        passes = 2,
        noise = 0.02,
        brightness = 1.05,
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
        border_active = acc,
        border_inactive = line,
    },

    groupbar = {
        col = {
            active = acc,
            inactive = line,
        },
    },
} })

hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })
