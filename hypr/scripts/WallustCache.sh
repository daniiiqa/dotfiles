#!/usr/bin/env bash
# Custom (dany): llena la caché de wallust con todos los wallpapers, para que
# elegir uno nunca espere a kmeans (de 1 a 6 s la primera vez en imágenes
# grandes; ya en caché, ~10 ms). Sin templates ni secuencias: no toca los
# colores de nada. La caché es del backend, así que sirve para todos los looks
# (cada paleta sale de ella en <100 ms). Los videos también: el fotograma de
# en medio, igual que WallpaperSelect.sh, que así ya no corre ffmpeg al elegir.
# Corre al iniciar sesión (startup) y al abrir el menú de wallpapers
# (WallpaperSelect.sh), con prioridad baja; lo ya cacheado se
# brinca solo. Uso: WallustCache.sh

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/wallust-cache.lock"
flock -n 9 || exit 0

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
frame_dir="$HOME/.cache/video_frame"

renice -n 19 -p $$ >/dev/null
ionice -c 3 -p $$ 2>/dev/null

find -L "$wallDIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0 |
  while IFS= read -r -d '' video; do
    frame="$frame_dir/$(basename "$video").png"
    [[ -f "$frame" ]] && continue
    mkdir -p "$frame_dir"
    dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$video" 2>/dev/null)
    mid=$(echo "${dur:-2} / 2" | bc 2>/dev/null)
    ffmpeg -y -loglevel error -ss "${mid:-1}" -i "$video" -frames:v 1 "$frame" 2>/dev/null
  done

{
  find -L "$wallDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
    -iname "*.gif" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \) -print0
  find "$frame_dir" -type f -name "*.png" -print0 2>/dev/null
} | while IFS= read -r -d '' img; do
  wallust run -s -T -q "$img" >/dev/null 2>&1
done
