#!/usr/bin/env bash
# Custom (dany): si en la misma compu también hay KDE Plasma, que lo de
# discada se quede en Hyprland: KDE con sus colores, sus iconos, su tema y su
# cursor, y Hyprland con los de discada.
#
#   FueraDeHyprland.sh entra     al entrar a Plasma, antes de que arranque
#                                (~/.config/plasma-workspace/env/discada.sh)
#   FueraDeHyprland.sh sale      al salir de Plasma: guarda lo de KDE
#                                (~/.config/plasma-workspace/shutdown/discada.sh)
#   FueraDeHyprland.sh regresa   al entrar a Hyprland (startup.lua), antes de
#                                `lena apps`
#
# Lo que comparten los dos escritorios y aquí se separa:
#   - ~/.config/gtk-{3,4}.0/gtk.css: leña le agrega `@import 'discada.css';`
#     (los colores del look en las apps GTK). En KDE se quita ese renglón (lo
#     demás, como el colors.css de KDE, se queda); `lena apps` lo vuelve a poner.
#   - gsettings (org.gnome.desktop.interface): tema GTK, iconos, claro/oscuro y
#     cursor; y ~/.config/gtk-{3,4}.0/settings.ini. Cada escritorio tiene su
#     copia en ~/.local/state/discada/escritorio/{kde,hyprland}: al cambiar de
#     uno a otro se guarda la del que se fue y se pone la del que llega.
#
# Lo demás ya va por su lado: programas por defecto en hyprland-mimeapps.list,
# arre solo en Hyprland, fastfetch en la terminal de KDE, Qt (qt6ct) solo con
# las variables de Hyprland.

dir="${XDG_STATE_HOME:-$HOME/.local/state}/discada/escritorio"
ultima="$dir/ultima"   # el último escritorio en el que se entró
KEYS=(gtk-theme icon-theme color-scheme cursor-theme cursor-size)
IMPORT="@import 'discada.css';"
# lo que FirstRun.sh escribe en settings.ini si no había
INI_DISCADA=$'[Settings]\ngtk-application-prefer-dark-theme=true\ngtk-icon-theme-name=Papirus-Dark'

gs() { command -v gsettings >/dev/null && timeout 3 gsettings "$@" 2>/dev/null; }

guardar() {  # guardar <kde|hyprland>
  local d="$dir/$1" k v
  mkdir -p "$d" || return
  : > "$d/gsettings.tmp"
  for k in "${KEYS[@]}"; do
    v=$(gs get org.gnome.desktop.interface "$k") && printf '%s\t%s\n' "$k" "$v" >> "$d/gsettings.tmp"
  done
  # sin gsettings (o sin sesión de D-Bus) no se pisa lo que ya estaba guardado
  if [ -s "$d/gsettings.tmp" ]; then mv "$d/gsettings.tmp" "$d/gsettings"; else rm -f "$d/gsettings.tmp"; fi
  for v in 3.0 4.0; do
    if [ -f "$HOME/.config/gtk-$v/settings.ini" ]; then cp "$HOME/.config/gtk-$v/settings.ini" "$d/settings-$v.ini"
    else rm -f "$d/settings-$v.ini"; fi
  done
}

poner() {  # poner <kde|hyprland>: 1 si no había nada guardado
  local d="$dir/$1" k v
  [ -s "$d/gsettings" ] || [ -f "$d/settings-3.0.ini" ] || return 1
  if [ -s "$d/gsettings" ]; then
    while IFS=$'\t' read -r k v; do
      [ -n "$k" ] && gs set org.gnome.desktop.interface "$k" "$v"
    done < "$d/gsettings"
  fi
  for v in 3.0 4.0; do
    [ -f "$d/settings-$v.ini" ] && mkdir -p "$HOME/.config/gtk-$v" && cp "$d/settings-$v.ini" "$HOME/.config/gtk-$v/settings.ini"
  done
  return 0
}

sin_import() {
  local v f tmp
  for v in 3.0 4.0; do
    f="$HOME/.config/gtk-$v/gtk.css"
    [ -f "$f" ] && grep -qxF "$IMPORT" "$f" || continue
    tmp=$(mktemp) || continue
    grep -vxF "$IMPORT" "$f" > "$tmp"
    cat "$tmp" > "$f"
    rm -f "$tmp"
  done
}

mkdir -p "$dir" 2>/dev/null
antes=$(cat "$ultima" 2>/dev/null)

case "${1:-entra}" in
  entra)
    sin_import
    # lo que hay ahora es de Hyprland (se viene de ahí, o es la primera vez)
    [ "$antes" = kde ] || guardar hyprland
    if ! poner kde; then
      # la primera vez en KDE con discada: lo de discada se quita y KDE pone
      # lo suyo al arrancar (su módulo de GTK lo sincroniza)
      for k in "${KEYS[@]}"; do gs reset org.gnome.desktop.interface "$k"; done
      for v in 3.0 4.0; do
        f="$HOME/.config/gtk-$v/settings.ini"
        [ "$(cat "$f" 2>/dev/null)" = "$INI_DISCADA" ] && rm -f "$f"
      done
    fi
    echo kde > "$ultima"
    ;;
  sale)
    guardar kde
    ;;
  regresa)
    [ "$antes" = kde ] && poner hyprland
    echo hyprland > "$ultima"
    ;;
esac
exit 0
