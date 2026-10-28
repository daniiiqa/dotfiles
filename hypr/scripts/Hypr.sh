#!/usr/bin/env bash
# Hablarle a Hyprland igual con la config vieja (.conf) que con la nueva (Lua).
# Con Lua ya no existen `hyprctl keyword` ni `hyprctl dispatch workspace 2`:
# todo es `hyprctl eval` / `hyprctl dispatch 'hl.dsp…'`. Los scripts, la barra
# y wlogout pasan por aquí y no se enteran de cuál está activa.
#
#   Hypr.sh mode                       lua | conf
#   Hypr.sh set KEY VALUE [KEY VALUE…] opciones (decoration:blur:size 4)
#   Hypr.sh get KEY                    valor de una opción (sí/no como 1/0)
#   Hypr.sh workspace W                ir al workspace (2, e+1, special…)
#   Hypr.sh focus SEL                  enfocar una ventana (address:0x…, class:^x$)
#   Hypr.sh movetows W SEL [silent]    mandar una ventana a un workspace
#   Hypr.sh moveto X Y SEL             posición exacta
#   Hypr.sh resizeto W H SEL           tamaño exacto
#   Hypr.sh pin SEL                    fijar / soltar
#   Hypr.sh float|tile SEL             flotar / al tile
#   Hypr.sh close SEL                  cerrar una ventana
#   Hypr.sh opaque-all                 todas las ventanas opacas (game mode)
#   Hypr.sh exec 'REGLAS' CMD         lanzar con reglas ('float; size 800 400; workspace special:x silent')
#   Hypr.sh dpms on|off                prender / apagar las pantallas
#   Hypr.sh exit                       salir de Hyprland
#   Hypr.sh lua CODE                   Lua tal cual (solo en modo Lua)
#   Hypr.sh file NOMBRE                conf/NOMBRE.lua o .conf, el formato que se usa
#   Hypr.sh defaults                   apps por defecto como term="kitty" (para eval)

mode() {
  case "$(hyprctl eval 'return 1' 2>&1)" in
    *"only supported with the lua"*) echo conf ;;
    *) echo lua ;;
  esac
}

# "texto" con comillas y \ escapados, para meterlo en código Lua
q() { local s=${1//\\/\\\\}; printf '"%s"' "${s//\"/\\\"}"; }

# valor de un set → literal de Lua (número, true/false o texto)
lit() {
  case "$1" in
    "[[EMPTY]]") echo '""' ;;   # sin valor (screen_shader): en Lua es ""
    true|yes|on) echo true ;;
    false|no|off) echo false ;;
    *) if [[ $1 =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then echo "$1"; else q "$1"; fi ;;
  esac
}

# decoration:blur:size 4 → { decoration = { blur = { size = 4 } } }
lua_table() {
  local key=$1 val=$2 out
  IFS=: read -ra parts <<<"$key"
  out="${parts[-1]//-/_} = $val"
  for ((i = ${#parts[@]} - 2; i >= 0; i--)); do out="${parts[i]//-/_} = { $out }"; done
  echo "{ $out }"
}

# workspace "2" → 2; "e+1" → "e+1"
ws() { if [[ $1 =~ ^-?[0-9]+$ ]]; then echo "$1"; else q "$1"; fi; }

dsp() { hyprctl dispatch "$1" >/dev/null; }

hypr="$HOME/.config/hypr"

# lo que se lee de archivos va por el formato que carga Hyprland al iniciar
# (hyprland.lua si existe), no hace falta preguntarle
case "$1" in
  file)
    if [ -f "$hypr/hyprland.lua" ]; then echo "$hypr/conf/$2.lua"; else echo "$hypr/conf/$2.conf"; fi
    exit ;;
  defaults)
    # term, edit, files, search_engine
    if [ -f "$hypr/hyprland.lua" ]; then
      sed -nE 's/^\s*(term|edit|files|search_engine)\s*=\s*"(.*)",.*$/\1="\2"/p' "$hypr/conf/defaults.lua"
    else
      sed -nE 's/^\$(term|edit|files|Search_Engine)\s*=\s*"?([^"#]*[^"# ])"?.*$/\1="\2"/p' "$hypr/conf/defaults.conf" |
        sed 's/^Search_Engine=/search_engine=/'
    fi
    exit ;;
esac

# HYPR_MODE=lua|conf se lo ahorra (scripts que llaman muchas veces seguidas)
M=${HYPR_MODE:-$(mode)}
cmd=$1
shift

case "$cmd" in
  mode) echo "$M" ;;
  set)
    if [ "$M" = lua ]; then
      code=""
      while (($# >= 2)); do code+="hl.config($(lua_table "$1" "$(lit "$2")")); "; shift 2; done
      hyprctl eval "$code" >/dev/null
    else
      batch=""
      while (($# >= 2)); do batch+="keyword $1 $2; "; shift 2; done
      hyprctl --batch "$batch" >/dev/null
    fi ;;
  get)
    hyprctl -j getoption "$1" | jq -r '
      if has("bool") then (if .bool then 1 else 0 end)
      else (.int // .float // .str // .custom // .css // "") end' ;;
  workspace)
    if [ "$M" = lua ]; then dsp "hl.dsp.focus({ workspace = $(ws "$1") })"
    else dsp "workspace $1"; fi ;;
  focus)
    if [ "$M" = lua ]; then dsp "hl.dsp.focus({ window = $(q "$1") })"
    else dsp "focuswindow $1"; fi ;;
  movetows)
    if [ "$M" = lua ]; then
      follow=true; [ "$3" = silent ] && follow=false
      dsp "hl.dsp.window.move({ workspace = $(ws "$1"), follow = $follow, window = $(q "$2") })"
    else
      dsp "movetoworkspace$([ "$3" = silent ] && echo silent) $1,$2"
    fi ;;
  moveto)
    if [ "$M" = lua ]; then dsp "hl.dsp.window.move({ x = $1, y = $2, window = $(q "$3") })"
    else dsp "movewindowpixel exact $1 $2,$3"; fi ;;
  resizeto)
    if [ "$M" = lua ]; then
      # con Lua el resize recentra la ventana; con .conf se queda donde estaba
      at=""
      [[ $3 == address:* ]] && at=$(hyprctl -j clients | jq -r --arg a "${3#address:}" '.[] | select(.address == $a) | "\(.at[0]) \(.at[1])"')
      dsp "hl.dsp.window.resize({ x = $1, y = $2, window = $(q "$3") })"
      [ -n "$at" ] && dsp "hl.dsp.window.move({ x = ${at% *}, y = ${at#* }, window = $(q "$3") })"
    else dsp "resizewindowpixel exact $1 $2,$3"; fi ;;
  pin)
    if [ "$M" = lua ]; then dsp "hl.dsp.window.pin({ window = $(q "$1") })"
    else dsp "pin $1"; fi ;;
  float|tile)
    if [ "$M" = lua ]; then
      a=enable; [ "$cmd" = tile ] && a=disable
      dsp "hl.dsp.window.float({ action = \"$a\", window = $(q "$1") })"
    else dsp "$([ "$cmd" = tile ] && echo settiled || echo setfloating) $1"; fi ;;
  close)
    if [ "$M" = lua ]; then dsp "hl.dsp.window.close({ window = $(q "$1") })"
    else dsp "closewindow $1"; fi ;;
  opaque-all)
    if [ "$M" = lua ]; then hyprctl eval 'hl.window_rule({ match = { class = ".*" }, opacity = "1 override" })' >/dev/null
    else hyprctl keyword windowrule "match:class .*, opacity 1 override" >/dev/null; fi ;;
  exec)
    if [ "$M" = lua ]; then
      rules=""
      IFS=';' read -ra rs <<<"$1"
      for r in "${rs[@]}"; do
        r=$(echo "$r" | xargs)
        case "$r" in
          float) rules+="float = true, " ;;
          size\ *) rules+="size = $(q "${r#size }"), " ;;
          workspace\ *) rules+="workspace = $(q "${r#workspace }"), " ;;
          ?*) rules+="${r%% *} = $(q "${r#* }"), " ;;
        esac
      done
      dsp "hl.dsp.exec_cmd($(q "$2"), { ${rules%, } })"
    else dsp "exec [$1] $2"; fi ;;
  dpms)
    if [ "$M" = lua ]; then dsp "hl.dsp.dpms($(q "$1"))"
    else dsp "dpms $1"; fi ;;
  exit)
    if [ "$M" = lua ]; then dsp "hl.dsp.exit()"
    else dsp "exit 0"; fi ;;
  lua)
    [ "$M" = lua ] && hyprctl eval "$1" ;;
  *)
    sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
    exit 2 ;;
esac
