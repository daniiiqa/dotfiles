#!/usr/bin/env bash
# Custom (dany): jale (el launcher, antes rofi) vive en ~/.local/bin,
# fuera del PATH de Hyprland
PATH="$HOME/.local/bin:$PATH"
# discada — el centro de ajustes del rice (SUPER+Shift+E): look, shader,
# idioma, visualizador, grabador, notificaciones, teclado, batería, game mode y blur; más los submenús para
# editar la config y abrir las herramientas del sistema. Cada cambio vuelve a
# abrir el menú en la misma fila, así se pueden tocar varias cosas seguidas.

hypr="$HOME/.config/hypr"
scripts="$hypr/scripts"
jale_theme="$HOME/.config/jale/config-edit.rasi"
iDIR="$HOME/.config/swaync/images"
discada="$hypr/discada.conf"
recconf="$hypr/recorder.conf"
bar="$HOME/.config/empalme/bar.json"   # la barra del look (su [bar])

# $term y $edit salen de conf/defaults.lua (Hypr.sh defaults)
eval "$("$scripts/Hypr.sh" defaults | grep -E '^(term|edit)=')"
term=${term:-kitty}
edit=${EDITOR:-${edit:-nano}}

. "$scripts/lang.sh"

I_LOOK=$'\U000f03d8'; I_SHADER=$'\U000f0068'; I_LANG=$'\U000f05ca'; I_VIS=$'\U000f0ea2'
I_REC=$'\U000f044b'; I_GAME=$'\U000f0297'; I_BLUR=$'\U000f00b5'; I_EDIT=$'\U000f03eb'
I_TOOLS=$'\U000f1064'; I_KEYS=$'\U000f030c'; I_FONT=$'\U000f027f'; I_UPDATE=$'\U000f06b0'
I_TRACKPAD=$'\U000f0322'; I_MACHIN=$'\U000f037a'; I_NOTIF=$'\U000f009a'; I_BAT=$'\U000f0079'; I_TECLADO=$'\U000f030c'; I_FETCH=$'\U000f018d'; I_ENTRADA=$'\U000f0e24'; I_SEMANA=$'\U000f00f0'
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
  printf '%s\n' "$@" | jale -dmenu -i -format i -no-custom -p "$prompt" \
    -config "$jale_theme" -selected-row "${row:-0}" ${mesg:+-mesg "$mesg"}
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
  pkill -RTMIN+10 -x empalme
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
  "$HOME/.local/bin/lena" bar-set visualizer "${json[$i]}"
}

vis_now() {
  local style bars chars
  { read -r style; read -r bars; read -r chars; } < <(jq -r '.modules.visualizer // {} | .style // "braille", .bars // 16, .chars // ""' "$bar" 2>/dev/null)
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
    prof=$("$bat" profile get)
    saver=$([ -f "$XDG_RUNTIME_DIR/discada/saver.json" ] && echo yes || echo no)
    at=$(get_conf "$discada" BATTERY_SAVER_AT)
    i=$(pick "$(L batería battery)" \
        "$(L "ahorro: perfil de ahorro, sin blur, sombras ni shader y el video en pausa" "saver: power-saving profile, no blur, shadows or shader, video paused")" \
        "$(L "ahorro de batería" "battery saver"): $(onoff "$saver")" \
        "$(L "perfil de energía" "power profile"): $(prof_name "$prof")" \
        "$(L "ahorro solo al" "saver by itself at"): $([ "${at:-20}" = 0 ] && L nunca never || echo "${at:-20}%")" \
        "$(L "límites de carga y más" "charge limits and more") (fierro)" \
        "‹ $(L volver back)") || return
    row=$i
    case "$i" in
      0) "$bat" saver ;;
      1) "$bat" profile ;;
      2) set_conf "$discada" BATTERY_SAVER_AT "$(cycle "${at:-20}" 20 30 15 10 0)" ;;
      3) "$scripts/TuiApp.sh" fierro & return ;;
      *) return ;;
    esac
  done
}

# ── editar / herramientas ────────────────────────────────────────────────────
edit_menu() {
  local names=() files=()
  add() { names+=("$1"); files+=("$2"); }
  add "discada ($(L "idioma" "language"))"            "$discada"
  add "Look: $(cat "$hypr/looks/.current" 2>/dev/null) (look.toml)" "$hypr/looks/$(cat "$hypr/looks/.current" 2>/dev/null)/look.toml"
  add "$(L "Grabador" "Recorder")"                    "$recconf"
  local f="$scripts/Hypr.sh file"   # conf/X.lua
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
  # `leña apps` les pone los colores del look solo.
  local i
  i=$(row=0 pick "$(L herramientas tools)" "" \
      "Audio (vato)" "Bluetooth (vato)" "$(L "Red" "Network") (vato)" "$(L "Sistema" "System") (vato)" \
      "$(L "Notificaciones" "Notifications") (vato)" "$(L "Mandar y recibir" "Send and receive") (picha)" \
      "$(L "Monitores" "Monitors") (nwg-displays)" "$(L "Buscar atajos" "Search shortcuts")" "‹ $(L volver back)") || return
  case "$i" in
    0) "$scripts/Vato.sh" audio & ;;
    1) "$scripts/Vato.sh" bluetooth & ;;
    2) "$scripts/Vato.sh" network & ;;
    3) "$scripts/Vato.sh" system & ;;
    4) "$scripts/Vato.sh" notifications & ;;
    5) "$scripts/TuiApp.sh" picha & ;;
    6) need nwg-displays && nwg-displays & ;;
    7) "$scripts/KeyBinds.sh" & ;;
  esac
}

# ── el trackpad ──────────────────────────────────────────────────────────────
# Custom (dany): todo en hypr/discada.conf (TRACKPAD_*), que el updater no
# pisa; conf/settings.lua lo lee al recargar Hyprland. Solo en compus con
# trackpad.
hay_trackpad() { grep -qsi '^N: Name=".*touchpad' /proc/bus/input/devices; }

trackpad_menu() {
  local row=0 i
  while true; do
    local g; g() { local v; v=$(get_conf "$discada" "TRACKPAD_$1"); echo "${v:-$2}"; }
    local en nat tap tdrag lock map click mid dwt speed accel sspeed smeth d3 swipe inv zoom
    en=$(g ENABLED yes) nat=$(g NATURAL yes) tap=$(g TAP yes) tdrag=$(g TAP_DRAG yes)
    lock=$(g DRAG_LOCK no) map=$(g TAP_MAP lrm) click=$(g CLICK areas) mid=$(g MIDDLE no)
    dwt=$(g DWT yes) speed=$(g SPEED 0) accel=$(g ACCEL adaptive) sspeed=$(g SCROLL_SPEED 1.0)
    smeth=$(g SCROLL_METHOD 2fg) d3=$(g DRAG_3FG no) swipe=$(g SWIPE 3) inv=$(g SWIPE_INVERT yes) zoom=$(g ZOOM yes)
    local lock_t map_t click_t accel_t smeth_t d3_t swipe_t
    case "$lock" in timeout) lock_t=$(L "un ratito" "briefly") ;; sticky) lock_t=$(L "hasta otro toque" "until next tap") ;; *) lock_t=no ;; esac
    [ "$map" = lmr ] && map_t=$(L "2 dedos = medio, 3 = derecho" "2 fingers = middle, 3 = right") || map_t=$(L "2 dedos = derecho, 3 = medio" "2 fingers = right, 3 = middle")
    [ "$click" = fingers ] && click_t=$(L "por dedos (2 = derecho, 3 = medio)" "by fingers (2 = right, 3 = middle)") || click_t=$(L "por zona (abajo a la derecha = derecho)" "by area (bottom right = right)")
    [ "$accel" = flat ] && accel_t=$(L "plana (siempre igual)" "flat (always the same)") || accel_t=$(L "adaptiva (más rápido = más lejos)" "adaptive (faster = farther)")
    [ "$smeth" = edge ] && smeth_t=$(L "la orilla derecha" "the right edge") || smeth_t=$(L "dos dedos" "two fingers")
    case "$d3" in 3|4) d3_t="$d3 $(L dedos fingers)" ;; *) d3_t=no ;; esac
    case "$swipe" in 3|4) swipe_t="$swipe $(L dedos fingers)" ;; *) swipe_t=no ;; esac
    i=$(pick trackpad \
        "$(L "se aplica al instante · ojo: arrastrar con 3 dedos le gana a deslizar con 3" "applies right away · note: 3-finger drag beats 3-finger swipe")" \
        "$(L "trackpad" "trackpad"): $(onoff "$en")" \
        "$(L "scroll natural (como en el cel)" "natural scroll (like a phone)"): $(onoff "$nat")" \
        "$(L "tocar para hacer clic" "tap to click"): $(onoff "$tap")" \
        "$(L "tocar y arrastrar" "tap and drag"): $(onoff "$tdrag")" \
        "$(L "seguir arrastrando al soltar" "keep dragging after lifting"): $lock_t" \
        "$(L "toques" "taps"): $map_t" \
        "$(L "clic al apretar" "click when pressing"): $click_t" \
        "$(L "clic medio con izquierdo + derecho" "middle click with left + right"): $(onoff "$mid")" \
        "$(L "apagarlo mientras escribes" "off while typing"): $(onoff "$dwt")" \
        "$(L "velocidad" "speed"): $speed" \
        "$(L "aceleración" "acceleration"): $accel_t" \
        "$(L "velocidad del scroll" "scroll speed"): ${sspeed}×" \
        "$(L "scroll con" "scroll with"): $smeth_t" \
        "$(L "arrastrar con" "drag with"): $d3_t" \
        "$(L "cambiar de escritorio deslizando" "swipe between workspaces"): $swipe_t" \
        "$(L "deslizar al revés" "inverted swipe"): $(onoff "$inv")" \
        "$(L "zoom con 4 dedos (arriba/abajo)" "4-finger zoom (up/down)"): $(onoff "$zoom")" \
        "‹ $(L volver back)") || return
    row=$i
    local yn; yn() { [ "$1" = yes ] && echo no || echo yes; }
    case "$i" in
      0)  set_conf "$discada" TRACKPAD_ENABLED "$(yn "$en")" ;;
      1)  set_conf "$discada" TRACKPAD_NATURAL "$(yn "$nat")" ;;
      2)  set_conf "$discada" TRACKPAD_TAP "$(yn "$tap")" ;;
      3)  set_conf "$discada" TRACKPAD_TAP_DRAG "$(yn "$tdrag")" ;;
      4)  set_conf "$discada" TRACKPAD_DRAG_LOCK "$(cycle "$lock" no timeout sticky)" ;;
      5)  set_conf "$discada" TRACKPAD_TAP_MAP "$(cycle "$map" lrm lmr)" ;;
      6)  set_conf "$discada" TRACKPAD_CLICK "$(cycle "$click" areas fingers)" ;;
      7)  set_conf "$discada" TRACKPAD_MIDDLE "$(yn "$mid")" ;;
      8)  set_conf "$discada" TRACKPAD_DWT "$(yn "$dwt")" ;;
      9)  set_conf "$discada" TRACKPAD_SPEED "$(cycle "$speed" 0 0.2 0.4 0.6 0.8 -0.6 -0.4 -0.2)" ;;
      10) set_conf "$discada" TRACKPAD_ACCEL "$(cycle "$accel" adaptive flat)" ;;
      11) set_conf "$discada" TRACKPAD_SCROLL_SPEED "$(cycle "$sspeed" 1.0 1.25 1.5 2.0 0.5 0.75)" ;;
      12) set_conf "$discada" TRACKPAD_SCROLL_METHOD "$(cycle "$smeth" 2fg edge)" ;;
      13) set_conf "$discada" TRACKPAD_DRAG_3FG "$(cycle "$d3" no 3 4)" ;;
      14) set_conf "$discada" TRACKPAD_SWIPE "$(cycle "$swipe" 3 4 no)" ;;
      15) set_conf "$discada" TRACKPAD_SWIPE_INVERT "$(yn "$inv")" ;;
      16) set_conf "$discada" TRACKPAD_ZOOM "$(yn "$zoom")" ;;
      *)  return ;;
    esac
    hyprctl reload >/dev/null
  done
}

# ── la luz del teclado (chispa) ──────────────────────────────────────────────
# solo si está el AULA F75 por cable
hay_teclado() {
  command -v chispa >/dev/null && grep -qsiE '^HID_ID=[0-9a-f]+:(0000258A:0000010C|00003554:0000FA0[789])' /sys/class/hidraw/*/device/uevent
}

teclado_now() {
  case "$(get_conf "$discada" KEYBOARD_LIGHT)" in
    wallpaper) L "wallpaper" "wallpaper" ;;
    music) L "música" "music" ;;
    *) L "a mano" "custom" ;;
  esac
}

# lo que chispa sostiene en vivo, sin guardar todavía (sin hablarle al teclado)
chispa_en_vivo() {
  local p
  p=$(cat "$XDG_RUNTIME_DIR/chispa-hold.pid" 2>/dev/null) && [ -s "$XDG_RUNTIME_DIR/chispa-hold" ] &&
    [ "$(cat "/proc/$p/comm" 2>/dev/null)" = chispa ]
}

teclado_menu() {
  # Custom (dany): lo que no se puede (sin wallust, sin cava) ni sale
  local i labels=() keys=() bat mesg=""
  # la batería (solo por 2.4 GHz): la última que se leyó, al instante, y se vuelve
  # a leer de fondo para la próxima (leerla tarda unos segundos por radio)
  bat=$(chispa battery --cached 2>/dev/null)
  [ -n "$bat" ] && mesg="$(L batería battery): $bat"
  setsid -f chispa battery >/dev/null 2>&1
  if command -v wallust >/dev/null; then
    labels+=("$(L "Seguir al wallpaper" "Follow the wallpaper")"); keys+=(wallpaper)
  fi
  if command -v cava >/dev/null; then
    labels+=("$(L "Visualizador de música" "Music visualizer")"); keys+=(music)
  fi
  if chispa_en_vivo; then
    labels+=("$(L "Guardar ya el color (parpadea)" "Save the color now (blinks)")"); keys+=(save)
  fi
  labels+=("$(L "Barrita junto al Esc ›" "Side light ›")"); keys+=(side)
  labels+=("$(L "Apagar las luces sin usarlo ›" "Lights off when idle ›")"); keys+=(sleep)
  labels+=("$(L "Perilla ›" "Knob ›")"); keys+=(knob)
  labels+=("$(L "Escoger un color o efecto…" "Pick a color or effect…")"); keys+=(tui)
  i=$(row=0 pick "$(L teclado keyboard)" "$mesg" "${labels[@]}" "‹ $(L volver back)") || return
  case "${keys[$i]}" in
    wallpaper) local err
       err=$(chispa wallpaper 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err" ;;
    music) setsid -f chispa music >/dev/null 2>&1 ;;
    save) setsid -f chispa save >/dev/null 2>&1 ;;
    side) lateral_menu ;;
    sleep) dormir_menu ;;
    knob) perilla_menu ;;
    tui) "$scripts/TuiApp.sh" chispa tui & exit 0 ;;
  esac
}

# la perilla: volumen y silencio, o brillo y siguiente efecto (dejarla apretada
# también la cambia, en el teclado)
perilla_menu() {
  local i modos=(volume lighting) err
  i=$(row=0 pick "$(L perilla knob)" "" \
      "$(L "Volumen (apretar = silencio)" "Volume (press = mute)")" \
      "$(L "Luz (brillo; apretar = siguiente efecto)" "Lighting (brightness; press = next effect)")" "‹ $(L volver back)") || return
  [ -n "${modos[$i]}" ] || return
  err=$(chispa knob "${modos[$i]}" 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err"
}

# cuánto espera el teclado sin usarse para apagar las luces (2.4 GHz y Bluetooth)
dormir_menu() {
  local i ahora err opciones=(never 1 1.5 2 3 4 5 10 15 20) labels=()
  ahora=$(timeout 3 chispa sleep 2>/dev/null)
  labels+=("$(L Nunca Never)")
  for m in "${opciones[@]:1}"; do labels+=("$m min"); done
  i=$(row=0 pick "$(L "apagar sin usarlo" "lights off when idle")" "${ahora:+$(L ahora now): $ahora}" \
      "${labels[@]}" "‹ $(L volver back)") || return
  [ -n "${opciones[$i]}" ] || return
  err=$(chispa sleep "${opciones[$i]}" 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err"
}

# la barrita blanca junto al Esc (Fn+Shift izquierdo)
lateral_menu() {
  local i modos=(off fill breathing static) err
  i=$(row=0 pick "$(L barrita "side light")" "" \
      "$(L Apagada Off)" "$(L "Llenar de arriba abajo" "Fill top to bottom")" \
      "$(L Respirar Breathing)" "$(L Fija Static)" "‹ $(L volver back)") || return
  [ -n "${modos[$i]}" ] || return
  err=$(chispa side "${modos[$i]}" 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err"
}

# ── fastfetch ────────────────────────────────────────────────────────────────
# Custom (dany): FETCH_STYLE en discada.conf (lo lee Fetch.sh al abrir una
# terminal): el del look, tu wallpaper, la ficha regia o pixel art
# (cacha/pixel/*.txt: los de discada y los que dibujes tú; lo dibuja cacha).
fetch_pixel="$HOME/.config/cacha/pixel"
fetch_name() {
  case "$1" in
    ""|look)   L "el del look" "the look's" ;;
    wallpaper) L "tu wallpaper" "your wallpaper" ;;
    ficha)     L "ficha regia" "regio card" ;;
    pixel:*)   echo "pixel · ${1#pixel:}" ;;
    none)      L "sin logo" "no logo" ;;
    *)         echo "$1" ;;
  esac
}
fetch_menu() {
  local cur i names=() vals=() f v row=0
  while true; do
    cur=$(get_conf "$discada" FETCH_STYLE)
    vals=(look wallpaper ficha)
    for f in "$fetch_pixel"/*.txt; do
      [ -f "$f" ] && f=${f##*/} && vals+=("pixel:${f%.txt}")
    done
    vals+=(none)
    names=()
    for i in "${!vals[@]}"; do
      v=$(fetch_name "${vals[$i]}")
      [ "${vals[$i]}" = "${cur:-look}" ] && v="$v  ✓" && row=$i
      names+=("$v")
    done
    names+=("$(L "probar en una terminal" "try it in a terminal")" "$(L "dibujar el tuyo (abre la carpeta de pixel)" "draw your own (opens the pixel folder)")" "‹ $(L volver back)")
    i=$(pick fastfetch "$(L "se pinta con los colores del look" "painted with the look's colors")" "${names[@]}") || return
    if [ -n "${vals[$i]:-}" ]; then
      set_conf "$discada" FETCH_STYLE "${vals[$i]}"
      "$scripts/Fetch.sh" refresh   # las terminales recién abiertas lo cambian ya
    else
      case $(( i - ${#vals[@]} )) in
        0) setsid $term -e bash -c "'$scripts/Fetch.sh'; read -rsn1" >/dev/null 2>&1 & ;;
        1) xdg-open "$fetch_pixel" >/dev/null 2>&1 & return ;;
        *) return ;;
      esac
    fi
  done
}

# ── la entrada ───────────────────────────────────────────────────────────────
# Custom (dany): ENTRADA en discada.conf (Entrada.sh: el telón con el saludo,
# la campanita y lo que entra en cascada al iniciar sesión)
entrada_name() {
  case "$1" in
    quiet) L "sin sonido" "silent" ;;
    no)    L "apagada" "off" ;;
    *)     L "con sonido" "with sound" ;;
  esac
}
entrada_menu() {
  local cur i v vals=(yes quiet no) names row=0
  while true; do
    cur=$(get_conf "$discada" ENTRADA); cur=${cur:-yes}
    names=()
    for i in "${!vals[@]}"; do
      v=$(entrada_name "${vals[$i]}")
      [ "${vals[$i]}" = "$cur" ] && v="$v  ✓" && row=$i
      names+=("$v")
    done
    names+=("$(L "verla ahora" "see it now")" "‹ $(L volver back)")
    i=$(pick "$(L entrada entrance)" "$(L "al iniciar sesión: el saludo, la campanita y todo entrando" "on login: the greeting, the chime and everything coming in")" "${names[@]}") || return
    case $i in
      0|1|2) set_conf "$discada" ENTRADA "${vals[$i]}" ;;
      3) pkill -x jale; setsid "$scripts/Entrada.sh" demo >/dev/null 2>&1 & return ;;
      *) return ;;
    esac
  done
}

# ── para machaca (el panel de SUPER+Shift+E) ─────────────────────────────────
# Custom (dany): machaca es solo la cara; lo que se lee y se cambia sigue aquí.
#   QuickSettings.sh estado           una línea por cosa: clave<TAB>valor[<TAB>etiqueta]
#                                     y `opcion<TAB>clave<TAB>valor<TAB>etiqueta` por cada opción
#   QuickSettings.sh hacer CLAVE [V]  cambia una cosa sin menú
#   QuickSettings.sh menu NOMBRE      abre ese submenú directo (en jale)
# Sin argumentos: el menú de siempre (por si machaca no está).
qs_estado() {
  local deco v f
  printf 'maquina\t%s\n' "$(cat /etc/hostname 2>/dev/null)"
  printf 'look\t%s\n' "$(cat "$hypr/looks/.current" 2>/dev/null)"
  deco=$("$scripts/Hypr.sh" file decorations)
  if grep -qE '^\s*screen_shader\s*=' "$deco"; then printf 'shader\tyes\n'
  elif grep -qE '^\s*(#|--)\s*screen_shader\s*=' "$deco"; then printf 'shader\tno\n'; fi
  printf 'game\t%s\n' "$([ "$("$scripts/Hypr.sh" get animations:enabled)" = 0 ] && echo yes || echo no)"
  printf 'blur\t%s\n' "$([ "$("$scripts/Hypr.sh" get decoration:blur:passes)" = 2 ] && echo normal || echo ligero)"
  printf 'opcion\tblur\tligero\t%s\nopcion\tblur\tnormal\tnormal\n' "$(L ligero light)"
  printf 'lang\t%s\n' "$DISCADA_LANG"
  printf 'opcion\tlang\tes\tespañol\nopcion\tlang\ten\tEnglish\n'
  printf 'font\t%s\n' "$(sed -nE 's/^FONT_SIZE=\s*([+-]?[0-9]+).*/\1/p' "$discada" | head -n1)"
  v=$(get_conf "$discada" FETCH_STYLE)
  printf 'fetch\t%s\t%s\n' "${v:-look}" "$(fetch_name "${v:-look}")"
  for v in look wallpaper ficha; do printf 'opcion\tfetch\t%s\t%s\n' "$v" "$(fetch_name "$v")"; done
  for f in "$fetch_pixel"/*.txt; do
    [ -f "$f" ] && f=${f##*/} && printf 'opcion\tfetch\tpixel:%s\t%s\n' "${f%.txt}" "$(fetch_name "pixel:${f%.txt}")"
  done
  printf 'opcion\tfetch\tnone\t%s\n' "$(fetch_name none)"
  v=$(get_conf "$discada" ENTRADA)
  printf 'entrada\t%s\n' "${v:-yes}"
  for v in yes quiet no; do printf 'opcion\tentrada\t%s\t%s\n' "$v" "$(entrada_name "$v")"; done
  printf 'vis\t%s\n' "$(vis_now)"
  if [ -x "$arre" ]; then
    printf 'notif\t%s\n' "$("$arre" position)"
    for v in "${POSITIONS[@]}"; do printf 'opcion\tnotif\t%s\t%s\n' "$v" "$(pos_name "$v")"; done
    printf 'dnd\t%s\n' "$([ "$("$arre" dnd 2>/dev/null)" = on ] && echo yes || echo no)"
  fi
  hay_teclado && printf 'teclado\t%s\n' "$(teclado_now)"
  "$bat" has && printf 'bateria\t%s\n' "$("$bat" status | jq -r '"\(.percentage)%"')"
  if [ -x "$HOME/.local/bin/machin" ]; then
    v=$("$HOME/.local/bin/machin" estado 2>/dev/null)
    case "$v" in
      principal\ *) v="$(L usando using) ${v#principal }" ;;
      presta\ *)    v="$(L "prestada a" "lent to") ${v#presta }" ;;
      *)            v=$(L apagado off) ;;
    esac
    printf 'machin\t%s\n' "$v"
  fi
  command -v picha >/dev/null && printf 'picha\t1\n'
  command -v trompo >/dev/null && printf 'trompo\t%s\n' "$(trompo cels 2>/dev/null | grep -vc '(')"
  return 0
}

# Las páginas de machaca (los submenús, ya sin jale). Un renglón por cosa:
#   titulo<TAB>texto                    nota<TAB>texto (va abajo del título)
#   opcion<TAB>clave<TAB>nombre<TAB>actual   + valor<TAB>clave<TAB>v<TAB>etiqueta
#   interruptor<TAB>clave<TAB>nombre<TAB>yes|no
#   elige<TAB>clave<TAB>v<TAB>etiqueta<TAB>1|0   (una lista: se queda la elegida)
#   botones<TAB>clave<TAB>nombre          + valor… (se aplica y ya; sin actual)
#   abre<TAB>accion<TAB>nombre<TAB>valor  (cierra el panel y `hacer accion`)
# Todo se aplica con `hacer clave [v]`.
VIS_NOMBRES=("braille · 12" "braille · 16" "braille · 20" "peaks · 16" "peaks · 20" "bloques · 8   ▁▃▅█" "bloques · 12  ▁▃▅█" "ascii · 10  .:-=+*#" "lápiz · 12  _.-~^")
VIS_JSON=('{"style": "braille", "bars": 12}' '{"style": "braille", "bars": 16}' '{"style": "braille", "bars": 20}' '{"style": "peaks", "bars": 16}' '{"style": "peaks", "bars": 20}' '{"style": "chars", "bars": 8, "chars": "▁▂▃▄▅▆▇█"}' '{"style": "chars", "bars": 12, "chars": "▁▂▃▄▅▆▇█"}' '{"style": "chars", "bars": 10, "chars": ".:-=+*#"}' '{"style": "chars", "bars": 12, "chars": "_.-~^"}')
qs_pagina() {
  local t=$'\t' v i
  case "$1" in
    vis)
      printf 'titulo\t%s\nnota\t%s\n' "$(L visualizador visualizer)" "$(L "se guarda en el look actual" "saved into the current look")"
      local ahora
      ahora=$(jq -c '.modules.visualizer // {} | {style: (.style // "braille"), bars: (.bars // 16), chars: (.chars // "")}' "$bar" 2>/dev/null)
      for i in "${!VIS_NOMBRES[@]}"; do
        v=$(jq -c '{style: (.style // "braille"), bars: (.bars // 16), chars: (.chars // "")}' <<<"${VIS_JSON[$i]}")
        printf 'elige\tvis\t%s\t%s\t%s\n' "$i" "${VIS_NOMBRES[$i]}" "$([ "$v" = "$ahora" ] && echo 1 || echo 0)"
      done ;;
    rec)
      local fps q audio rs rlen dnd
      fps=$(get_conf "$recconf" FPS); q=$(get_conf "$recconf" QUALITY)
      audio=$(sed -nE 's/^AUDIO="?([^"#]*)"?.*/\1/p' "$recconf" | head -n1 | sed 's/ *$//')
      rs=$(get_conf "$recconf" REPLAY_ON_STARTUP); rlen=$(get_conf "$recconf" REPLAY_SECONDS)
      dnd=$(get_conf "$recconf" RECORD_DND)
      printf 'titulo\t%s\nnota\t%s\n' "$(L grabador recorder)" "$(L "el replay toma los cambios al volver a encenderlo" "replay picks up changes when turned on again")"
      printf 'opcion\trec-fps\tfps\t%s\n' "${fps:-60}"
      for v in 30 60 120 144; do printf 'valor\trec-fps\t%s\t%s\n' "$v" "$v"; done
      printf 'opcion\trec-q\t%s\t%s\n' "$(L calidad quality)" "${q:-very_high}"
      for v in medium high very_high ultra; do printf 'valor\trec-q\t%s\t%s\n' "$v" "${v/_/ }"; done
      printf 'opcion\trec-audio\taudio\t%s\n' "$audio"
      for v in "default_output|default_input" default_output default_input ""; do printf 'valor\trec-audio\t%s\t%s\n' "$v" "$(audio_name "$v")"; done
      printf 'opcion\trec-len\t%s\t%s\n' "$(L "duración del replay" "replay length")" "${rlen:-60}"
      for v in 30 60 120 300; do printf 'valor\trec-len\t%s\t%ss\n' "$v" "$v"; done
      printf 'interruptor\trec-dnd\t%s\t%s\n' "$(L "no molestar al grabar" "do not disturb while recording")" "${dnd:-yes}"
      printf 'interruptor\trec-rs\t%s\t%s\n' "$(L "replay al iniciar sesión" "replay at login")" "${rs:-no}"
      printf 'abre\trec-carpeta\t%s\t%s\n' "$(L "carpeta de videos" "videos folder")" "$(L abrir open)" ;;
    bateria)
      local prof saver at
      prof=$("$bat" profile get)
      saver=$([ -f "$XDG_RUNTIME_DIR/discada/saver.json" ] && echo yes || echo no)
      at=$(get_conf "$discada" BATTERY_SAVER_AT)
      printf 'titulo\t%s\nnota\t%s\n' "$(L batería battery)" "$(L "ahorro: perfil de ahorro, sin blur, sombras ni shader y el video en pausa" "saver: power-saving profile, no blur, shadows or shader, video paused")"
      printf 'interruptor\tbat-saver\t%s\t%s\n' "$(L "ahorro de batería" "battery saver")" "$saver"
      printf 'opcion\tbat-perfil\t%s\t%s\n' "$(L "perfil de energía" "power profile")" "$prof"
      for v in power-saver balanced performance; do printf 'valor\tbat-perfil\t%s\t%s\n' "$v" "$(prof_name "$v")"; done
      printf 'opcion\tbat-at\t%s\t%s\n' "$(L "ahorro solo al" "saver by itself at")" "${at:-20}"
      for v in 10 15 20 30 0; do printf 'valor\tbat-at\t%s\t%s\n' "$v" "$([ "$v" = 0 ] && L nunca never || echo "$v%")"; done
      printf 'abre\tfierro\t%s\t%s\n' "$(L "límites de carga y más" "charge limits and more")" fierro ;;
    teclado)
      local b modo
      printf 'titulo\t%s\n' "$(L teclado keyboard)"
      b=$(chispa battery --cached 2>/dev/null); setsid -f chispa battery >/dev/null 2>&1
      [ -n "$b" ] && printf 'nota\t%s: %s\n' "$(L batería battery)" "$b"
      modo=$(get_conf "$discada" KEYBOARD_LIGHT)
      command -v wallust >/dev/null && printf 'elige\tteclado-modo\twallpaper\t%s\t%s\n' "$(L "seguir al wallpaper" "follow the wallpaper")" "$([ "$modo" = wallpaper ] && echo 1 || echo 0)"
      command -v cava >/dev/null && printf 'elige\tteclado-modo\tmusic\t%s\t%s\n' "$(L "visualizador de música" "music visualizer")" "$([ "$modo" = music ] && echo 1 || echo 0)"
      chispa_en_vivo && printf 'boton\tteclado-modo\tsave\t%s\n' "$(L "guardar ya el color (parpadea)" "save the color now (blinks)")"
      printf 'botones\tteclado-lado\t%s\n' "$(L "barrita junto al Esc" "side light")"
      printf 'valor\tteclado-lado\toff\t%s\nvalor\tteclado-lado\tfill\t%s\nvalor\tteclado-lado\tbreathing\t%s\nvalor\tteclado-lado\tstatic\t%s\n' "$(L apagada off)" "$(L llenar fill)" "$(L respirar breathing)" "$(L fija static)"
      printf 'botones\tteclado-dormir\t%s\n' "$(L "apagar sin usarlo" "lights off when idle")"
      printf 'valor\tteclado-dormir\tnever\t%s\n' "$(L nunca never)"
      for v in 1 2 5 10 20; do printf 'valor\tteclado-dormir\t%s\t%s min\n' "$v" "$v"; done
      printf 'botones\tteclado-perilla\t%s\n' "$(L perilla knob)"
      printf 'valor\tteclado-perilla\tvolume\t%s\nvalor\tteclado-perilla\tlighting\t%s\n' "$(L volumen volume)" "$(L luz lighting)"
      printf 'abre\tteclado-tui\t%s\t%s\n' "$(L "escoger un color o efecto" "pick a color or effect")" chispa ;;
    edit)
      local f="$scripts/Hypr.sh file" lk
      lk=$(cat "$hypr/looks/.current" 2>/dev/null)
      printf 'titulo\t%s\nnota\t%s\n' "$(L "editar config" "edit config")" "$(L "se abre en $edit" "opens in $edit")"
      ed() { printf 'abre\teditar:%s\t%s\t%s\n' "$2" "$1" "${2##*/}"; }
      ed "discada" "$discada"
      ed "look: $lk" "$hypr/looks/$lk/look.toml"
      ed "$(L grabador recorder)" "$recconf"
      ed "$(L "apps por defecto" "default apps")" "$($f defaults)"
      ed "$(L atajos keybinds)" "$($f keybinds)"
      ed "$(L arranque startup)" "$($f startup)"
      ed "$(L "ajustes generales" "general settings")" "$($f settings)"
      ed "$(L "decoraciones (del look)" "decorations (look)")" "$($f decorations)"
      ed "$(L "animaciones (del look)" "animations (look)")" "$($f animations)"
      ed "$(L "reglas de ventanas" "window rules")" "$($f windowrules)"
      ed "$(L "apps fijadas" "pinned apps")" "$hypr/conf/pinned.conf"
      ed "$(L "variables de entorno" "environment")" "$($f env)"
      ed "idle (hypridle)" "$hypr/hypridle.conf"
      ed "lock (hyprlock)" "$hypr/hyprlock.conf" ;;
    tools)
      printf 'titulo\t%s\n' "$(L "audio, red y sistema" "audio, network and system")"
      printf 'abre\tvato:audio\taudio\tvato\nabre\tvato:bluetooth\tbluetooth\tvato\n'
      printf 'abre\tvato:network\t%s\tvato\nabre\tvato:system\t%s\tvato\n' "$(L red network)" "$(L sistema system)"
      printf 'abre\tvato:notifications\t%s\tvato\n' "$(L notificaciones notifications)"
      printf 'abre\tmonitores\t%s\tnwg-displays\n' "$(L monitores monitors)"
      printf 'abre\tbuscar-atajos\t%s\t\n' "$(L "buscar atajos" "search shortcuts")" ;;
    *) return 2 ;;
  esac
}

qs_hacer() {
  case "$1" in
    vis)          [ -n "${VIS_JSON[$2]:-}" ] && "$HOME/.local/bin/lena" bar-set visualizer "${VIS_JSON[$2]}" ;;
    rec-fps)      set_conf "$recconf" FPS "$2" ;;
    rec-q)        set_conf "$recconf" QUALITY "$2" ;;
    rec-audio)    set_conf "$recconf" AUDIO "\"$2\"" ;;
    rec-len)      set_conf "$recconf" REPLAY_SECONDS "$2" ;;
    rec-dnd)      local d; d=$(get_conf "$recconf" RECORD_DND); set_conf "$recconf" RECORD_DND "$(cycle "${d:-yes}" yes no)" ;;
    rec-rs)       local r; r=$(get_conf "$recconf" REPLAY_ON_STARTUP); set_conf "$recconf" REPLAY_ON_STARTUP "$(cycle "${r:-no}" yes no)" ;;
    rec-carpeta)  . "$recconf" 2>/dev/null; exec xdg-open "${DIR:-$HOME/Videos}" ;;
    bat-saver)    "$bat" saver ;;
    bat-perfil)   local n; for n in 1 2 3; do [ "$("$bat" profile get)" = "$2" ] && break; "$bat" profile >/dev/null; done ;;
    bat-at)       set_conf "$discada" BATTERY_SAVER_AT "$2" ;;
    fierro)       exec "$scripts/TuiApp.sh" fierro ;;
    teclado-modo) case "$2" in
                    wallpaper) local err; err=$(chispa wallpaper 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err" ;;
                    music) setsid -f chispa music >/dev/null 2>&1 ;;
                    save) setsid -f chispa save >/dev/null 2>&1 ;;
                  esac ;;
    teclado-lado|teclado-dormir|teclado-perilla)
                  local sub=${1#teclado-} err; sub=${sub/lado/side}; sub=${sub/dormir/sleep}; sub=${sub/perilla/knob}
                  err=$(chispa "$sub" "$2" 2>&1 >/dev/null) || notify-send -i "dialog-error-symbolic" "chispa" "$err" ;;
    teclado-tui)  exec "$scripts/TuiApp.sh" chispa tui ;;
    editar:*)     exec $term -e $edit "${1#editar:}" ;;
    vato:*)       exec "$scripts/Vato.sh" "${1#vato:}" ;;
    monitores)    need nwg-displays && exec nwg-displays ;;
    buscar-atajos) exec "$scripts/KeyBinds.sh" ;;
    lang)    [ "$2" != "$DISCADA_LANG" ] && set_language "$2" ;;
    font)    "$scripts/FontSize.py" set "$2" ;;
    blur)    [ "$2" != "$([ "$("$scripts/Hypr.sh" get decoration:blur:passes)" = 2 ] && echo normal || echo ligero)" ] && "$scripts/ChangeBlur.sh" ;;
    shader)  "$scripts/LookSwitch.sh" shader ;;
    game)    "$scripts/GameMode.sh" ;;
    fetch)   set_conf "$discada" FETCH_STYLE "$2"; "$scripts/Fetch.sh" refresh ;;
    entrada) set_conf "$discada" ENTRADA "$2" ;;
    notif)   "$arre" position "$2" && notif_sample ;;
    dnd)     "$arre" dnd toggle >/dev/null ;;
    semana)  exec "$scripts/Semana.sh" ver ;;
    atajos)  exec "$scripts/KeyHints.sh" ;;
    update)  exec $term --class discada-update -e bash -c "'$scripts/Update.sh'; echo; read -rp '$(L "Enter para cerrar" "Press Enter to close")'" ;;
    picha)   exec "$scripts/TuiApp.sh" picha ;;
    trompo)  exec $term --class discada-trompo -e trompo ;;
    machin)  exec "$HOME/.local/bin/machin" menu ;;
    wallpaper) exec "$scripts/WallpaperSelect.sh" ;;
    entrada-demo) exec "$scripts/Entrada.sh" demo ;;
    *) echo "no sé hacer '$1'" >&2; return 2 ;;
  esac
}

case "$1" in
  estado) qs_estado; exit ;;
  pagina) qs_pagina "$2"; exit ;;
  hacer)  shift; qs_hacer "$@"; exit ;;
  menu)
    pidof jale >/dev/null && pkill -x jale
    case "$2" in
      vis) vis_menu ;; rec) rec_menu ;; notif) notif_menu ;; bateria) bat_menu ;;
      teclado) teclado_menu ;; edit) edit_menu ;; tools) tools_menu ;;
      fetch) fetch_menu ;; entrada) entrada_menu ;;
      *) echo "no hay menú '$2'" >&2; exit 2 ;;
    esac
    exit 0 ;;
esac

# ── menú principal ───────────────────────────────────────────────────────────
# Custom (dany): con machaca instalado, el panel; si no está o falla, el menú
# de jale de siempre (`QuickSettings.sh lista` lo abre directo)
if [ "$1" != lista ] && [ -x "$HOME/.local/bin/machaca" ]; then
  "$HOME/.local/bin/machaca" && exit 0
fi
pidof jale >/dev/null && pkill -x jale

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
  add "$I_FETCH  fastfetch: $(fetch_name "$(get_conf "$discada" FETCH_STYLE)") ›" fetch
  add "$I_ENTRADA  $(L entrada entrance): $(entrada_name "$(get_conf "$discada" ENTRADA)") ›" entrada
  add "$I_SEMANA  $(L "tu semana" "your week")"                       semana
  add "$I_VIS  $(L visualizador visualizer): $(vis_now)"           vis
  add "$I_REC  $(L grabador recorder) ›"                           rec
  # Custom (dany): machín, la otra compu como monitor extra (su menú: sonido, lado, calidad)
  if [ -x "$HOME/.local/bin/machin" ]; then
    m=$("$HOME/.local/bin/machin" estado 2>/dev/null)
    case "$m" in
      principal\ *) m="$(L usando using) ${m#principal }" ;;
      presta\ *)    m="$(L "prestada a" "lent to") ${m#presta }" ;;
      *)            m=$(L apagado off) ;;
    esac
    add "$I_MACHIN  machín: $m ›"                                   machin
  fi
  [ -x "$arre" ] && add "$I_NOTIF  $(L notificaciones notifications): $(pos_name "$("$arre" position)") ›" notif
  hay_teclado && add "$I_TECLADO  $(L teclado keyboard): $(teclado_now) ›" teclado
  hay_trackpad && add "$I_TRACKPAD  trackpad ›"                         trackpad
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
    fetch)  fetch_menu ;;
    entrada) entrada_menu ;;
    semana) exec "$scripts/Semana.sh" ver ;;
    lang)   set_language "$([ "$DISCADA_LANG" = es ] && echo en || echo es)" ;;
    vis)    vis_menu ;;
    rec)    rec_menu ;;
    machin) exec "$HOME/.local/bin/machin" menu ;;
    notif)  notif_menu ;;
    teclado) teclado_menu ;;
    trackpad) trackpad_menu ;;
    battery) bat_menu ;;
    game)   "$scripts/GameMode.sh"; sleep 0.3 ;;
    blur)   "$scripts/ChangeBlur.sh" ;;
    edit)   edit_menu; exit 0 ;;
    tools)  tools_menu; exit 0 ;;
    keys)   exec "$scripts/KeyHints.sh" ;;
    update) exec $term --class discada-update -e bash -c "'$scripts/Update.sh'; echo; read -rp '$(L "Enter para cerrar" "Press Enter to close")'" ;;
  esac
done
