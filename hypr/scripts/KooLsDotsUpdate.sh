#!/usr/bin/env bash
# NEUTRALIZADO (dany, 2026-07-16): esta config ya no sigue los dots de KooL.
# Es una versión propia, auto-gestionada con git en ~/.config.
# El updater original jalaba ~/Hyprland-Dots y corría copy.sh, que aplastaba
# 17 carpetas de .config sin preguntar (así se perdió el sync de SDDM en marzo).
# Si algún día quieres un cambio de upstream, tráelo a mano y commitéalo.

iDIR="$HOME/.config/swaync/images"
notify-send -i "$iDIR/note.png" "Config auto-gestionada" "El updater de KooL está desactivado. Los cambios se manejan con git en ~/.config."
exit 0
