#!/usr/bin/env bash
# Hablarle a Hyprland (config en Lua desde 0.57). Ya no existen `hyprctl
# keyword` ni `hyprctl dispatch workspace 2`: todo es `hyprctl eval` /
# `hyprctl dispatch 'hl.dsp…'`. Los scripts, la barra, jale, rollo y wlogout
# pasan por aquí para no repetir cómo se escribe cada cosa.
#
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
#   Hypr.sh lua CODE                   Lua tal cual
#   Hypr.sh file NOMBRE                conf/NOMBRE.lua
#   Hypr.sh defaults                   apps por defecto como term="kitty" (para eval)

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

cmd=$1
shift

case "$cmd" in
  file) echo "$hypr/conf/$1.lua" ;;
  defaults)
    # term, edit, files, search_engine
    sed -nE 's/^\s*(term|edit|files|search_engine)\s*=\s*"(.*)",.*$/\1="\2"/p' "$hypr/conf/defaults.lua" ;;
  set)
    code=""
    while (($# >= 2)); do code+="hl.config($(lua_table "$1" "$(lit "$2")")); "; shift 2; done
    hyprctl eval "$code" >/dev/null ;;
  get)
    hyprctl -j getoption "$1" | jq -r '
      if has("bool") then (if .bool then 1 else 0 end)
      else (.int // .float // .str // .custom // .css // "") end' ;;
  workspace)
    dsp "hl.dsp.focus({ workspace = $(ws "$1") })" ;;
  focus)
    dsp "hl.dsp.focus({ window = $(q "$1") })" ;;
  movetows)
    follow=true; [ "$3" = silent ] && follow=false
    dsp "hl.dsp.window.move({ workspace = $(ws "$1"), follow = $follow, window = $(q "$2") })" ;;
  moveto)
    dsp "hl.dsp.window.move({ x = $1, y = $2, window = $(q "$3") })" ;;
  resizeto)
    # el resize recentra la ventana: se vuelve a poner donde estaba
    at=""
    [[ $3 == address:* ]] && at=$(hyprctl -j clients | jq -r --arg a "${3#address:}" '.[] | select(.address == $a) | "\(.at[0]) \(.at[1])"')
    dsp "hl.dsp.window.resize({ x = $1, y = $2, window = $(q "$3") })"
    [ -n "$at" ] && dsp "hl.dsp.window.move({ x = ${at% *}, y = ${at#* }, window = $(q "$3") })" ;;
  pin)
    dsp "hl.dsp.window.pin({ window = $(q "$1") })" ;;
  float|tile)
    a=enable; [ "$cmd" = tile ] && a=disable
    dsp "hl.dsp.window.float({ action = \"$a\", window = $(q "$1") })" ;;
  close)
    dsp "hl.dsp.window.close({ window = $(q "$1") })" ;;
  opaque-all)
    hyprctl eval 'hl.window_rule({ match = { class = ".*" }, opacity = "1 override" })' >/dev/null ;;
  exec)
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
    dsp "hl.dsp.exec_cmd($(q "$2"), { ${rules%, } })" ;;
  dpms)
    dsp "hl.dsp.dpms($(q "$1"))" ;;
  exit)
    dsp "hl.dsp.exit()" ;;
  lua)
    hyprctl eval "$1" ;;
  *)
    sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
    exit 2 ;;
esac
