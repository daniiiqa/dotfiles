#!/usr/bin/env bash
# Teclas multimedia: manejan lo que esté sonando (rola, el cel por Bluetooth,
# un video…) y avisan con el mismo aviso que el volumen (arre): canción,
# artista, de dónde sale y una barra con lo que lleva.
# Uso: MediaCtrl.sh --nxt|--prv|--pause|--stop|--show

sDIR="$HOME/.config/hypr/scripts"
. "$sDIR/lang.sh"

# El que está sonando; si nada suena, el primero que haya (rola casi siempre).
pick_player() {
  local p
  for p in $(playerctl -l 2>/dev/null); do
    [ "$(playerctl -p "$p" status 2>/dev/null)" = Playing ] && { echo "$p"; return; }
  done
  playerctl -l 2>/dev/null | grep -v '^playerctld$' | head -1
}

player=$(pick_player)
[ -n "$player" ] || exit 0
pc() { playerctl -p "$player" "$@" 2>/dev/null; }

# "Galaxy de Ana Media Player" (un cel por Bluetooth) → "Galaxy de Ana"
source_name() {
  local id
  id=$(busctl --user get-property "org.mpris.MediaPlayer2.$player" /org/mpris/MediaPlayer2 \
    org.mpris.MediaPlayer2 Identity 2>/dev/null | sed -E 's/^s "(.*)"$/\1/; s/\\//g')
  echo "${id% Media Player}"
}

# un aviso que se reemplaza a sí mismo, como el del volumen
note() {  # ícono, título, cuerpo, [nivel]
  notify-send -e -a discada -u low -h string:x-canonical-private-synchronous:media_notif \
    -h boolean:SWAYNC_BYPASS_DND:true ${4:+-h int:value:$4} -i "$1" "$2" "$3"
}

show() {
  local status title artist from icon length position pct
  status=$(pc status)
  from=$(source_name)
  case "$player" in
    *Media_Player*) icon="smartphone-symbolic" ;;   # el cel por Bluetooth
    *) icon="audio-x-generic-symbolic" ;;
  esac
  if [ "$status" = Paused ]; then
    note "media-playback-pause-symbolic" "$(L Pausa Paused)" "$(pc metadata title) · $from"
    return
  fi
  [ "$status" = Playing ] || return
  title=$(pc metadata title)
  artist=$(pc metadata artist)
  length=$(pc metadata mpris:length)          # µs
  position=$(pc position | cut -d. -f1)        # s
  pct=""
  [ -n "$length" ] && [ "$length" -gt 0 ] && pct=$(( position * 100000000 / length ))
  note "$icon" "${title:-$(L 'Sonando' 'Playing')}" "${artist:+$artist · }$from" "$pct"
}

case "$1" in
  --nxt) pc next; sleep 0.4; show ;;
  --prv) pc previous; sleep 0.4; show ;;
  --pause) pc play-pause; sleep 0.2; show ;;
  --stop) pc stop; note "media-playback-stop-symbolic" "$(L Detenido Stopped)" "$(source_name)" ;;
  --show) show ;;
  *) echo "Uso: $0 --nxt|--prv|--pause|--stop|--show"; exit 1 ;;
esac
