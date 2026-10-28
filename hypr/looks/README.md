# Looks de discada

Cada look es una carpeta aquí con un archivo maestro, `look.toml`, y los
archivos de cada app (un espejo de `~/.config` con solo lo que el look cambia).
`LookSwitch.sh` (SUPER+T) lo aplica con `LookBuild.py`.

```
hypr/looks/<look>/
  look.toml            colores, fuente, estilo: lo único obligatorio de tocar
  waybar/              config (módulos) y style.css (forma de la barra)
  rofi/                config.rasi, theme.rasi (forma de los menús), fuentes
  hypr/conf/           decorations (bordes, gaps, blur) y animations, .conf y .lua
  hypr/hyprlock.conf   la pantalla de bloqueo
  wlogout/  kitty/  fastfetch/  sddm/look.conf
```

## Crear uno

```bash
~/.config/hypr/scripts/LookNew.sh cobre fundidora   # copia fundidora como «cobre»
$EDITOR ~/.config/hypr/looks/cobre/look.toml        # colores, fuente, estilo
~/.config/hypr/scripts/LookSwitch.sh cobre          # probarlo
```

Con cambiar `look.toml` ya es otro look. Para cambiar la *forma* (la barra, los
menús, los bordes), se editan los archivos de cada app en su carpeta.
El look aparece solo en el menú de looks y en el instalador.

## look.toml

```toml
[about]
es = "descripción corta"          # menú de looks e instalador
en = "short description"

[font]
family = "MartianMono Nerd Font"  # {{font}} en los archivos del look
package = "ttf-martian-mono-nerd" # paquete de Arch que la instala
display = "Noto Serif"            # opcional: {{font_display}}, para títulos

[colors]
from = "palette"                  # "palette": los de aquí · "wallpaper": wallust
background = "#0a0605"            # con "palette": los 16 de la terminal +
foreground = "#aaadad"            #   background/foreground/cursor
color0 = "#282119"                #   (kitty, vato, taco, arre, nvim, GTK/Qt)
# … color15

[colors.named]                    # nombres propios del look (con las dos fuentes)
acc = "#8f7156"                   # un color…
hi = "color15"                    # …o el nombre de otro
critical = "#e06c75"

[style]                           # rola, vato, taco, arre y nvim
borders = "thick"                 # auto rounded plain double thick dashed none
bar = "blocks"                    # line knob blocks dots ascii
labels = "short"                  # icons short words
case = "upper"                    # normal upper lower
select = "inverse"                # fill bar inverse
tint = "color"                    # color phosphor ink
transparent = false

[wallust]
palette = "dark16"                # cómo saca wallust los colores del wallpaper

[kitty]                           # opcional: más colores de kitty
selection_background = "acc"
```

## Usar los colores y la fuente en los archivos del look

| archivo | color | con transparencia | fuente |
|---|---|---|---|
| waybar, wlogout (CSS) | `@acc` | `alpha(@acc, 0.5)` | `{{font}}` |
| rofi (`.rasi`) | `@acc` | `@acc_a80` | `{{font}}` |
| hyprland (`.conf`), hyprlock | `$acc` | `$acc_a80` | `{{font}}` |
| hyprland (`.lua`) | `c.acc` | `c.acc_a80` | — |
| sddm/look.conf | `"@acc"` | — | `{{font}}` |
| kitty.conf | — | — | `{{font}} Mono` |

`_a80` es la transparencia en hex (`80` = la mitad, `ff` = sólido); se generan
solas las que use el look. Los de la terminal (`@color12`, `@background`…)
también sirven, y en los looks de wallpaper son los únicos que cambian con él.

Lo que genera `LookBuild.py` (no se edita a mano): los colores de cada app
(`waybar/wallust/colors-waybar.css`, `rofi/wallust/colors-rofi.rasi`,
`hypr/wallust/wallust-hyprland.{conf,lua}`, el theme de kitty, cava),
`wallust/wallust.toml` (de `wallust/wallust.base.toml`) y `rola/look.json`.
