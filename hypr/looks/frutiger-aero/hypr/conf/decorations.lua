local c = require("wallust.wallust-hyprland")
-- Look frutiger-aero: vidrio brillante tipo Vista/7 — ventanas claras y
-- translúcidas, blur luminoso y saturado, canto de luz cian→verde que gira con
-- brillos blancos, sombras suaves azuladas (no negras). Colores de wallust:
-- se ve mejor con wallpapers de cielo, agua o pasto.

-- colores de wallust: c.color0 … c.color15

-- el brillo: blanco → cian → azul → verde → blanco, girando (animations.lua)
local brillo = { colors = { "rgba(ffffffdd)", c.color14, c.color12, c.color10, "rgba(ffffffdd)" }, angle = 45 }

hl.config({ general = {
    border_size = 2,
    gaps_in = 8,
    gaps_out = 16,

    col = {
        active_border = brillo,
        inactive_border = "rgba(ffffff30)",
    },
} })

hl.config({ decoration = {
    rounding = 18,
    rounding_power = 2,

    active_opacity = 0.92,
    inactive_opacity = 0.85,
    fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.25,

    -- sombra grande y suave, azulada como en Aero
    shadow = {
        enabled = true,
        range = 60,
        render_power = 3,
        offset = "0 8",
        color = "rgba(0a2a4a59)",
        color_inactive = "rgba(0a2a4a2a)",
    },

    -- vidrio claro: más brillo y saturación, casi sin grano
    blur = {
        enabled = true,
        size = 10,
        passes = 3,
        noise = 0.01,
        contrast = 1.0,
        brightness = 1.15,
        vibrancy = 0.5,
        vibrancy_darkness = 0.3,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true,
        special = true,
        popups = true,
    },
} })

hl.config({ group = {
    col = {
        border_active = brillo,
        border_inactive = "rgba(ffffff30)",
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
hl.layer_rule({ match = { namespace = "empalme" }, blur = true })
hl.layer_rule({ match = { namespace = "empalme" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })
