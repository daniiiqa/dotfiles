#!/usr/bin/env bash
# Custom (dany): farula (el telón) vive en ~/.local/bin, que no está en el
# PATH de Hyprland: sin esto los atajos no lo encuentran
PATH="$HOME/.local/bin:$PATH"
# Cambia el look del rice (SUPER+T). Cada look vive en hypr/looks/<nombre>/
# como espejo de ~/.config con solo los archivos que le tocan (decoraciones,
# animaciones, hyprlock, rofi, wlogout, kitty, fastfetch, sddm), más su
# look.toml: colores, fuente y estilo (leña los aplica).
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
# línea en el decorations.lua vivo, así sobrevive a los reload y al cambiar
# de look se guarda con él. Sin línea de shader no hay opción en el menú.
deco="$cfg/hypr/conf/decorations.lua"
shader_entry=""
if grep -qE '^\s*screen_shader\s*=' "$deco"; then
  shader_entry="shader: off"
elif grep -qE '^\s*--\s*screen_shader\s*=' "$deco"; then
  shader_entry="shader: on"
fi

if [ -n "$1" ]; then
  target="$1"
else
  pidof jale >/dev/null && pkill -x jale
  target=$( { [ -n "$shader_entry" ] && echo "$shader_entry"
    "$HOME/.local/bin/lena" list; } |
    jale -dmenu -i -p look -config "$cfg/jale/config-edit.rasi" -mesg "$(L actual current): ${current:-?}")
fi

[ -z "$target" ] && exit 0
case "$target" in
  shader|"shader: off"|"shader: on")
    if grep -qE '^\s*screen_shader\s*=' "$deco"; then
      sed -i -E 's/^(\s*)screen_shader(\s*)=/\1-- screen_shader\2=/' "$deco"
      msg=$(L "shader apagado" "shader off")
    elif grep -qE '^\s*--\s*screen_shader\s*=' "$deco"; then
      sed -i -E 's/^(\s*)--\s*screen_shader(\s*)=/\1screen_shader\2=/' "$deco"
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

# el telón (~/farula): congela la pantalla mientras todo cambia por debajo y
# al final lo abre con un iris desde el cursor (sale con el acento nuevo)
if command -v farula >/dev/null; then
  [ -z "$1" ] && sleep 0.3 # que el menú (jale) termine de irse, o sale en la foto
  farula freeze
fi

# sin autoreload mientras se cambia: Hyprland recargaba solo en cuanto
# leña copiaba decorations.lua, que ya usa los colores del look nuevo
# ($alt, $line…) antes de que `leña colors` los escriba — y salía la
# barra roja de errores un segundo (más en los looks con wallpaper propio).
# El `hyprctl reload` del paso 4 lo vuelve a prender (la config no lo apaga).
"$cfg/hypr/scripts/Hypr.sh" set misc:disable_autoreload true

# 0) quitar el tamaño de letra de discada (FontSize.py) para guardar el look
#    con sus tamaños originales; se vuelve a aplicar después de copiar
"$cfg/hypr/scripts/FontSize.py" unapply

# 1) guardar lo vivo en el look actual (leña: la fuente vuelve a {{font}})
if [ -n "$current" ] && [ -d "$looks/$current" ]; then
  "$HOME/.local/bin/lena" save "$current"
fi

# 2) aplicar el nuevo: sus archivos con su fuente, su wallust.toml y el estilo
#    de rola/vato/taco/arre (todo sale de hypr/looks/<look>/look.toml)
wallust_before=$(md5sum < "$cfg/wallust/wallust.toml" 2>/dev/null)
"$HOME/.local/bin/lena" apply "$target"
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
  "$cfg/hypr/scripts/WallustSwww.sh" "$(readlink -f "$cfg/hypr/wallpaper_effects/.wallpaper_link")" >/dev/null 2>&1
fi

# 3b) los colores del look: su paleta (o la de wallust) y sus nombres propios
"$HOME/.local/bin/lena" colors "$target"

# 4) recargar todo
hyprctl reload >/dev/null
pkill -SIGUSR2 -x empalme
"$cfg/hypr/scripts/SDDMWallpaperSync.sh" >/dev/null 2>&1   # sddm: fuente, forma y paleta del look
"$HOME/.local/bin/lena" apps >/dev/null 2>&1          # apps GTK/Qt: colores del look
pkill -USR1 -x kitty
pkill -x jale 2>/dev/null
# la barra (SIGUSR2) y kitty ya releyeron: un respiro para que pinten
sleep 0.3
farula reveal 2>/dev/null

notify-send -e -u low -i "preferences-desktop-appearance-symbolic" "Look" "$target"
