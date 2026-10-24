#!/usr/bin/env bash
# Buscador de atajos (SUPER+Shift+K): lista los `bindd` de conf/keybinds.conf
# con su descripción. Solo consulta — Enter no ejecuta nada.

pkill yad 2>/dev/null
pidof rofi >/dev/null && pkill rofi

conf="$HOME/.config/hypr/conf/keybinds.conf"

awk -F',' '
  /^[[:space:]]*bind[a-z]*d[a-z]*[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/, "", $1)
    mods = $1; key = $2; desc = $3
    gsub(/\$mainMod/, "SUPER", mods)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", mods)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", desc)
    if (key ~ /^code:1[0-9]$/) key = (substr(key, 6) - 9) % 10   # code:10..19 → teclas 1..0
    combo = (mods == "" ? key : mods " + " key)
    printf "%-32s %s\n", combo, desc
  }' "$conf" |
  rofi -dmenu -i -config "$HOME/.config/rofi/config-keybinds.rasi" -p keys -mesg "read-only — edit in hypr/conf/keybinds.conf"
