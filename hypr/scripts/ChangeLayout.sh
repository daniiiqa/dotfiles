#!/usr/bin/env bash
# Alterna el layout entre dwindle y master (SUPER+Alt+L).
# J/K ciclan ventanas en dwindle y el stack en master; togglesplit vive en
# SUPER+Shift+I — no se toca SUPER+O (es el toggle de opacidad).

notif="$HOME/.config/swaync/images/bell.png"
layout=$(hyprctl -j getoption general:layout | jq -r '.str')

if [ "$layout" = "master" ]; then
  hyprctl --batch "keyword general:layout dwindle; \
    keyword unbind SUPER,J; keyword unbind SUPER,K; \
    keyword bind SUPER,J,cyclenext; keyword bind SUPER,K,cyclenext,prev" >/dev/null
  notify-send -e -u low -i "$notif" "Dwindle layout"
else
  hyprctl --batch "keyword general:layout master; \
    keyword unbind SUPER,J; keyword unbind SUPER,K; \
    keyword bind SUPER,J,layoutmsg,cyclenext; keyword bind SUPER,K,layoutmsg,cycleprev" >/dev/null
  notify-send -e -u low -i "$notif" "Master layout"
fi
