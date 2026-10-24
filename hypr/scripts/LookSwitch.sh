#!/usr/bin/env bash
# Cambia el look del rice (SUPER+T). Cada look vive en hypr/looks/<nombre>/
# como espejo de ~/.config con solo los archivos que le tocan (decoraciones,
# animaciones, hyprlock, waybar, rofi, swaync, wlogout, kitty, fastfetch y la paleta
# de wallust).
#
# Al cambiar, primero guarda los archivos vivos en el look actual — así lo
# que edites a mano no se pierde — y luego copia el nuevo encima.
# Uso: LookSwitch.sh [nombre]   (sin nombre abre un menú de rofi)

cfg="$HOME/.config"
looks="$cfg/hypr/looks"
state="$looks/.current"
current=$(cat "$state" 2>/dev/null)

if [ -n "$1" ]; then
  target="$1"
else
  pidof rofi >/dev/null && pkill rofi
  target=$(find "$looks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort |
    rofi -dmenu -i -p look -config "$cfg/rofi/config-edit.rasi" -mesg "current: ${current:-?}")
fi

[ -z "$target" ] && exit 0
if [ ! -d "$looks/$target" ]; then
  notify-send -i "$cfg/swaync/images/error.png" "Look" "No existe: $target"
  exit 1
fi
[ "$target" = "$current" ] && exit 0

# 1) guardar lo vivo en el look actual
if [ -n "$current" ] && [ -d "$looks/$current" ]; then
  (cd "$looks/$current" && find . -type f -printf '%P\n') | while read -r f; do
    [ -f "$cfg/$f" ] && cp "$cfg/$f" "$looks/$current/$f"
  done
fi

# 2) aplicar el nuevo
wallust_before=$(md5sum < "$cfg/wallust/wallust.toml" 2>/dev/null)
(cd "$looks/$target" && find . -type f -printf '%P\n') | while read -r f; do
  mkdir -p "$(dirname "$cfg/$f")"
  cp "$looks/$target/$f" "$cfg/$f"
done
echo "$target" > "$state"

# 3) si cambió la config de wallust (paleta, saturación…), regenerar colores
wallust_after=$(md5sum < "$cfg/wallust/wallust.toml" 2>/dev/null)
if [ "$wallust_before" != "$wallust_after" ]; then
  "$cfg/hypr/scripts/WallustSwww.sh" "$(readlink -f "$cfg/rofi/.current_wallpaper")" >/dev/null 2>&1
fi

# 4) recargar todo
hyprctl reload >/dev/null
pkill -SIGUSR2 waybar
swaync-client -rs >/dev/null 2>&1
pkill -USR1 -x kitty
pkill rofi 2>/dev/null

notify-send -e -u low -i "$cfg/swaync/images/bell.png" "Look" "$target"
