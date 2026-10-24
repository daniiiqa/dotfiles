#!/usr/bin/env bash
# Recarga waybar/swaync/rofi tras un cambio de wallpaper.
# Uso: Refresh.sh [--full]
#
# Reload EN CALIENTE en lugar de matar y relanzar.
# Lo único que este script necesita lograr tras un cambio de wallpaper es
# que las barras relean los colores de wallust — waybar (SIGUSR2) y swaync
# (swaync-client) saben hacerlo sin morir, así que la barra ya no parpadea
# ni re-instancia sus módulos. El kill queda solo como fallback si el
# proceso no está corriendo.

# waybar: con "reload_style_on_change" la barra vigila style.css (y los
# @import, o sea los colores de wallust) y se re-estiliza sola, sin
# reconstruirse. Por eso un cambio de wallpaper no necesita señal.
# --full (SUPER+Alt+R) fuerza el reload completo de config + CSS.
if pidof waybar >/dev/null; then
  [ "$1" = "--full" ] && killall -SIGUSR2 waybar
else
  waybar &
fi

# swaync: reload de config y CSS en caliente; lanzarlo si no corre
if pidof swaync >/dev/null; then
  swaync-client --reload-config 2>/dev/null
  swaync-client --reload-css 2>/dev/null
else
  swaync >/dev/null 2>&1 &
fi

# rofi no es daemon: si quedó un menú abierto ciérralo, el próximo
# lanzamiento lee los colores nuevos solo
pkill rofi 2>/dev/null

exit 0
