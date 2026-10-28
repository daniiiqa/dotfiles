#!/usr/bin/env bash
# Buscador de atajos (SUPER+Shift+K): los atajos que tienen descripción, con
# ella. Solo consulta — Enter no ejecuta nada.

pkill yad 2>/dev/null
pidof rofi >/dev/null && pkill rofi

# Le pregunta a Hyprland (sirve igual con la config .conf que con la de Lua)
hyprctl -j binds | jq -r '
  def mods: [ (if . % 128 >= 64 then "SUPER" else empty end),
              (if . % 8 >= 4 then "CTRL" else empty end),
              (if . % 16 >= 8 then "ALT" else empty end),
              (if . % 2 >= 1 then "SHIFT" else empty end) ] | join(" ");
  .[] | select(.has_description)
  | (if .key == "" and .keycode >= 10 and .keycode <= 19 then ((.keycode - 9) % 10 | tostring)   # code:10..19 → 1..0
     elif .key == "" then "code:\(.keycode)" else .key end) as $key
  | (.modmask | mods) as $m
  | "\(if $m == "" then $key else "\($m) + \($key)" end)|\(.description)"' |
  awk -F'|' '{ printf "%-32s %s\n", $1, $2 }' |
  rofi -dmenu -i -config "$HOME/.config/rofi/config-keybinds.rasi" -p keys -mesg "read-only — edit in hypr/conf/keybinds"
