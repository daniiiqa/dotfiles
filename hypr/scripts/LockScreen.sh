#!/usr/bin/env bash
# Custom (dany): farula (el telón) vive en ~/.local/bin, que no está en el
# PATH de Hyprland
PATH="$HOME/.local/bin:$PATH"

# Bloquea vía hypridle (lock_cmd = LockScreen.sh run)
#   LockScreen.sh        bloquear (loginctl → hypridle → lock_cmd)
#   LockScreen.sh run    lo que corre hypridle: hyprlock, y al desbloquear el
#                        escritorio sale con el efecto del look (farula)
#
# Al desbloquear, hyprlock se va de golpe. Para que se abra con estilo, ya
# bloqueado se pone farula debajo con la misma imagen que muestra hyprlock
# (su wallpaper, con su blur y su brillo: así no se nota el relevo) y cuando
# hyprlock sale, farula revela el escritorio. Bloqueado no se puede capturar
# la pantalla, por eso la imagen y no una foto.

if [ "$1" != run ]; then
  loginctl lock-session
  exit
fi

pidof hyprlock >/dev/null && exit 0

# Custom (dany): LOCKER=chapa en hypr/discada.conf → la chapa de discada en vez
# de hyprlock (con huella si hay lector y dedos). chapa sale con 0 solo al
# abrirse; si sale de otro modo (se cayó, no pudo bloquear), hyprlock toma el
# bloqueo (misc:allow_session_lock_restore), para no quedarse en la pantalla
# roja de Hyprland.
locker=$(sed -nE 's/^LOCKER=([a-z]+).*/\1/p' "$HOME/.config/hypr/discada.conf" 2>/dev/null)
if [ "$locker" = chapa ] && command -v chapa >/dev/null; then
  pidof chapa >/dev/null && exit 0
  chapa && exit 0
  echo "LockScreen: chapa salió con $?, sigue hyprlock" >&2
  exec hyprlock
fi

# con farula, hyprlock sin su fadeOut: al desbloquear se desvanecía medio
# segundo sobre la misma imagen y luego apenas empezaba el efecto (se sentía
# lento). Una copia de su config con solo eso apagado; si con ella no
# arrancara, el de siempre: el lock nunca se queda sin poner.
conf="$HOME/.config/hypr/hyprlock.conf"
lock_conf=()
extra=""
if command -v farula >/dev/null && [ ! -e "$HOME/.config/hypr/farula.off" ]; then
  extra+=$'\nanimations {\n    animation = fadeOut, 0\n}\n'
fi
# huella: si fprintd ya tiene un dedo registrado, hyprlock también abre con el
# lector, a la par de la contraseña (sin esperar a que se acabe el tiempo)
if command -v fprintd-list >/dev/null && fprintd-list "$USER" 2>/dev/null | grep -q ' - #'; then
  extra+=$'\nauth {\n    fingerprint:enabled = true\n}\n'
fi
if [ -n "$extra" ]; then
  quick="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-farula.conf"
  { cat "$conf"; printf '%s' "$extra"; } > "$quick"
  lock_conf=(-c "$quick")
fi
hyprlock "${lock_conf[@]}" &
lock=$!
if [ ${#lock_conf[@]} -gt 0 ]; then
  sleep 0.4
  if ! kill -0 "$lock" 2>/dev/null; then
    hyprlock &
    lock=$!
  fi
fi

# la imagen del telón: lo que pinta el background {} de hyprlock
lock_image() {
  local conf="$HOME/.config/hypr/hyprlock.conf"
  local wall="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
  local out="${XDG_RUNTIME_DIR:-/tmp}/farula-lock.ppm"
  [ -f "$wall" ] || return 1
  read -r size passes bright < <(awk '
    /^background *\{/ { inb = 1 } inb && /^\}/ { inb = 0 }
    inb && $1 == "blur_size"   { s = $3 } inb && $1 == "blur_passes" { p = $3 }
    inb && $1 == "brightness"  { b = $3 }
    END { print (s == "" ? 0 : s) + 0, (p == "" ? 0 : p) + 0, (b == "" ? 1 : b) + 0 }' "$conf")
  local geo
  geo=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width)x\(.height)"')
  # el blur de hyprlock (kawase) a ojo: un gaussiano de size×passes, hecho a
  # un cuarto de tamaño para que sea rápido
  local blur=()
  if [ "$passes" -gt 0 ] && [ "$size" -gt 0 ]; then
    blur=(-resize 25% -blur "0x$(echo "$size * $passes * 0.45" | bc -l)" -resize 400%)
  fi
  magick "${wall}[0]" -resize "${geo}^" -gravity center -extent "$geo" "${blur[@]}" \
    -resize "${geo}!" -evaluate multiply "$bright" "ppm:$out" 2>/dev/null && echo "$out"
}
img=$(lock_image)

# que hyprlock ya tape la pantalla antes de poner el telón (si no, se vería
# encima del escritorio un instante)
sleep 0.4
if [ -n "$img" ] && kill -0 "$lock" 2>/dev/null; then
  farula freeze --image "$img" --hold
fi

wait "$lock"
farula reveal 2>/dev/null
