#!/usr/bin/env bash
# Recarga la barra y rofi tras un cambio de wallpaper.
# Uso: Refresh.sh [--full]

# la barra (empalme) relee sola el look, los colores de wallust
# (empalme/colors.json) y su [bar] (empalme/bar.json): un cambio de
# wallpaper no necesita señal. --full (SUPER+Alt+R) la rearma de una vez
# (SIGUSR2); si no está corriendo, la arranca (y cierra waybar, la barra de
# antes, que puede seguir corriendo tras la primera actualización).
if pidof empalme >/dev/null; then
  [ "$1" = "--full" ] && pkill -SIGUSR2 -x empalme
else
  pkill -x waybar
  setsid "$HOME/.config/hypr/scripts/Bar.sh" >/dev/null 2>&1 &
fi

# las notificaciones (arre) toman el look solas, y si no corren las arranca
# D-Bus con la siguiente que llegue: aquí no hay nada que hacer

# rofi no es daemon: si quedó un menú abierto ciérralo, el próximo
# lanzamiento lee los colores nuevos solo
pkill rofi 2>/dev/null

exit 0
