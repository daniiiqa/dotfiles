#!/usr/bin/env bash
# Custom (dany): el protector de pantalla de discada: jardín a pantalla completa
# cuando llevas rato sin usar la compu, antes de que se bloquee (hypridle).
#
#   Protector.sh empieza   lo abre (si no hay candado ni algo a pantalla completa)
#   Protector.sh quita     lo cierra (al volver; también sale solo con una tecla)

PATH="$HOME/.local/bin:$PATH"
clase=jardin-protector

case "$1" in
  empieza)
    command -v jardin >/dev/null || exit 0
    # ya bloqueado (chapa o hyprlock): nada
    pidof chapa hyprlock >/dev/null && exit 0
    # un juego o un video a pantalla completa: no estorbar
    [ "$(hyprctl activewindow -j 2>/dev/null | jq -r '.fullscreen // 0')" != 0 ] && exit 0
    hyprctl clients -j | jq -e --arg c "$clase" 'any(.[]; .class == $c)' >/dev/null && exit 0
    setsid -f kitty --class "$clase" --title jardín -o window_padding_width=0 \
      -o background_opacity=1 jardin --protector >/dev/null 2>&1
    ;;
  quita)
    hyprctl clients -j | jq -r --arg c "$clase" '.[] | select(.class == $c) | .pid' | xargs -r kill 2>/dev/null
    ;;
  *) echo "uso: Protector.sh empieza | quita" >&2; exit 2 ;;
esac
