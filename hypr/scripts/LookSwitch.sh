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
. "$cfg/hypr/scripts/lang.sh"

# screen_shader del look actual (outsider trae grano). Se apaga comentando la
# línea en el decorations.conf vivo, así sobrevive a los reload y al cambiar
# de look se guarda con él. Sin línea de shader no hay opción en el menú.
# decorations.conf (#) o decorations.lua (--), el que cargue Hyprland; el
# cambio se hace en los dos para que no se desfasen
deco=$("$cfg/hypr/scripts/Hypr.sh" file decorations)
shader_entry=""
if grep -qE '^\s*screen_shader\s*=' "$deco"; then
  shader_entry="shader: off"
elif grep -qE '^\s*(#|--)\s*screen_shader\s*=' "$deco"; then
  shader_entry="shader: on"
fi

if [ -n "$1" ]; then
  target="$1"
else
  pidof rofi >/dev/null && pkill rofi
  target=$( { [ -n "$shader_entry" ] && echo "$shader_entry"
    find "$looks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort; } |
    rofi -dmenu -i -p look -config "$cfg/rofi/config-edit.rasi" -mesg "$(L actual current): ${current:-?}")
fi

[ -z "$target" ] && exit 0
case "$target" in
  shader|"shader: off"|"shader: on")
    conf="$cfg/hypr/conf/decorations.conf" lua="$cfg/hypr/conf/decorations.lua"
    if grep -qE '^\s*screen_shader\s*=' "$deco"; then
      [ -f "$conf" ] && sed -i -E 's/^(\s*)screen_shader(\s*)=/\1# screen_shader\2=/' "$conf"
      [ -f "$lua" ] && sed -i -E 's/^(\s*)screen_shader(\s*)=/\1-- screen_shader\2=/' "$lua"
      msg=$(L "shader apagado" "shader off")
    elif grep -qE '^\s*(#|--)\s*screen_shader\s*=' "$deco"; then
      [ -f "$conf" ] && sed -i -E 's/^(\s*)#\s*screen_shader(\s*)=/\1screen_shader\2=/' "$conf"
      [ -f "$lua" ] && sed -i -E 's/^(\s*)--\s*screen_shader(\s*)=/\1screen_shader\2=/' "$lua"
      msg=$(L "shader encendido" "shader on")
    else
      msg=$(L "este look no tiene shader" "this look has no shader")
    fi
    hyprctl reload >/dev/null
    notify-send -e -u low -i "preferences-desktop-appearance-symbolic" "Look" "$msg"
    exit 0
    ;;
esac
if [ ! -d "$looks/$target" ]; then
  notify-send -i "dialog-error-symbolic" "Look" "$(L "No existe" "Not found"): $target"
  exit 1
fi
[ "$target" = "$current" ] && exit 0

# 0) quitar el tamaño de letra de discada (FontSize.py) para guardar el look
#    con sus tamaños originales; se vuelve a aplicar después de copiar
"$cfg/hypr/scripts/FontSize.py" unapply

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
"$cfg/hypr/scripts/FontSize.py" apply --no-reload

# 2b) looks de paleta fija: su wallpaper (hypr/wallpapers/<look>.jpg); al
#     volver a uno que sigue al wallpaper, el tuyo de vuelta. 10 = ya regeneró
#     los colores de wallust
"$cfg/hypr/scripts/LookWallpaper.sh" "$target"
walls_rc=$?

# 3) si cambió la config de wallust (paleta, saturación…), regenerar colores
wallust_after=$(md5sum < "$cfg/wallust/wallust.toml" 2>/dev/null)
if [ "$walls_rc" != 10 ] && [ "$wallust_before" != "$wallust_after" ]; then
  "$cfg/hypr/scripts/WallustSwww.sh" "$(readlink -f "$cfg/rofi/.current_wallpaper")" >/dev/null 2>&1
fi

# 4) recargar todo
hyprctl reload >/dev/null
pkill -SIGUSR2 waybar
"$cfg/hypr/scripts/SDDMWallpaperSync.sh" >/dev/null 2>&1   # sddm: fuente, forma y paleta del look
"$cfg/hypr/scripts/AppColors.py" >/dev/null 2>&1          # apps GTK/Qt: colores del look
pkill -USR1 -x kitty
pkill rofi 2>/dev/null

notify-send -e -u low -i "preferences-desktop-appearance-symbolic" "Look" "$target"
