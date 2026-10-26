#!/usr/bin/env bash
# Las herramientas del sistema de discada: vato (audio, bluetooth, red y
# sistema en la terminal, con el look como rola). Una sola ventana: si ya
# está abierta, se cambia a la pestaña pedida y se enfoca.
#
#   Vato.sh audio | mic | bluetooth | network | wifi | system

tab=${1:-audio}
# Hyprland no trae ~/.local/bin en el PATH (ahí lo deja cargo install)
PATH="$HOME/.local/bin:$PATH"
. "$HOME/.config/hypr/scripts/lang.sh"

if ! command -v vato >/dev/null; then
  notify-send -i "$HOME/.config/swaync/images/error.png" "$(L "Falta vato" "vato is missing")" \
    "$(L "Instálalo con: cargo install --git https://github.com/daniiiqa/vato --root ~/.local" \
         "Install it with: cargo install --git https://github.com/daniiiqa/vato --root ~/.local")"
  exit 1
fi

addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "vato") | .address' | head -n1)
if [ -n "$addr" ]; then
  echo "$tab" > "${XDG_RUNTIME_DIR:-/tmp}/vato.tab"
  hyprctl dispatch focuswindow "address:$addr" >/dev/null
  exit 0
fi

# kitty pide su último tamaño al abrir y Hyprland se lo da por encima de la
# regla: se le dice de entrada 55%×60% del monitor (la regla la centra)
read -r mw mh < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\((.width / .scale) | floor) \((.height / .scale) | floor)"')
exec kitty --class vato --title vato -o remember_window_size=no \
  -o initial_window_width=$(( ${mw:-1920} * 55 / 100 )) -o initial_window_height=$(( ${mh:-1080} * 60 / 100 )) \
  vato "$tab"
