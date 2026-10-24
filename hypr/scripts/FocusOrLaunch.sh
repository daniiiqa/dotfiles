#!/usr/bin/env bash
# Custom (dany): enfoca la ventana de la clase dada; si no hay, lanza la app.
# Uso: FocusOrLaunch.sh <clase-de-ventana> <comando> [args...]
class="$1"; shift
if hyprctl clients -j | jq -e --arg c "$class" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl dispatch focuswindow "class:^${class}$"
else
  "$@" >/dev/null 2>&1 &
fi
