-- Look ofrenda: luz de vela: el borde va de cempasúchil a magenta y morado, sombra
-- cálida. Shader: viñeta tibia de vela (GameMode.sh lo apaga).
-- Paleta fija (no sigue al wallpaper).

local bg = "rgb(120c16)"
local line = "rgb(2b1f35)"
local ink = "rgb(4a3758)"
local acc = "rgb(ff8c1a)"
local acc2 = "rgb(e0218a)"
local alt = "rgb(8e44c4)"
local rust = "rgb(b5562f)"

hl.config({ general = {
    border_size = 2,
    gaps_in = 5,
    gaps_out = 12,

    col = {
        active_border = { colors = { acc, acc2, alt }, angle = 135 },
        inactive_border = line,
    },
} })

hl.config({ decoration = {
    rounding = 10,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.94,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.06,
    dim_special = 0.5,

    -- viñeta tibia de vela. GameMode.sh lo apaga.
    screen_shader = "~/.config/hypr/shaders/ofrenda.frag",

    shadow = {
        enabled = true,
        range = 28,
        render_power = 3,
        offset = "0 6",
        sharp = false,
        color = "rgba(ff8c1a33)",
        color_inactive = "rgba(ff8c1a22)",
    },

    blur = {
        enabled = true,
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
