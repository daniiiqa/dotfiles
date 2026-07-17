#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

PICS=($(find -L "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

# Transition config
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Custom (dany): daemon con if de verdad — el `query || daemon && img` original
# tenía la precedencia rota (el img quedaba encadenado al arranque del daemon)
if ! pgrep -x swww-daemon >/dev/null; then
  swww-daemon --format xrgb &
  sleep 1
fi

# Custom (dany): igual que elegir imagen en el selector — si ESTE monitor traía
# video, el video muere y su línea de LiveWallpaper.conf se limpia. Sin esto la
# imagen aterriza DETRÁS del video (parece que el random no hizo nada) y el
# video revive al reboot.
live_conf="$HOME/.config/hypr/UserConfigs/LiveWallpaper.conf"
for pid in $(pgrep -x mpvpaper); do
  if ps -o args= -p "$pid" | tr ' ' '\n' | grep -qx -e "$focused_monitor" -e '\*' -e "'\*'"; then
    kill "$pid" 2>/dev/null
  fi
done
if [ -f "$live_conf" ]; then
  grep -v -e "mpvpaper $focused_monitor " -e "mpvpaper '\*'" "$live_conf" > "$live_conf.tmp"
  mv "$live_conf.tmp" "$live_conf"
fi

swww img -o "$focused_monitor" "$RANDOMPICS" $SWWW_PARAMS

# Custom (dany): pasar la ruta exacta — sin argumento, WallustSwww lee el caché
# de swww y en randoms seguidos generaba el theme del wallpaper ANTERIOR
# (carrera: el caché aún no se escribía cuando wallust leía)
"$SCRIPTSDIR/WallustSwww.sh" "$RANDOMPICS"
sleep 2
"$SCRIPTSDIR/Refresh.sh"
