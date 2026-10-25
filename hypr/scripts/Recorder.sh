#!/usr/bin/env bash
# Grabador de pantalla: gpu-screen-recorder sin su interfaz (gsr-ui). Los
# avisos van por swaync, el menú por rofi y el indicador por waybar
# (custom/recorder), así que todo sigue al look. Ajustes: hypr/recorder.conf.
#
# Sin aviso al empezar ni al prender el replay: gsr captura por KMS (directo de
# la GPU), así que lo que salga en pantalla queda en el video; las reglas de
# Hyprland (noscreenshare) no aplican. El indicador de waybar basta.
#
# Uso: Recorder.sh menu                    menú de rofi (ALT+Z)
#      Recorder.sh screen|region|window    empezar a grabar (o detener si ya graba)
#      Recorder.sh stop | pause
#      Recorder.sh replay [on|off]         replay buffer (sin argumento: alterna)
#      Recorder.sh save [10|30|60|300|600] guardar el replay (todo o los últimos N s)
#      Recorder.sh status                  JSON para waybar
#      Recorder.sh autostart               replay al iniciar sesión, si está activado
#      Recorder.sh FILE TYPE               lo llama gpu-screen-recorder (-sc) al guardar

cfg="$HOME/.config"
self=$(readlink -f "$0")
run="${XDG_RUNTIME_DIR:-/tmp}/recorder"
mkdir -p "$run"

DIR="$HOME/Videos"; FPS=60; QUALITY=very_high; CODEC=auto; CURSOR=yes
AUDIO="default_output|default_input"
RECORD_DND=yes; REPLAY_SECONDS=60; REPLAY_AUDIO="default_output"; REPLAY_BITRATE=40000; REPLAY_ON_STARTUP=no
[ -f "$cfg/hypr/recorder.conf" ] && . "$cfg/hypr/recorder.conf"
mkdir -p "$DIR"

I_REC=$'\U000f044b'; I_PAUSE=$'\U000f03e5'; I_REPLAY=$'\U000f0459'
I_SCREEN=$'\U000f0379'; I_REGION=$'\U000f019e'; I_WINDOW=$'\U000f0614'
I_STOP=$'\U000f0666'; I_SAVE=$'\U000f0193'

alive() { [ -f "$run/$1.pid" ] && kill -0 "$(cat "$run/$1.pid")" 2>/dev/null; }
bar() { pkill -RTMIN+10 -x waybar; }
# no molestar mientras graba (si ya estaba puesto, no se toca al terminar)
dnd_on() {
  [ "$RECORD_DND" = yes ] || return
  [ "$(swaync-client -D 2>/dev/null)" = false ] || return
  swaync-client -dn >/dev/null 2>&1 && touch "$run/rec.dnd"
}
dnd_restore() { [ -f "$run/rec.dnd" ] && rm -f "$run/rec.dnd" && swaync-client -df >/dev/null 2>&1; }
note() { notify-send -e -a Grabador -u low -i "${3:-media-record}" "$1" "$2"; }

monitor() { hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'; }

# lanza gpu-screen-recorder en segundo plano; al terminar limpia su estado
launch() {
  local kind=$1; shift
  (
    gpu-screen-recorder "$@" -sc "$self" >"$run/$kind.log" 2>&1 &
    echo $! >"$run/$kind.pid"
    date +%s >"$run/$kind.start"
    bar
    wait $!
    rc=$?
    rm -f "$run/$kind".{pid,start,paused,pausedtotal}
    [ "$kind" = rec ] && dnd_restore
    bar
    # 0 = guardado; 130/2 = Ctrl+C; lo demás es un error de verdad
    if [ $rc -ne 0 ] && [ $rc -ne 130 ] && [ $rc -ne 2 ]; then
      note "No se pudo grabar" "$(grep -v '^$' "$run/$kind.log" | tail -n 2)" dialog-error
    fi
  ) >/dev/null 2>&1 &
  disown
}

record() {
  if alive rec; then stop; return; fi
  local target=()
  case "$1" in
    region)
      local g; g=$(slurp -f '%wx%h+%x+%y') || return 0
      target=(-w region -region "$g") ;;
    window)
      local g; g=$(hyprctl activewindow -j | jq -r 'if .size then "\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])" else empty end')
      [ -z "$g" ] && { note "Grabador" "No hay ventana activa"; return 1; }
      target=(-w region -region "$g") ;;
    *)
      target=(-w "$(monitor)") ;;
  esac
  local audio=()
  [ -n "$AUDIO" ] && audio=(-a "$AUDIO" -ac opus)
  dnd_on
  launch rec "${target[@]}" -f "$FPS" -q "$QUALITY" -k "$CODEC" -c mp4 "${audio[@]}" \
    -cursor "$CURSOR" -o "$DIR/Video_$(date +%F_%H-%M-%S).mp4"
}

stop() { alive rec && kill -INT "$(cat "$run/rec.pid")"; }

pause() {
  alive rec || return
  kill -USR2 "$(cat "$run/rec.pid")"
  if [ -f "$run/rec.paused" ]; then
    local t=$(( $(date +%s) - $(cat "$run/rec.paused") ))
    echo $(( $(cat "$run/rec.pausedtotal" 2>/dev/null || echo 0) + t )) >"$run/rec.pausedtotal"
    rm -f "$run/rec.paused"
  else
    date +%s >"$run/rec.paused"
  fi
  bar
}

replay() {
  local want=$1
  [ -z "$want" ] && { alive replay && want=off || want=on; }
  if [ "$want" = off ]; then
    alive replay && kill -INT "$(cat "$run/replay.pid")"
    return
  fi
  alive replay && return
  local audio=()
  [ -n "$REPLAY_AUDIO" ] && audio=(-a "$REPLAY_AUDIO" -ac opus)
  launch replay -w "$(monitor)" -f "$FPS" -k "$CODEC" -c mp4 "${audio[@]}" -cursor "$CURSOR" \
    -r "$REPLAY_SECONDS" -replay-storage ram -bm cbr -q "$REPLAY_BITRATE" -o "$DIR"
}

save() {
  alive replay || { note "Replay apagado" "Enciéndelo con ALT+SHIFT+F10"; return 1; }
  local pid; pid=$(cat "$run/replay.pid")
  case "$1" in
    10) kill -RTMIN+1 "$pid" ;; 30) kill -RTMIN+2 "$pid" ;; 60) kill -RTMIN+3 "$pid" ;;
    300) kill -RTMIN+4 "$pid" ;; 600) kill -RTMIN+5 "$pid" ;;
    *) kill -USR1 "$pid" ;;
  esac
}

saved() {
  local file=$1 type=$2 thumb="$run/thumb-$$.png" title="Grabación guardada"
  [ "$type" = replay ] && title="Replay guardado"
  [ "$type" = regular ] && dnd_restore   # para que este aviso sí se vea
  ffmpegthumbnailer -i "$file" -o "$thumb" -s 256 >/dev/null 2>&1 || thumb=video-x-generic
  ( act=$(notify-send -e -a Grabador -i "$thumb" -A open=Abrir -A folder=Carpeta \
            "$title" "$(basename "$file")")
    case "$act" in
      open) xdg-open "$file" ;;
      folder) xdg-open "$(dirname "$file")" ;;
    esac ) >/dev/null 2>&1 &
  disown
}

mmss() { printf '%02d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

status() {
  local text="" class=() tip=()
  if alive rec; then
    local now; now=$(date +%s)
    local t=$(( now - $(cat "$run/rec.start") - $(cat "$run/rec.pausedtotal" 2>/dev/null || echo 0) ))
    if [ -f "$run/rec.paused" ]; then
      t=$(( t - (now - $(cat "$run/rec.paused")) ))
      text="$I_PAUSE $(mmss $t)"; class+=(paused); tip+=("Grabación en pausa")
    else
      text="$I_REC $(mmss $t)"; class+=(recording); tip+=("Grabando")
    fi
    tip+=("click: detener · medio: pausa · derecho: menú")
  fi
  if alive replay; then
    text="${text:+$text  }$I_REPLAY"; class+=(replay)
    [ ${#tip[@]} -eq 0 ] && tip+=("Replay: últimos ${REPLAY_SECONDS}s" "click: guardar · derecho: menú") \
                         || tip+=("Replay encendido")
  fi
  jq -cn --arg t "$text" --arg tip "$(printf '%s\n' "${tip[@]}" | sed '/^$/d')" \
    --arg c "${class[*]}" '{text: $t, tooltip: $tip, class: ($c | split(" "))}'
}

# click en el indicador: detener la grabación o, si solo hay replay, guardarlo
click() { if alive rec; then stop; elif alive replay; then save; fi; }

menu() {
  pidof rofi >/dev/null && pkill rofi
  local opts=()
  if alive rec; then
    opts+=("$I_STOP  detener grabación")
    [ -f "$run/rec.paused" ] && opts+=("$I_PAUSE  reanudar") || opts+=("$I_PAUSE  pausar")
  else
    opts+=("$I_SCREEN  grabar pantalla" "$I_REGION  grabar región" "$I_WINDOW  grabar ventana")
  fi
  if alive replay; then
    opts+=("$I_SAVE  guardar replay (${REPLAY_SECONDS}s)" "$I_SAVE  guardar últimos 10s"
           "$I_SAVE  guardar últimos 30s" "$I_REPLAY  apagar replay")
  else
    opts+=("$I_REPLAY  encender replay")
  fi
  local pick
  pick=$(printf '%s\n' "${opts[@]}" | rofi -dmenu -i -p grabar -config "$cfg/rofi/config-edit.rasi" \
    -mesg "videos en ${DIR/#$HOME/\~}") || return 0
  case "$pick" in
    *"detener grabación") stop ;;
    *pausar|*reanudar) pause ;;
    *"grabar pantalla") sleep 0.2; record screen ;;
    *"grabar región") record region ;;
    *"grabar ventana") sleep 0.2; record window ;;
    *"guardar replay"*) save ;;
    *"últimos 10s") save 10 ;;
    *"últimos 30s") save 30 ;;
    *"apagar replay") replay off ;;
    *"encender replay") replay on ;;
  esac
}

case "$1" in
  menu) menu ;;
  screen|region|window) record "$1" ;;
  stop) stop ;;
  pause) pause ;;
  replay) replay "$2" ;;
  save) save "$2" ;;
  click) click ;;
  status) status ;;
  autostart) [ "$REPLAY_ON_STARTUP" = yes ] && { sleep 3; replay on; } ;;
  *) if [ -f "$1" ]; then saved "$1" "$2"; exit; fi   # -sc: ruta y tipo
     sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
