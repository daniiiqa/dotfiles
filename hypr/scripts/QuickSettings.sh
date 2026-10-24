#!/usr/bin/env bash
# Menú rápido de ajustes (SUPER+Shift+E): editar la config y abrir las
# herramientas del sistema.

hypr="$HOME/.config/hypr"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
iDIR="$HOME/.config/swaync/images"

# $term y $edit salen de conf/defaults.conf
eval "$(sed -nE 's/^\$(term|edit)\s*=\s*(.*)$/\1="\2"/p' "$hypr/conf/defaults.conf")"
term=${term:-kitty}
edit=${EDITOR:-${edit:-nano}}

need() {
  command -v "$1" &>/dev/null && return 0
  notify-send -i "$iDIR/error.png" "Falta $1" "Instálalo primero"
  return 1
}

menu() {
  cat <<MENU
--- EDITAR ---
Apps por defecto
Atajos
Arranque
Ajustes generales
Look (decoraciones)
Animaciones
Reglas de ventanas
Variables de entorno
Idle (hypridle)
Lock (hyprlock)
--- HERRAMIENTAS ---
Cambiar look
Monitores (nwg-displays)
GTK (nwg-look)
Qt6 (qt6ct)
Qt5 (qt5ct)
Kvantum
Buscar atajos
Game mode
MENU
}

pidof rofi >/dev/null && pkill rofi

choice=$(menu | rofi -i -dmenu -p settings -config "$rofi_theme")

case "$choice" in
  "Apps por defecto")      file="$hypr/conf/defaults.conf" ;;
  "Atajos")                file="$hypr/conf/keybinds.conf" ;;
  "Arranque")              file="$hypr/conf/startup.conf" ;;
  "Ajustes generales")     file="$hypr/conf/settings.conf" ;;
  "Look (decoraciones)")   file="$hypr/conf/decorations.conf" ;;
  "Animaciones")           file="$hypr/conf/animations.conf" ;;
  "Reglas de ventanas")    file="$hypr/conf/windowrules.conf" ;;
  "Variables de entorno")  file="$hypr/conf/env.conf" ;;
  "Idle (hypridle)")       file="$hypr/hypridle.conf" ;;
  "Lock (hyprlock)")       file="$hypr/hyprlock.conf" ;;
  "Monitores (nwg-displays)") need nwg-displays && nwg-displays ;;
  "GTK (nwg-look)")        need nwg-look && nwg-look ;;
  "Qt6 (qt6ct)")           need qt6ct && qt6ct ;;
  "Qt5 (qt5ct)")           need qt5ct && qt5ct ;;
  "Kvantum")               need kvantummanager && kvantummanager ;;
  "Cambiar look")          "$hypr/scripts/LookSwitch.sh" ;;
  "Buscar atajos")         "$hypr/scripts/KeyBinds.sh" ;;
  "Game mode")             "$hypr/scripts/GameMode.sh" ;;
esac

[ -n "$file" ] && $term -e $edit "$file"
