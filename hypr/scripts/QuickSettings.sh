#!/usr/bin/env bash
# discada — el centro de ajustes del rice (SUPER+Shift+E): look, shader,
# idioma, visualizador, grabador, notificaciones, batería, game mode y blur; más los submenús para
# editar la config y abrir las herramientas del sistema. Cada cambio vuelve a
# abrir el menú en la misma fila, así se pueden tocar varias cosas seguidas.

hypr="$HOME/.config/hypr"
scripts="$hypr/scripts"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
iDIR="$HOME/.config/swaync/images"
discada="$hypr/discada.conf"
recconf="$hypr/recorder.conf"
vis="$HOME/.config/waybar/visualizer.json"

# $term y $edit salen de conf/defaults (.lua o .conf, Hypr.sh lo resuelve)
eval "$("$scripts/Hypr.sh" defaults | grep -E '^(term|edit)=')"
term=${term:-kitty}
edit=${EDITOR:-${edit:-nano}}

. "$scripts/lang.sh"

I_LOOK=$'\U000f03d8'; I_SHADER=$'\U000f0068'; I_LANG=$'\U000f05ca'; I_VIS=$'\U000f0ea2'
I_REC=$'\U000f044b'; I_GAME=$'\U000f0297'; I_BLUR=$'\U000f00b5'; I_EDIT=$'\U000f03eb'
I_TOOLS=$'\U000f1064'; I_KEYS=$'\U000f030c'; I_FONT=$'\U000f027f'; I_UPDATE=$'\U000f06b0'
I_NOTIF=$'\U000f009a'; I_BAT=$'\U000f0079'
arre="$HOME/.local/bin/arre"

need() {
  command -v "$1" &>/dev/null && return 0
  notify-send -i "dialog-error-symbolic" "$(L "Falta $1" "$1 is missing")" "$(L "Instálalo primero" "Install it first")"
  return 1
}

# KEY=valor en un archivo tipo bash, respetando el comentario de la línea
set_conf() {
  local file=$1 key=$2 val=$3 tmp
  tmp=$(mktemp)
  awk -v k="$key" -v v="$val" '
    index($0, k "=") == 1 {
      c = ""
      if (match($0, /[ \t]+#.*/)) c = substr($0, RSTART)
      $0 = k "=" v c; found = 1
    }
    { print }
    END { if (!found) print k "=" v }' "$file" > "$tmp" && cat "$tmp" > "$file"
  rm -f "$tmp"
}
get_conf() { sed -nE "s/^$2=\"?([^\"# ]*)\"?.*/\1/p" "$1" 2>/dev/null | head -n1; }

# siguiente valor de una lista (vuelve al principio)
cycle() {
  local cur=$1; shift
  local i
  for ((i = 1; i <= $#; i++)); do
    [ "${!i}" = "$cur" ] && { local n=$(( i % $# + 1 )); echo "${!n}"; return; }
  done
  echo "$1"
}

onoff() { [ "$1" = yes ] && L "sí" "yes" || L "no" "no"; }

# rofi con la fila elegida guardada en $row; imprime el índice
pick() {
  local prompt=$1 mesg=$2; shift 2
  printf '%s\n' "$@" | rofi -dmenu -i -format i -no-custom -p "$prompt" \
    -config "$rofi_theme" -selected-row "${row:-0}" ${mesg:+-mesg "$mesg"}
}

# ── idioma ───────────────────────────────────────────────────────────────────
set_language() {
  set_conf "$discada" LANGUAGE "$1"
  DISCADA_LANG=$1
  # rola tiene su propio idioma: que siga al rice
  local rola="$HOME/.config/rola/config.json" tmp
  if [ -f "$rola" ] && command -v jq >/dev/null; then
    tmp=$(mktemp) && jq --arg l "$1" '.lang = $l' "$rola" > "$tmp" && cat "$tmp" > "$rola"
    rm -f "$tmp"
  fi
  # AppStrip lo relee en cada render (el reload lo dispara); el visualizador
  # se reinicia solo al ver el cambio
  hyprctl reload >/dev/null
  pkill -RTMIN+10 -x waybar
  notify-send -e -u low -i "preferences-system-notifications-symbolic" "discada" "$(L "Idioma: español" "Language: English")"
}

# ── visualizador ─────────────────────────────────────────────────────────────
vis_menu() {
  local names=() json=()
  add() { names+=("$1"); json+=("$2"); }
  add "braille · 12"                 '{"style": "braille", "bars": 12}'
  add "braille · 16"                 '{"style": "braille", "bars": 16}'
  add "braille · 20"                 '{"style": "braille", "bars": 20}'
  add "peaks · 16"                   '{"style": "peaks", "bars": 16}'
  add "peaks · 20"                   '{"style": "peaks", "bars": 20}'
  add "$(L bloques blocks) · 8   ▁▃▅█" '{"style": "chars", "bars": 8, "chars": "▁▂▃▄▅▆▇█"}'
  add "$(L bloques blocks) · 12  ▁▃▅█" '{"style": "chars", "bars": 12, "chars": "▁▂▃▄▅▆▇█"}'
  add "ascii · 10  .:-=+*#"           '{"style": "chars", "bars": 10, "chars": ".:-=+*#"}'
  add "$(L lápiz pencil) · 12  _.-~^"  '{"style": "chars", "bars": 12, "chars": "_.-~^"}'
  local i
  i=$(row=0 pick "$(L visualizador visualizer)" \
      "$(L "se guarda en el look actual" "saved into the current look")" "${names[@]}") || return
  printf '%s\n' "${json[$i]}" > "$vis"
}

vis_now() {
  local style bars chars
  { read -r style; read -r bars; read -r chars; } < <(jq -r '.style // "braille", .bars // 16, .chars // ""' "$vis" 2>/dev/null)
  case "$style" in
    chars) [[ $chars == ▁* ]] && echo "$(L bloques blocks) · $bars" || echo "$chars · $bars" ;;
    "") echo braille ;;
    *) echo "$style · $bars" ;;
  esac
}

# ── grabador ─────────────────────────────────────────────────────────────────
audio_name() {
  case "$1" in
    "default_output|default_input") L "sistema + mic" "system + mic" ;;
    default_output) L sistema system ;;
    default_input) L mic mic ;;
    "") L ninguno none ;;
    *) echo "$1" ;;
  esac
}

rec_menu() {
  local row=0
  while true; do
    local fps q audio rs rlen dnd i
    fps=$(get_conf "$recconf" FPS); q=$(get_conf "$recconf" QUALITY)
    audio=$(sed -nE 's/^AUDIO="?([^"#]*)"?.*/\1/p' "$recconf" | head -n1 | sed 's/ *$//')
    rs=$(get_conf "$recconf" REPLAY_ON_STARTUP); rlen=$(get_conf "$recconf" REPLAY_SECONDS)
    dnd=$(get_conf "$recconf" RECORD_DND)
    i=$(pick "$(L grabador recorder)" \
        "$(L "el replay toma los cambios al volver a encenderlo" "replay picks up changes when turned on again")" \
        "fps: ${fps:-60}" \
        "$(L calidad quality): ${q:-very_high}" \
        "audio: $(audio_name "$audio")" \
        "$(L "no molestar al grabar" "do not disturb while recording"): $(onoff "${dnd:-yes}")" \
        "$(L "replay al iniciar sesión" "replay at login"): $(onoff "${rs:-no}")" \
        "$(L "duración del replay" "replay length"): ${rlen:-60}s" \
        "$(L "abrir carpeta de videos" "open videos folder")" \
        "‹ $(L volver back)") || return
    row=$i
    case "$i" in
      0) set_conf "$recconf" FPS "$(cycle "${fps:-60}" 30 60 120 144)" ;;
      1) set_conf "$recconf" QUALITY "$(cycle "${q:-very_high}" medium high very_high ultra)" ;;
      2) set_conf "$recconf" AUDIO "\"$(cycle "$audio" "default_output|default_input" default_output default_input "")\"" ;;
      3) set_conf "$recconf" RECORD_DND "$(cycle "${dnd:-yes}" yes no)" ;;
      4) set_conf "$recconf" REPLAY_ON_STARTUP "$(cycle "${rs:-no}" yes no)" ;;
      5) set_conf "$recconf" REPLAY_SECONDS "$(cycle "${rlen:-60}" 30 60 120 300)" ;;
      6) . "$recconf" 2>/dev/null; xdg-open "${DIR:-$HOME/Videos}" & return ;;
      *) return ;;
    esac
  done
}

# ── notificaciones (arre) ────────────────────────────────────────────────────
POSITIONS=(top-left top-center top-right bottom-left bottom-center bottom-right)
pos_name() {
  case "$1" in
    top-left) L "arriba a la izquierda" "top left" ;;
    top-center) L "arriba al centro" "top center" ;;
    top-right) L "arriba a la derecha" "top right" ;;
    bottom-left) L "abajo a la izquierda" "bottom left" ;;
    bottom-center) L "abajo al centro" "bottom center" ;;
    bottom-right) L "abajo a la derecha" "bottom right" ;;
    *) echo "?" ;;
  esac
}

# un aviso de muestra, de paso (no se queda en el historial)
notif_sample() {
  notify-send -e -t 4000 -a discada -i "preferences-system-notifications-symbolic" \
    "$(L "Así se ven las notificaciones" "This is how notifications look")" "$(pos_name "$("$arre" position)")"
}

notif_menu() {
  [ -x "$arre" ] || { notify-send -i "dialog-error-symbolic" "$(L "Falta arre" "arre is missing")" \
    "cargo install --git https://github.com/daniiiqa/arre --root ~/.local"; return; }
  local row=0
  while true; do
    local pos dnd i j k names=()
    pos=$("$arre" position); dnd=$("$arre" dnd 2>/dev/null)
    i=$(pick "$(L notificaciones notifications)" "$(L "los cambios se ven al momento" "changes show right away")" \
        "$(L posición position): $(pos_name "$pos") ›" \
        "$(L "no molestar" "do not disturb"): $([ "$dnd" = on ] && L sí yes || L no no)" \
        "$(L "probar" "try it")" \
        "‹ $(L volver back)") || return
    row=$i
    case "$i" in
      0) for j in "${POSITIONS[@]}"; do names+=("$(pos_name "$j")"); done
         j=0; for ((k = 0; k < ${#POSITIONS[@]}; k++)); do [ "${POSITIONS[$k]}" = "$pos" ] && j=$k; done
         j=$(row=$j pick "$(L posición position)" "" "${names[@]}") || continue
         "$arre" position "${POSITIONS[$j]}" && notif_sample ;;
      1) "$arre" dnd toggle >/dev/null ;;
      2) notif_sample ;;
      *) return ;;
    esac
  done
}

# ── batería (laptops) ────────────────────────────────────────────────────────
bat="$scripts/Battery.py"
prof_name() {
  case "$1" in
    power-saver) L ahorro "power saver" ;;
    balanced) L balanceado balanced ;;
    performance) L rendimiento performance ;;
    *) echo "?" ;;
  esac
}

bat_menu() {
  local row=0
  while true; do
    local prof saver at i
    prof=$(powerprofilesctl get 2>/dev/null)
    saver=$([ -f "$XDG_RUNTIME_DIR/discada/saver.json" ] && echo yes || echo no)
    at=$(get_conf "$discada" BATTERY_SAVER_AT)
    i=$(pick "$(L batería battery)" \
        "$(L "ahorro: perfil power-saver, sin blur, sombras ni shader y el video en pausa" "saver: power-saver profile, no blur, shadows or shader, video paused")" \
        "$(L "ahorro de batería" "battery saver"): $(onoff "$saver")" \
        "$(L "perfil de energía" "power profile"): $(prof_name "$prof")" \
        "$(L "ahorro solo al" "saver by itself at"): $([ "${at:-20}" = 0 ] && L nunca never || echo "${at:-20}%")" \
        "‹ $(L volver back)") || return
    row=$i
    case "$i" in
      0) "$bat" saver ;;
      1) "$bat" profile ;;
      2) set_conf "$discada" BATTERY_SAVER_AT "$(cycle "${at:-20}" 20 30 15 10 0)" ;;
      *) return ;;
    esac
  done
}

# ── editar / herramientas ────────────────────────────────────────────────────
edit_menu() {
  local names=() files=()
  add() { names+=("$1"); files+=("$2"); }
  add "discada ($(L "idioma" "language"))"            "$discada"
  add "$(L "Grabador" "Recorder")"                    "$recconf"
  local f="$scripts/Hypr.sh file"   # conf/X.lua o conf/X.conf, el que se usa
  add "$(L "Apps por defecto" "Default apps")"        "$($f defaults)"
  add "$(L "Atajos" "Keybinds")"                      "$($f keybinds)"
  add "$(L "Arranque" "Startup")"                     "$($f startup)"
  add "$(L "Ajustes generales" "General settings")"  "$($f settings)"
  add "$(L "Decoraciones (del look)" "Decorations (look)")" "$($f decorations)"
  add "$(L "Animaciones (del look)" "Animations (look)")"   "$($f animations)"
  add "$(L "Reglas de ventanas" "Window rules")"      "$($f windowrules)"
  add "$(L "Apps fijadas" "Pinned apps")"             "$hypr/conf/pinned.conf"
  add "$(L "Variables de entorno" "Environment")"     "$($f env)"
  add "Idle (hypridle)"                               "$hypr/hypridle.conf"
  add "Lock (hyprlock)"                               "$hypr/hyprlock.conf"
  local i
  i=$(row=0 pick "$(L editar edit)" "" "${names[@]}" "‹ $(L volver back)") || return
  [ -n "${files[$i]}" ] && $term -e $edit "${files[$i]}" &
}

tools_menu() {
  # vato (audio, bluetooth, red, sistema, notificaciones) en la terminal con el look; solo los
  # monitores siguen en una app gráfica. GTK/Qt ya no hacen falta aquí:
  # AppColors.py les pone los colores del look solo.
  local i
  i=$(row=0 pick "$(L herramientas tools)" "" \
      "Audio (vato)" "Bluetooth (vato)" "$(L "Red" "Network") (vato)" "$(L "Sistema" "System") (vato)" \
      "$(L "Notificaciones" "Notifications") (vato)" \
      "$(L "Monitores" "Monitors") (nwg-displays)" "$(L "Buscar atajos" "Search shortcuts")" "‹ $(L volver back)") || return
  case "$i" in
    0) "$scripts/Vato.sh" audio & ;;
    1) "$scripts/Vato.sh" bluetooth & ;;
    2) "$scripts/Vato.sh" network & ;;
    3) "$scripts/Vato.sh" system & ;;
    4) "$scripts/Vato.sh" notifications & ;;
    5) need nwg-displays && nwg-displays & ;;
    6) "$scripts/KeyBinds.sh" & ;;
  esac
}

# ── menú principal ───────────────────────────────────────────────────────────
pidof rofi >/dev/null && pkill rofi

row=0
while true; do
  look=$(cat "$hypr/looks/.current" 2>/dev/null)
  deco=$("$scripts/Hypr.sh" file decorations)
  shader=""
  if grep -qE '^\s*screen_shader\s*=' "$deco"; then shader=yes
  elif grep -qE '^\s*(#|--)\s*screen_shader\s*=' "$deco"; then shader=no; fi
  game=$([ "$("$scripts/Hypr.sh" get animations:enabled)" = 0 ] && echo yes || echo no)
  blur=$([ "$("$scripts/Hypr.sh" get decoration:blur:passes)" = 2 ] && L normal normal || L ligero light)

  names=() acts=()
  add() { names+=("$1"); acts+=("$2"); }
  add "$I_LOOK  look: ${look:-?}"                                   look
  [ -n "$shader" ] && add "$I_SHADER  shader: $([ $shader = yes ] && echo on || echo off)" shader
  add "$I_LANG  $(L idioma language): $(L español English)"         lang
  font=$(sed -nE 's/^FONT_SIZE=\s*([+-]?[0-9]+).*/\1/p' "$discada" | head -n1)
  case "${font:-0}" in 0) font_txt=normal ;; -*) font_txt=$font ;; *) font_txt=+$font ;; esac
  add "$I_FONT  $(L "tamaño de letra" "font size"): $font_txt"     font
  add "$I_VIS  $(L visualizador visualizer): $(vis_now)"           vis
  add "$I_REC  $(L grabador recorder) ›"                           rec
  [ -x "$arre" ] && add "$I_NOTIF  $(L notificaciones notifications): $(pos_name "$("$arre" position)") ›" notif
  add "$I_GAME  game mode: $(onoff "$game")"                        game
  if "$bat" has; then
    add "$I_BAT  $(L batería battery): $("$bat" status | jq -r '"\(.percentage)%"') ›" battery
  fi
  add "$I_BLUR  blur: $blur"                                        blur
  add "$I_EDIT  $(L "editar config" "edit config") ›"               edit
  add "$I_TOOLS  $(L herramientas tools) ›"                          tools
  add "$I_KEYS  $(L atajos shortcuts) (SUPER+H)"                    keys
  add "$I_UPDATE  $(L "actualizar discada" "update discada")"           update

  i=$(pick discada "$(L "el rice de los looks · Esc para salir" "the rice of looks · Esc to close")" "${names[@]}") || exit 0
  row=$i
  case "${acts[$i]}" in
    look)   exec "$scripts/LookSwitch.sh" ;;
    shader) "$scripts/LookSwitch.sh" shader ;;
    font)   "$scripts/FontSize.py" set "$(cycle "${font:-0}" 0 1 2 3 4 -2 -1)" ;;
    lang)   set_language "$([ "$DISCADA_LANG" = es ] && echo en || echo es)" ;;
    vis)    vis_menu ;;
    rec)    rec_menu ;;
    notif)  notif_menu ;;
    battery) bat_menu ;;
    game)   "$scripts/GameMode.sh"; sleep 0.3 ;;
    blur)   "$scripts/ChangeBlur.sh" ;;
    edit)   edit_menu; exit 0 ;;
    tools)  tools_menu; exit 0 ;;
    keys)   exec "$scripts/KeyHints.sh" ;;
    update) exec $term --class discada-update -e bash -c "'$scripts/Update.sh'; echo; read -rp '$(L "Enter para cerrar" "Press Enter to close")'" ;;
  esac
done
