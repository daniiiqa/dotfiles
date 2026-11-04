local c = require("wallust.wallust-hyprland")
-- Look obsidiana: vidrio volcánico — ventanas sin borde y transparentes, sin
-- difuminado (el wallpaper se ve tal cual detrás del texto); la activa flota con
-- una sombra honda, las demás se oscurecen como piedra a la sombra.
-- Shader: un poco menos de color y un frío leve (GameMode.sh lo apaga).
-- Paleta fija sobre tu wallpaper.

hl.config({ general = {
    border_size = 0,
    gaps_in = 8,
    gaps_out = 20,

    col = {
        active_border = c.brillo,
        inactive_border = c.line,
    },
} })

hl.config({ decoration = {
    rounding = 18,
    rounding_power = 3,

    active_opacity = 1.0,
    inactive_opacity = 0.96,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.28,
    dim_special = 0.6,

    -- piedra: menos color, un frío leve. GameMode.sh lo apaga.
    screen_shader = "~/.config/hypr/shaders/obsidiana.frag",

    shadow = {
        enabled = true,
        range = 18,
        render_power = 3,
        offset = "0 5",
        sharp = false,
        color = c.bg0_a99,
        color_inactive = c.bg0_a00,
    },

    -- sin difuminado: lo de atrás se ve tal cual
    blur = {
        enabled = false,
        size = 12,
        passes = 3,
        noise = 0.01,
        brightness = 0.7,
        vibrancy = 0.0,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.brillo,
        border_inactive = c.line,
    },

    groupbar = {
        col = {
            active = c.brillo,
            inactive = c.line,
        },
    },
} })

hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.2 })
