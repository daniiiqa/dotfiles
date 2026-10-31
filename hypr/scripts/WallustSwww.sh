#!/usr/bin/env bash
# Wallust: derive colors from the current wallpaper and update templates
# Usage: WallustSwww.sh [absolute_path_to_wallpaper]

set -euo pipefail

# Inputs and paths
passed_path="${1:-}"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
# Custom (dany): swww ahora es awww y su caché ya no es una ruta por monitor:
# se pregunta al daemon (": DP-1: 1920x1080, ... image: /ruta")
read_wallpaper_from_query() {
  local monitor="$1"
  awww query 2>/dev/null | sed -nE "s/^: $monitor: .*image: (.*)\$/\1/p" | head -n1
}

# Helper: get focused monitor name (prefer JSON)
get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

# Determine wallpaper_path
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  current_monitor="$(get_focused_monitor)"
  # recién cambiado, el daemon tarda un poco en reportar la imagen nueva
  for _ in {1..10}; do
    wallpaper_path="$(read_wallpaper_from_query "$current_monitor")"
    [[ -n "$wallpaper_path" ]] && break
    sleep 0.1
  done
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  exit 0
fi

# Update helpers that depend on the path
ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

wait_for_templates() {
  local start_ts="$1"
  shift
  local files=("$@")
  for _ in {1..50}; do
    local ready=true
    for file in "${files[@]}"; do
      if [[ ! -s "$file" ]]; then
        ready=false
        break
      fi
      local mtime
      mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
      if (( mtime < start_ts )); then
        ready=false
        break
      fi
    done
    $ready && return 0
    sleep 0.1
  done
  return 1
}

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
start_ts=$(date +%s)
wallust run -s "$wallpaper_path" || true
# Custom (dany): sube los colores que quedaron ilegibles contra el fondo y
# re-renderiza los templates (ver ContrastFix.py)
"$HOME/.config/hypr/scripts/ContrastFix.py" || true
# los colores del look: en los de paleta fija su paleta gana sobre la del
# wallpaper; en todos, sus nombres propios (acc, critical…)
"$HOME/.config/hypr/scripts/LookBuild.py" colors || true
wallust_targets=(
  "$HOME/.config/wlogout/wallust/colors-wlogout.css"
  "$HOME/.config/rofi/wallust/colors-rofi.rasi"
)
wait_for_templates "$start_ts" "${wallust_targets[@]}" || true

# kitty relee su config (incluye kitty-themes/01-Wallust.conf) con SIGUSR1
pkill -USR1 -x kitty 2>/dev/null || true

# Custom (dany): aquí NO se recarga la barra. Este script genera colores;
# recargar la barra es chamba del caller (Refresh.sh). Cuando ambos lo
# hacían, cada cambio de wallpaper parpadeaba la barra DOS veces: una al
# click (esta recarga) y otra al acabar la transición (la de Refresh.sh).

# Custom (dany): fondo + colores de SDDM en sync con el wallpaper
"$HOME/.config/hypr/scripts/SDDMWallpaperSync.sh" >/dev/null 2>&1 || true
# Custom (dany): apps GTK y Qt con los colores del look (AppColors.py)
"$HOME/.config/hypr/scripts/AppColors.py" >/dev/null 2>&1 || true
