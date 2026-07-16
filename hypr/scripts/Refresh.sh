#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing waybar, rofi, swaync, quickshell, wallust
#
# Custom (dany): reload EN CALIENTE en lugar de matar y relanzar.
# Lo único que este script necesita lograr tras un cambio de wallpaper es
# que las barras relean los colores de wallust — waybar (SIGUSR2) y swaync
# (swaync-client) saben hacerlo sin morir, así que la barra ya no parpadea
# ni re-instancia sus módulos. El kill queda solo como fallback si el
# proceso no está corriendo. quickshell sí se reinicia: no tiene reload.

UserScripts=$HOME/.config/hypr/UserScripts

# waybar: reload (config + CSS) si corre; lanzarlo si no
if pidof waybar >/dev/null; then
  killall -SIGUSR2 waybar
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

# quickshell: sin reload de colores → restart completo
pkill qs 2>/dev/null
sleep 0.2
qs -c overview >/dev/null 2>&1 &

# Relaunching rainbow borders if the script exists
if [ -e "${UserScripts}/RainbowBorders.sh" ]; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
