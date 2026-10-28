#!/usr/bin/env bash
# Alterna el layout entre dwindle y master (SUPER+Alt+L).
# J/K ciclan ventanas en dwindle y el stack en master; togglesplit vive en
# SUPER+Shift+I — no se toca SUPER+O (es el toggle de opacidad).

notif="preferences-system-notifications-symbolic"
H="$HOME/.config/hypr/scripts/Hypr.sh"
layout=$("$H" get general:layout)

# SUPER+J/K: en dwindle cambian de ventana, en master recorren la pila
if [ "$layout" = "master" ]; then
  if [ "$("$H" mode)" = lua ]; then
    "$H" lua 'hl.config({ general = { layout = "dwindle" } })
      hl.unbind("SUPER + J"); hl.unbind("SUPER + K")
      hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "next window" })
      hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "previous window" })' >/dev/null
  else
    hyprctl --batch "keyword general:layout dwindle; \
      keyword unbind SUPER,J; keyword unbind SUPER,K; \
      keyword bind SUPER,J,cyclenext; keyword bind SUPER,K,cyclenext,prev" >/dev/null
  fi
  notify-send -e -u low -i "$notif" "Dwindle layout"
else
  if [ "$("$H" mode)" = lua ]; then
    "$H" lua 'hl.config({ general = { layout = "master" } })
      hl.unbind("SUPER + J"); hl.unbind("SUPER + K")
      hl.bind("SUPER + J", hl.dsp.layout("cyclenext"), { description = "next window" })
      hl.bind("SUPER + K", hl.dsp.layout("cycleprev"), { description = "previous window" })' >/dev/null
  else
    hyprctl --batch "keyword general:layout master; \
      keyword unbind SUPER,J; keyword unbind SUPER,K; \
      keyword bind SUPER,J,layoutmsg,cyclenext; keyword bind SUPER,K,layoutmsg,cycleprev" >/dev/null
  fi
  notify-send -e -u low -i "$notif" "Master layout"
fi
