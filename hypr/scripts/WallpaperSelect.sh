#!/usr/bin/env bash
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if package bc exists
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Custom (dany): wallpapers independientes por monitor.
# swww-daemon queda SIEMPRE vivo (imágenes/gifs); mpvpaper corre una instancia
# por monitor solo donde hay video. Matar mpvpaper únicamente en un output
# (las instancias legacy con '*' cubrían todo, también cuentan).
kill_mpvpaper_on() {
  local out="$1" pid
  for pid in $(pgrep -x mpvpaper); do
    if ps -o args= -p "$pid" | tr ' ' '\n' | grep -qx -e "$out" -e '\*' -e "'\*'"; then
      kill "$pid" 2>/dev/null
    fi
  done
}

# Kill existing wallpaper daemons for video
kill_wallpaper_for_video() {
  kill_mpvpaper_on "$focused_monitor"
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Kill existing wallpaper daemons for image
kill_wallpaper_for_image() {
  kill_mpvpaper_on "$focused_monitor"
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Retrieve wallpapers (both images & videos)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi command
rofi_command="rofi -i -show -dmenu -config $rofi_theme -theme-str $rofi_override"

# Sorting Wallpapers
menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))

  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
    else
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$pic_path"
    fi
  done
}


# Custom (dany): la persistencia de videos vive en LiveWallpaper.conf (una
# línea exec-once por monitor), regenerado aquí — nada de seds sobre
# startup.conf. swww-daemon arranca siempre desde startup.conf.
modify_startup_config() {
  local selected_file="$1"
  local live_conf="$HOME/.config/hypr/conf/livewallpaper.conf"

  touch "$live_conf"
  # Quitar la entrada previa de ESTE monitor (y cualquier legacy global '*').
  # Ojo: grep -v sale con 1 si filtra todo, por eso NO se encadena con && —
  # el tmp queda escrito (vacío) de todos modos y el mv debe correr siempre.
  grep -v -e "mpvpaper $focused_monitor " -e "mpvpaper '\*'" "$live_conf" > "$live_conf.tmp"
  mv "$live_conf.tmp" "$live_conf"

  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # sleep 1: mpvpaper debe mapear su superficie DESPUÉS de swww, o la imagen
    # cacheada de swww quedaría encima del video en este monitor
    selected_file="${selected_file/#$HOME/\$HOME}" # Replace /home/user with $HOME
    echo "exec-once = sleep 1 && mpvpaper $focused_monitor -o \"load-scripts=no no-audio --loop hwdec=auto\" \"$selected_file\"" >> "$live_conf"
    echo "Configured live wallpaper (video) for $focused_monitor."
  else
    echo "Configured static wallpaper (image) for $focused_monitor."
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"

  kill_wallpaper_for_image

  if ! pgrep -x "swww-daemon" >/dev/null; then
    echo "Starting swww-daemon..."
    swww-daemon --format xrgb &
  fi

  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS

  # Run additional scripts (pass the image path to avoid cache race conditions)
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  sleep 1

}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Custom (dany): swww debe estar vivo ANTES de lanzar mpvpaper — sirve los
  # demás monitores, y su superficie tiene que quedar debajo del video.
  if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb &
    sleep 1
  fi

  # Apply video wallpaper using mpvpaper — SOLO en el monitor enfocado.
  # hwdec=auto: decodificación por hardware (un 4K por software costaba ~30% CPU)
  mpvpaper "$focused_monitor" -o "load-scripts=no no-audio --loop hwdec=auto" "$video_path" &

  # Custom (dany): el theme TAMBIÉN cambia con un wallpaper vivo. Wallust no
  # puede leer un video, así que se extrae el fotograma de en medio del clip
  # (cacheado por video) y ese alimenta wallust — y por la misma tubería, el
  # fondo de SDDM, que queda con el fotograma del video.
  local frame_dir="$HOME/.cache/video_frame"
  local frame="$frame_dir/$(basename "$video_path").png"
  if [[ ! -f "$frame" ]] && command -v ffmpeg &>/dev/null; then
    mkdir -p "$frame_dir"
    local dur mid
    dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$video_path" 2>/dev/null)
    mid=$(echo "${dur:-2} / 2" | bc 2>/dev/null)
    ffmpeg -y -loglevel error -ss "${mid:-1}" -i "$video_path" -frames:v 1 "$frame" 2>/dev/null
  fi
  if [[ -f "$frame" ]]; then
    "$SCRIPTSDIR/WallustSwww.sh" "$frame"
    sleep 2
    "$SCRIPTSDIR/Refresh.sh"
  fi
}

# Main function
main() {
  choice=$(menu | $rofi_command)
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  # Handle random selection correctly
  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    choice=$(basename "$RANDOM_PIC")
  fi

  choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')

  # Search for the selected file in the wallpapers directory, including subdirectories
  selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

  if [[ -z "$selected_file" ]]; then
    echo "File not found. Selected choice: $choice"
    exit 1
  fi

  # Persistir el wallpaper (livewallpaper.conf) según su tipo
  modify_startup_config "$selected_file"

  # **CHECK FIRST** if it's a video or an image **before calling any function**
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main