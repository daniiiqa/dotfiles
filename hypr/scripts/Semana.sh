#!/usr/bin/env bash
# Custom (dany): el wrapped de discada. Los domingos en la noche (el timer
# hypr/systemd/discada-semana.timer) avisa que tu semana ya está, y con "ver"
# abre `cacha semana` en una terminal. También desde el menú (SUPER+Shift+E).
#
#   Semana.sh          el aviso (y la terminal si le das "ver")
#   Semana.sh ver      la terminal y ya

PATH="$HOME/.local/bin:$PATH"
. "$HOME/.config/hypr/scripts/lang.sh"
command -v cacha >/dev/null || exit 0
# Custom (dany): solo si estás en Hyprland (el timer de systemd también corre
# si entraste a KDE en la misma compu)
case ":${XDG_CURRENT_DESKTOP:-Hyprland}:" in *:Hyprland:*) ;; *) [ "${1:-}" = ver ] || exit 0 ;; esac

ver() {
  setsid kitty --class discada-update -e sh -c "cacha semana; printf '  %s' '$(L "cualquier tecla para cerrar" "any key to close")'; stty -echo -icanon; dd bs=1 count=1 >/dev/null 2>&1" >/dev/null 2>&1 &
}

if [ "${1:-}" = ver ]; then ver; exit 0; fi
act=$(notify-send -a discada -i "view-calendar-week-symbolic" -A ver="$(L ver see)" \
  "$(L "tu semana en discada" "your week in discada")" \
  "$(L "lo que sonó, a qué jugaste y en qué le picaste" "what you played, listened to and worked on")")
[ "$act" = ver ] && ver
exit 0  # sin «ver» el && de arriba sale con 1 y systemd marca discada-semana como failed
