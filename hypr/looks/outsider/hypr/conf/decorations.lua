local c = require("wallust.wallust-hyprland")
-- Look outsider: outsider house / lo-fi — foto vieja de rollo, cassette y VHS.
-- Paleta fija (no sigue al wallpaper): negros cálidos, crema, rosa deslavado,
-- teal de cinta y el rojo del REC. Grano de película con screen_shader.

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 1,
    gaps_in = 3,
    gaps_out = 8,

    col = {
        active_border = { colors = { c.rose, c.amber }, angle = 45 },
        inactive_border = c.ink2,
    },
} })

hl.config({ decoration = {
    rounding = 3,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 0.93,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.06,
    dim_special = 0.5,

    -- grano + negros levantados + viñeta leve. GameMode.sh lo apaga.
    screen_shader = "~/.config/hypr/shaders/outsider.frag",

    shadow = {
        enabled = true,
        range = 22,
        render_power = 2,
        offset = "0 8",
        color = "rgba(0a080699)",
        color_inactive = "rgba(0a080644)",
    },

    blur = {
        enabled = true,
        size = 5,
        passes = 2,
        noise = 0.06,
        brightness = 0.9,
        vibrancy = 0.05,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = c.rose,
        border_inactive = c.ink2,
    },

    groupbar = {
        col = {
            active = c.rose,
            inactive = c.ink3,
        },
    },
} })

hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })
