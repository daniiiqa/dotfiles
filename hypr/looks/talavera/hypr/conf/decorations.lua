-- Look talavera: azulejo: borde cobalto, esquinas redondas, sombra azulada suave.
-- Paleta fija (no sigue al wallpaper).

local bg = "rgb(f6f1e4)"
local line = "rgb(d9ccb0)"
local ink = "rgb(1f3f8f)"
local acc = "rgb(1f3f8f)"
local acc2 = "rgb(e3a51b)"
local alt = "rgb(2f5bb8)"
local rust = "rgb(b5562f)"

hl.config({ general = {
    border_size = 2,
    gaps_in = 6,
    gaps_out = 14,

    col = {
        active_border = { colors = { acc, alt }, angle = 45 },
        inactive_border = line,
    },
} })

hl.config({ decoration = {
    rounding = 14,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.97,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_strength = 0.06,
    dim_special = 0.5,

    shadow = {
        enabled = true,
        range = 20,
        render_power = 3,
        offset = "0 6",
        sharp = false,
        color = "rgba(1f3f8f33)",
        color_inactive = "rgba(1f3f8f22)",
    },

    blur = {
        enabled = true,
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
