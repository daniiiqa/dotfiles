#!/usr/bin/env bash
# Custom (dany): al entrar a otro escritorio en la misma compu (KDE Plasma),
# quitar lo de discada que esos también leerían. Lo corre
# ~/.config/plasma-workspace/env/discada.sh (lo pone install.sh) antes de que
# arranque Plasma.
#
# Lo único que hace falta quitar a mano son los colores del look en las apps
# GTK: leña agrega `@import 'discada.css';` a ~/.config/gtk-{3,4}.0/gtk.css y
# ese archivo lo leen todas las sesiones. Aquí se quita ese renglón (lo demás,
# como el colors.css de KDE, se queda) y al entrar a Hyprland `lena apps` lo
# vuelve a poner (startup.lua). El tema y los iconos de GTK (gsettings) los
# regresa KDE solo al arrancar.
#
# Los programas por defecto ya van en hyprland-mimeapps.list, arre solo
# arranca en Hyprland, y el fetch de la terminal sale con fastfetch.

for v in 3.0 4.0; do
  f="$HOME/.config/gtk-$v/gtk.css"
  [ -f "$f" ] && grep -qxF "@import 'discada.css';" "$f" || continue
  tmp=$(mktemp) || continue
  grep -vxF "@import 'discada.css';" "$f" > "$tmp"
  cat "$tmp" > "$f"
  rm -f "$tmp"
done
exit 0
