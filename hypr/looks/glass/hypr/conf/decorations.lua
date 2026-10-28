local c = require("wallust.wallust-hyprland")
-- Look glass: vidrio esmerilado — ventanas translúcidas con blur fuerte,
-- canto de luz que gira alrededor del borde, dock de píldoras abajo. Colores de wallust (paleta dark16).

-- colores de wallust: c.color0 … c.color15

hl.config({ general = {
    border_size = 2,
    gaps_in = 4,
    gaps_out = 10,

    col = {
        active_border = { colors = { "rgba(ffffff88)", "rgba(ffffff10)", c.color12, "rgba(ffffff10)" }, angle = 45 },
        inactive_border = "rgba(ffffff14)",
    },
} })

hl.config({ decoration = {
    rounding = 20,
    rounding_power = 2.8,

    active_opacity = 0.86,
    inactive_opacity = 0.72,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.3,

    shadow = {
        enabled = true,
        range = 40,
        render_power = 2,
        offset = "0 12",
        color = "rgba(00000066)",
        color_inactive = "rgba(00000033)",
    },

    blur = {
        enabled = true,
        size = 12,
        passes = 4,
        noise = 0.02,
        contrast = 1.1,
        brightness = 0.9,
        vibrancy = 0.3,
        vibrancy_darkness = 0.2,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = { colors = { "rgba(ffffff88)", "rgba(ffffff10)", c.color12, "rgba(ffffff10)" }, angle = 45 },
        border_inactive = "rgba(ffffff1a)",
    },

    groupbar = {
        col = {
            active = c.color12,
            inactive = c.color0,
        },
    },
} })

-- Esmerilado de capas — viven aquí (y no en windowrules.conf) porque son
-- parte del look: al cambiar de look, hyprctl reload las quita.
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })
