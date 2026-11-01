#!/usr/bin/env bash
# Recarga la barra y rofi tras un cambio de wallpaper.
# Uso: Refresh.sh [--full]

# la barra (empalme) relee sola el look, los colores de wallust
# (empalme/colors.json) y su [bar] (empalme/bar.json), pero solo al cambiar
# el segundo: RTMIN+12 le dice que los revise ya (el telón de farula la
# espera para abrirse). --full (SUPER+Alt+R) la rearma de una vez
# (SIGUSR2); si no está corriendo, la arranca (y cierra waybar, la barra de
# antes, que puede seguir corriendo tras la primera actualización).
if pidof empalme >/dev/null; then
  if [ "$1" = "--full" ]; then
    pkill -SIGUSR2 -x empalme
  else
    pkill -RTMIN+12 -x empalme
  fi
else
  pkill -x waybar
  setsid "$HOME/.config/hypr/scripts/Bar.sh" >/dev/null 2>&1 &
fi

# las notificaciones (arre) toman el look solas, y si no corren las arranca
# D-Bus con la siguiente que llegue: aquí no hay nada que hacer

# rofi no es daemon: si quedó un menú abierto ciérralo, el próximo
# lanzamiento lee los colores nuevos solo
pkill -x jale 2>/dev/null

exit 0
