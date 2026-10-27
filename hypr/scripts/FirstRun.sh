#!/usr/bin/env bash
# Primer arranque en una máquina nueva (lo lanza startup.conf; corre una vez).
# Deja el escritorio listo sin tocar nada: wallpaper, colores de wallust,
# tema oscuro + iconos para las apps GTK y un aviso de bienvenida.
# Para repetirlo: borrar ~/.local/state/dotfiles/firstrun-done

marker="$HOME/.local/state/dotfiles/firstrun-done"
[ -f "$marker" ] && exit 0

scripts="$HOME/.config/hypr/scripts"
pics="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
walls="$pics/wallpapers"
mkdir -p "$walls" "$(dirname "$marker")"

# 1) wallpaper: el primero que haya; si no hay ninguno, uno generado
wall=$(find -L "$walls" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n 1)
if [ -z "$wall" ]; then
  wall="$walls/default.png"
  # aurora oscura difuminada + grano fino. Un degradado liso no sirve:
  # wallust necesita varios tonos distintos ("Not enough colors!")
  magick -size 480x270 -seed 7 plasma:'#3a2350'-'#123a4a' -blur 0x18 \
    -resize 1920x1080\! -modulate 70,140 \
    \( -size 1920x1080 xc: +noise Random -colorspace gray -evaluate multiply 0.05 \) \
    -compose plus -composite "$wall" 2>/dev/null
fi

# 2) mostrarlo (esperar a que awww-daemon esté arriba)
for _ in $(seq 1 50); do awww query >/dev/null 2>&1 && break; sleep 0.1; done
awww img "$wall" --transition-type fade --transition-duration 1 >/dev/null 2>&1

# 3) colores desde el wallpaper + recargar todo
"$scripts/WallustSwww.sh" "$wall"

# 3b) si el look inicial es de paleta fija, su propio wallpaper (el de arriba
#     queda guardado para cuando cambies a un look que sigue al wallpaper)
look=$(cat "$HOME/.config/hypr/looks/.current" 2>/dev/null)
[ -n "$look" ] && "$scripts/LookWallpaper.sh" "$look"
"$scripts/Refresh.sh" --full

# 4) apps GTK y Qt con los colores del look (claro u oscuro según el look) e
#    iconos (rofi los usa en el lanzador)
"$scripts/AppColors.py"
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null
for v in 3.0 4.0; do
  f="$HOME/.config/gtk-$v/settings.ini"
  [ -f "$f" ] && continue
  mkdir -p "$(dirname "$f")"
  printf '[Settings]\ngtk-application-prefer-dark-theme=true\ngtk-icon-theme-name=Papirus-Dark\n' > "$f"
done

touch "$marker"
. "$HOME/.config/hypr/scripts/lang.sh"
notify-send -a discada "$(L "Bienvenido a discada" "Welcome to discada")" \
  "$(L "SUPER+H atajos · SUPER+Shift+E ajustes · SUPER+T cambiar look" \
       "SUPER+H shortcuts · SUPER+Shift+E settings · SUPER+T switch look")" 2>/dev/null
exit 0
