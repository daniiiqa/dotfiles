#!/usr/bin/env bash
# Game Mode. Turning off all animations

notif="preferences-system-notifications-symbolic"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


H="$SCRIPTSDIR/Hypr.sh"
HYPRGAMEMODE=$("$H" get animations:enabled)
if [ "$HYPRGAMEMODE" = 1 ] ; then
    "$H" set animations:enabled false decoration:shadow:enabled false \
        decoration:blur:enabled false general:gaps_in 0 general:gaps_out 0 \
        general:border_size 1 decoration:rounding 0 decoration:screen_shader "[[EMPTY]]"
	
	# Custom (dany): sintaxis windowrule actualizada (la vieja tronaba con
	# "invalid field" en Hyprland >= 0.53; hyprctl reload al salir la limpia)
	"$H" opaque-all
	# Custom (dany): el video también descansa en game mode, no solo awww
	awww kill
	pkill mpvpaper 2>/dev/null
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
	# Custom (dany): NADA de `awww img` global aquí — pintaba .current_wallpaper
	# en TODOS los monitores y aplastaba las imágenes independientes. El daemon
	# restaura solo su caché por monitor, y los videos reviven desde
	# LiveWallpaper.conf (una línea por monitor, la fuente de verdad).
	awww-daemon --format xrgb &
	live_conf="$HOME/.config/hypr/conf/livewallpaper.conf"
	if [ -f "$live_conf" ]; then
		grep '^exec-once = ' "$live_conf" | sed 's/^exec-once = //' | while read -r cmd; do
			sh -c "$cmd" &
		done
	fi
	sleep 0.5
  hyprctl reload
	${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload
