local c = require("wallust.wallust-hyprland")
-- Look glass: vidrio esmerilado — ventanas translúcidas con blur fuerte,
-- canto de luz que gira alrededor del borde, dock de píldoras abajo. Colores de wallust (paleta dark16).

-- colores de wallust: c.color0 … c.color15

  hl.config({ general = {
      border_size = 3,
      gaps_in = 6,
      gaps_out = 12,

        col = {
            active_border = { colors = { "rgb(ff79c6ff)", "rgb(8be9fdff)", "rgb(bd93f9ff)", "rgb(ffb86cff)" }, angle = 90 },
            inactive_border = "rgba(8be9fd44)",
        },
  } })

  hl.config({ decoration = {
      rounding = 35,
      rounding_power = 3.5,

      active_opacity = 0.95,
      inactive_opacity = 0.80,
      fullscreen_opacity = 1.0,

    dim_inactive = false,
    dim_special = 0.3,

      shadow = {
          enabled = true,
          range = 50,
          render_power = 3,
          offset = "-10 20",
            color = "rgba(bd93f980)",   # bd93f9 con alpha ~50%
            color_inactive = "rgba(8be9fd33)", # 8be9fd con alpha ~20%
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
          border_active = { colors = { "rgba(ff79c6)", "rgba(8be9fd)", "rgba(bd93f9)", "rgba(ffb86c)" }, angle = 90 },
          border_inactive = "rgba(8be9fd44)",
      },

      groupbar = {
          col = {
              active = "rgba(ff79c6, 0.5)",
              inactive = "rgba(8be9fd, 0.2)",
          },
          rounding = 15,
          font_size = 10,
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
