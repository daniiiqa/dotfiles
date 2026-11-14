#!/usr/bin/env bash
# Custom (dany): el fetch de discada. Lo dibuja cacha (~/.local/bin/cacha, el
# sucesor de fastfetch: el estilo sale de FETCH_STYLE en hypr/discada.conf,
# el menú SUPER+Shift+E → fastfetch); si no está, fastfetch con el config del
# look, como antes.
#
#   Fetch.sh [estilo]   dibujar (look | wallpaper | ficha | pixel:<nombre> | none)
#   Fetch.sh refresh    que las terminales recién abiertas se redibujen

cacha="$HOME/.local/bin/cacha"

# ── refresh: al cambiar de look, de wallpaper o de estilo (LookSwitch.sh,
# WallustSwww.sh, QuickSettings.sh). Las terminales recién abiertas, donde
# todavía no corres nada, se anotan en $XDG_RUNTIME_DIR/discada-fetch/<pid>
# (FetchHook.sh) y aquí les llega SIGUSR2 para que redibujen. Espera un
# respiro (kitty relee sus colores) y si en ese rato llega otro refresh, solo
# el último avisa.
if [ "${1:-}" = refresh ]; then
  dir="${XDG_RUNTIME_DIR:-/tmp}/discada-fetch"
  [ -d "$dir" ] || exit 0
  token="$$.$RANDOM"; echo "$token" > "$dir/.refresh"
  (
    sleep 0.6
    [ "$(cat "$dir/.refresh" 2>/dev/null)" = "$token" ] || exit 0
    for f in "$dir"/[0-9]*; do
      [ -e "$f" ] || continue
      pid=${f##*/}
      # solo una zsh viva que se anotó, la misma que arrancó entonces (a otra,
      # SIGUSR2 la mataría)
      if [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = zsh ] &&
         [ "$(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null)" = "$(cat "$f")" ]; then kill -USR2 "$pid" 2>/dev/null
      else rm -f "$f"; fi
    done
  ) >/dev/null 2>&1 &
  exit 0
fi

[ -x "$cacha" ] && exec "$cacha" "$@"
command -v fastfetch >/dev/null && exec fastfetch
