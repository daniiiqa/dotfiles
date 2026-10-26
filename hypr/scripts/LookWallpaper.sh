#!/usr/bin/env bash
# Wallpaper de los looks de paleta fija (los que no sacan colores del
# wallpaper: hypr/wallpapers/<look>.jpg). Lo llama LookSwitch.sh.
#
#   LookWallpaper.sh <look>
#
# Al entrar a un look con wallpaper propio se guarda lo que tenías (imagen de
# cada monitor y los videos de livewallpaper.conf) y se pone el del look en
# todos los monitores. Entre looks fijos solo se cambia. Al volver a un look
# que sigue al wallpaper se restaura lo guardado. Si eliges otro wallpaper
# estando en un look fijo (WallpaperSelect/Random), esa elección es la que se
# queda: los selectores borran lo guardado.
#
# Sale con 10 si regeneró los colores (WallustSwww.sh), para que LookSwitch
# no lo repita.

cfg="$HOME/.config"
scripts="$cfg/hypr/scripts"
walls="$cfg/hypr/wallpapers"
saved="${XDG_STATE_HOME:-$HOME/.local/state}/discada/wallpaper"
live="$cfg/hypr/conf/livewallpaper.conf"
target="$1"
params=(--transition-type fade --transition-duration 1 --transition-fps 60)

img=$(find "$walls" -maxdepth 1 -name "$target.*" -print -quit 2>/dev/null)

if [ -n "$img" ]; then
  # 1) guardar lo tuyo (solo al salir de un look que sigue al wallpaper)
  if [ ! -d "$saved" ]; then
    mkdir -p "$saved"
    swww query > "$saved/swww" 2>/dev/null
    [ -f "$live" ] && cp "$live" "$saved/livewallpaper.conf"
    readlink -f "$cfg/rofi/.current_wallpaper" > "$saved/current" 2>/dev/null
  fi
  # 2) sin videos: el wallpaper del look en todos los monitores
  pkill -x mpvpaper 2>/dev/null
  [ -f "$live" ] && grep '^#' "$live" > "$live.tmp" && mv "$live.tmp" "$live"
  pgrep -x swww-daemon >/dev/null || { swww-daemon --format xrgb & sleep 1; }
  swww img "$img" "${params[@]}"
  "$scripts/WallustSwww.sh" "$img" >/dev/null 2>&1
  exit 10
fi

# look que sigue al wallpaper: devolver lo guardado, si hay
[ -d "$saved" ] || exit 0
while IFS=$'\t' read -r mon path; do
  [ -n "$mon" ] && [ -f "$path" ] && swww img -o "$mon" "$path" "${params[@]}"
done < <(sed -nE 's/^: ([^:]+): .*image: (.*)$/\1\t\2/p' "$saved/swww")
if [ -f "$saved/livewallpaper.conf" ]; then
  cp "$saved/livewallpaper.conf" "$live"
  # relanzar los videos tal como los arranca Hyprland al iniciar sesión
  sed -nE 's/^exec-once *= *//p' "$live" | while IFS= read -r cmd; do
    setsid bash -c "$cmd" >/dev/null 2>&1 &
  done
fi
current=$(cat "$saved/current" 2>/dev/null)
rm -rf "$saved"
if [ -f "$current" ]; then
  "$scripts/WallustSwww.sh" "$current" >/dev/null 2>&1
  exit 10
fi
exit 0
