#!/usr/bin/env bash
# Una app de terminal de discada en su ventana flotante (picha, fierro): si
# ya está abierta, se enfoca; si no, kitty con la clase de la app.
#
#   TuiApp.sh picha | fierro [ARGS…]

app=$1; shift
# Hyprland no trae ~/.local/bin en el PATH (ahí lo deja cargo install)
PATH="$HOME/.local/bin:$PATH"
. "$HOME/.config/hypr/scripts/lang.sh"

if ! command -v "$app" >/dev/null; then
  notify-send -i "dialog-error-symbolic" "$(L "Falta $app" "$app is missing")" \
    "$(L "Instálalo con: cargo install --git https://github.com/daniiiqa/$app --root ~/.local" \
         "Install it with: cargo install --git https://github.com/daniiiqa/$app --root ~/.local")"
  exit 1
fi

if hyprctl clients -j | jq -e --arg c "$app" 'any(.[]; .class == $c)' >/dev/null; then
  exec "$HOME/.config/hypr/scripts/Hypr.sh" focus "class:^${app}$"
fi

# como en Vato.sh: kitty pide su último tamaño y Hyprland se lo da por encima
# de la regla, así que se le dice de entrada 55%×60% del monitor
read -r mw mh < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\((.width / .scale) | floor) \((.height / .scale) | floor)"')
exec kitty --class "$app" --title "$app" -o remember_window_size=no \
  -o initial_window_width=$(( ${mw:-1920} * 55 / 100 )) -o initial_window_height=$(( ${mh:-1080} * 60 / 100 )) \
  "$app" "$@"
