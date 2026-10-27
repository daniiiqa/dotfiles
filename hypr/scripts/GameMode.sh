#!/usr/bin/env bash
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/bell.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0;\
        keyword decoration:screen_shader [[EMPTY]]"
	
	# Custom (dany): sintaxis windowrule actualizada (la vieja tronaba con
	# "invalid field" en Hyprland >= 0.53; hyprctl reload al salir la limpia)
	hyprctl keyword windowrule "match:class .*, opacity 1 override"
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
