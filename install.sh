#!/usr/bin/env bash
# Instalador del rice (Arch Linux + Hyprland). En una máquina nueva basta con:
#
#   curl -fsSL https://raw.githubusercontent.com/daniiiqa/dotfiles/main/install.sh | bash
#
# o, con el repo ya clonado:  ./install.sh
#
#   --dry-run    muestra lo que haría, sin tocar nada
#   --no-sddm    no instalar pantalla de login (por defecto se instala SDDM
#                solo si no hay ningún display manager activo)
#   --sddm       instalar/configurar SDDM aunque ya haya otro
#   --no-aur     saltar los paquetes de AUR
#   --looks=L    qué looks instalar sin preguntar: all, none (solo classic) o
#                una lista como retro,nord. Sin esto pregunta; con -y o sin
#                terminal instala todos
#   -y           sin confirmaciones de pacman/yay
#
# Se puede correr más de una vez: los paquetes van con --needed y solo se
# respaldan los archivos que cambian. El primer login a Hyprland termina de
# configurar todo solo (hypr/scripts/FirstRun.sh).

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/daniiiqa/dotfiles.git}"
CLONE_DIR="$HOME/dotfiles"

# ── Paquetes ─────────────────────────────────────────────────────────────────
REPO_PKGS=(
  # Hyprland y lo que lo rodea
  hyprland hypridle hyprlock hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland
  # barra, menús, notificaciones
  waybar rofi swaync yad
  # terminal y herramientas de terminal
  kitty fastfetch btop cava
  yazi fd ripgrep zoxide resvg 7zip poppler ffmpegthumbnailer jq fzf
  # portapapeles, capturas y grabación (Recorder.sh)
  wl-clipboard cliphist grim slurp swappy gpu-screen-recorder
  # audio (visualizador incluido)
  pipewire wireplumber pipewire-pulse pamixer pavucontrol playerctl
  # wallpapers de video y colores
  imagemagick ffmpeg mpv
  # rola (YouTube Music en la terminal): audio por mpv, mpris para waybar
  yt-dlp mpv-mpris rustup
  # utilidades que usan los scripts
  libnotify libqalculate bc curl python xdg-user-dirs xdg-utils git
  # ajustes gráficos, red y bluetooth
  nwg-displays nwg-look qt5ct qt6ct kvantum papirus-icon-theme
  networkmanager nm-connection-editor bluez bluez-utils blueman
  # fuentes base (JetBrainsMono Mono para iconos alineados, Adwaita Mono para
  # el visualizador, Noto Serif para paper); las de cada look van en LOOK_FONT
  ttf-jetbrains-mono-nerd adwaita-fonts noto-fonts noto-fonts-emoji
)
# fuente de cada look (classic usa JetBrainsMono, que va siempre). Solo se
# instalan las de los looks elegidos.
declare -A LOOK_FONT=(
  [brutalist]=ttf-space-mono-nerd [classic]=""            [glass]=otf-geist-mono-nerd
  [minimal]=otf-geist-mono-nerd   [neon]=otf-monaspace-nerd [nord]=ttf-iosevka-nerd
  [outsider]=ttf-fantasque-nerd   [paper]=ttf-ibmplex-mono-nerd
  [pastel]=ttf-victor-mono-nerd   [retro]=ttf-terminus-nerd
)
declare -A LOOK_DESC=(
  [brutalist]="bloques sólidos, cero esquinas, MAYÚSCULAS"
  [classic]="el original: iconos, blur, JetBrainsMono"
  [glass]="vidrio esmerilado, barra abajo, redondeado"
  [minimal]="limpio y discreto, iconos finos"
  [neon]="colores encendidos, iconos rellenos"
  [nord]="paleta Nord fija, barra flotante"
  [outsider]="lo-fi de cassette, minúsculas, grano de película"
  [paper]="papel y tinta, toques de serif"
  [pastel]="suave y redondito, iconos tiernos"
  [retro]="terminal de fósforo, todo en texto"
)
AUR_PKGS=(
  swww       # wallpapers de imagen/gif
  mpvpaper   # wallpapers de video
  wallust    # colores desde el wallpaper
  wlogout    # menú de apagado
)
SDDM_PKGS=(sddm qt6-svg qt6-declarative qt6-5compat)
SDDM_THEME_REPO="https://github.com/JaKooLit/simple-sddm-2.git"
SDDM_THEME_DIR="/usr/share/sddm/themes/simple_sddm_2"

# carpetas del repo que van a ~/.config (las mismas del whitelist de .gitignore)
CONFIG_DIRS=(hypr waybar rofi swaync wallust kitty cava btop fastfetch wlogout yazi rola sddm Kvantum qt5ct qt6ct swappy)
ROLA_REPO="https://github.com/daniiiqa/rola.git"

# ── Opciones ─────────────────────────────────────────────────────────────────
DRY=0 SDDM=auto AUR=1 YES=() LOOKS_ARG=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --looks=*) LOOKS_ARG=${arg#--looks=} ;;
    --sddm) SDDM=yes ;;
    --no-sddm) SDDM=no ;;
    --no-aur) AUR=0 ;;
    -y|--yes) YES=(--noconfirm) ;;
    -h|--help) sed -n '2,20p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opción desconocida: $arg (usa --help)"; exit 2 ;;
  esac
done

say()  { printf '\033[1;35m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
run()  { if ((DRY)); then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }

# ── Comprobaciones ───────────────────────────────────────────────────────────
command -v pacman >/dev/null || { echo "Esto es para Arch Linux (no encontré pacman)."; exit 1; }
[ "$EUID" -ne 0 ] || { echo "Córrelo como tu usuario, no como root (pide sudo cuando lo necesita)."; exit 1; }

# ── 0. Arranque desde curl: clonar el repo y seguir desde ahí ────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)"
if [ ! -d "$REPO_DIR/hypr/conf" ]; then
  say "Descargando los dotfiles en $CLONE_DIR"
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  if [ -d "$CLONE_DIR/.git" ]; then git -C "$CLONE_DIR" pull --ff-only
  else git clone --depth 1 "$REPO_URL" "$CLONE_DIR"; fi
  # stdin era el propio script (curl | bash): devolverle la terminal
  exec bash "$CLONE_DIR/install.sh" "$@" </dev/tty
fi

CFG="$HOME/.config"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
NEW_MACHINE=0
[ "$REPO_DIR" != "$CFG" ] && NEW_MACHINE=1

if [ "$SDDM" = auto ]; then
  if systemctl is-enabled display-manager.service >/dev/null 2>&1; then SDDM=no
  else SDDM=yes; fi
fi

# ── Looks: cuáles instalar y con cuál empezar ────────────────────────────────
in_list() { local x; for x in "${@:2}"; do [ "$x" = "$1" ] && return 0; done; return 1; }

mapfile -t ALL_LOOKS < <(find "$REPO_DIR/hypr/looks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
LOOKS=() INITIAL=""
if [ -n "$LOOKS_ARG" ]; then
  case "$LOOKS_ARG" in
    all) LOOKS=("${ALL_LOOKS[@]}") ;;
    none) LOOKS=(classic) ;;
    *) IFS=, read -ra LOOKS <<< "$LOOKS_ARG" ;;
  esac
elif [ -t 0 ] && ((${#YES[@]} == 0)); then
  say "Looks: cada uno cambia barra, fuentes, colores, iconos y login (SUPER+T)"
  i=1
  for l in "${ALL_LOOKS[@]}"; do
    printf '   %2d) %-10s %s\n' "$i" "$l" "${LOOK_DESC[$l]:-}"
    i=$((i + 1))
  done
  while ((${#LOOKS[@]} == 0)); do
    read -r -p "   ¿Cuáles? [Enter = todos · números separados por espacio · 0 = ninguno, solo classic] " ans
    if [ -z "$ans" ]; then LOOKS=("${ALL_LOOKS[@]}")
    elif [ "$ans" = 0 ]; then LOOKS=(classic)
    else
      for n in $ans; do
        if [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#ALL_LOOKS[@]})); then
          in_list "${ALL_LOOKS[n - 1]}" "${LOOKS[@]}" || LOOKS+=("${ALL_LOOKS[n - 1]}")
        else
          warn "no entendí \"$n\""; LOOKS=(); break
        fi
      done
    fi
  done
  if ((${#LOOKS[@]} > 1)); then
    def=${LOOKS[0]}
    in_list minimal "${LOOKS[@]}" && def=minimal
    while [ -z "$INITIAL" ]; do
      read -r -p "   ¿Con cuál empezar? (${LOOKS[*]}) [Enter = $def] " ans
      ans=${ans:-$def}
      if in_list "$ans" "${LOOKS[@]}"; then INITIAL=$ans; else warn "\"$ans\" no está en la lista"; fi
    done
  fi
else
  LOOKS=("${ALL_LOOKS[@]}")
fi
for l in "${LOOKS[@]}"; do
  in_list "$l" "${ALL_LOOKS[@]}" || { echo "look desconocido: $l (hay: ${ALL_LOOKS[*]})"; exit 2; }
done
if [ -z "$INITIAL" ]; then
  INITIAL=${LOOKS[0]}
  in_list minimal "${LOOKS[@]}" && INITIAL=minimal
fi
LOOK_PKGS=()
for l in "${LOOKS[@]}"; do
  p=${LOOK_FONT[$l]:-}
  [ -n "$p" ] && ! in_list "$p" "${LOOK_PKGS[@]}" && LOOK_PKGS+=("$p")
done
say "Looks: ${LOOKS[*]} (empieza en $INITIAL)"

# ── 1. Paquetes de los repos ─────────────────────────────────────────────────
say "Paquetes de los repos oficiales (${#REPO_PKGS[@]} + ${#LOOK_PKGS[@]} fuentes de looks)"
run sudo pacman -Syu --needed "${YES[@]}" "${REPO_PKGS[@]}" "${LOOK_PKGS[@]}"
[ "$SDDM" = yes ] && run sudo pacman -S --needed "${YES[@]}" "${SDDM_PKGS[@]}"

# ── 2. AUR ───────────────────────────────────────────────────────────────────
if ((AUR)); then
  helper=""
  for h in yay paru; do command -v "$h" >/dev/null && { helper=$h; break; }; done
  if [ -z "$helper" ]; then
    say "No hay ayudante de AUR: instalando yay-bin"
    run sudo pacman -S --needed "${YES[@]}" base-devel git
    tmp=$(mktemp -d)
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    if ((DRY)); then printf '   [dry-run] (cd %s && makepkg -si)\n' "$tmp/yay-bin"
    else (cd "$tmp/yay-bin" && makepkg -si "${YES[@]}"); fi
    helper=yay
  fi
  say "Paquetes de AUR con $helper: ${AUR_PKGS[*]}"
  run "$helper" -S --needed "${YES[@]}" "${AUR_PKGS[@]}"
else
  warn "Saltando AUR: sin swww/mpvpaper/wallust no hay wallpapers ni colores dinámicos"
fi

# ── 3. Dotfiles ──────────────────────────────────────────────────────────────
if ((NEW_MACHINE)); then
  say "Copiando dotfiles a $CFG (lo que se pise va a $BACKUP)"
  for d in "${CONFIG_DIRS[@]}"; do
    [ -d "$REPO_DIR/$d" ] || continue
    # respaldar solo los archivos que existen y son distintos
    while IFS= read -r -d '' f; do
      rel=${f#"$REPO_DIR/"}
      if [ -e "$CFG/$rel" ] && ! cmp -s "$f" "$CFG/$rel"; then
        run mkdir -p "$BACKUP/$(dirname "$rel")"
        run cp -a "$CFG/$rel" "$BACKUP/$rel"
      fi
    done < <(find "$REPO_DIR/$d" -type f -print0)
    run mkdir -p "$CFG/$d"
    run cp -a "$REPO_DIR/$d/." "$CFG/$d/"
  done
  [ -d "$BACKUP" ] && say "Respaldo en $BACKUP"

  # el monitors.conf del repo es el de la máquina original (DP-1, posición
  # fija): aquí, que Hyprland detecte las pantallas. nwg-displays lo reescribe.
  say "Pantallas: detección automática"
  if ((DRY)); then echo "   [dry-run] monitors.conf → monitor=,preferred,auto,1"
  else
    printf '# Detección automática. Para acomodar pantallas: nwg-displays\nmonitor=,preferred,auto,1\n' > "$CFG/hypr/monitors.conf"
  fi
else
  say "El repo ya vive en ~/.config: nada que copiar"
fi

# ── 4. Ajustes que no viven en el repo ───────────────────────────────────────
say "Scripts ejecutables"
run chmod +x "$CFG"/hypr/scripts/*.sh "$CFG"/hypr/scripts/*.py

# enlace al wallpaper de la otra máquina: roto aquí. FirstRun pone uno nuevo.
link="$CFG/rofi/.current_wallpaper"
if [ -L "$link" ] && [ ! -e "$link" ]; then run rm "$link"; fi

looks_dir="$CFG/hypr/looks"
if ((NEW_MACHINE)); then
  # SUPER+T lista las carpetas de looks: quitar las que no se eligieron
  for l in "${ALL_LOOKS[@]}"; do
    in_list "$l" "${LOOKS[@]}" || run rm -rf "${looks_dir:?}/$l"
  done
elif ((${#LOOKS[@]} < ${#ALL_LOOKS[@]})); then
  warn "El repo vive en ~/.config: no se borran looks (serían archivos del repo)"
fi

# Los archivos vivos del repo son del último look con el que se hizo commit,
# no necesariamente el elegido: aplicar el look encima (como LookSwitch.sh) para
# que lo vivo y .current coincidan. Si ya hay look activo aquí, se respeta.
if ((NEW_MACHINE)) || [ ! -f "$looks_dir/.current" ]; then
  say "Look inicial: $INITIAL"
  if ((DRY)); then echo "   [dry-run] copiar $looks_dir/$INITIAL/* sobre $CFG y .current = $INITIAL"
  else
    (cd "$looks_dir/$INITIAL" && find . -type f -printf '%P\n') | while read -r f; do
      mkdir -p "$(dirname "$CFG/$f")"
      cp "$looks_dir/$INITIAL/$f" "$CFG/$f"
    done
    echo "$INITIAL" > "$looks_dir/.current"
  fi
fi

say "yazi como explorador de carpetas por defecto"
desk="$HOME/.local/share/applications/yazi-kitty.desktop"
if ((DRY)); then echo "   [dry-run] escribir $desk + xdg-mime default"
else
  mkdir -p "$(dirname "$desk")"
  cat > "$desk" <<'EOF'
[Desktop Entry]
Name=Archivos (yazi)
Comment=Explorador de archivos en terminal
Exec=kitty --class yazi -e yazi %f
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
  xdg-mime default yazi-kitty.desktop inode/directory
fi

say "rola (YouTube Music en la terminal) → ~/.local/bin/rola"
if ! rustup show active-toolchain >/dev/null 2>&1; then run rustup default stable; fi
run cargo install --git "$ROLA_REPO" --root "$HOME/.local" --locked
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "~/.local/bin no está en el PATH: agrégalo para correr rola" ;; esac

say "Carpetas de usuario y de wallpapers"
run xdg-user-dirs-update
pics="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
run mkdir -p "$pics/wallpapers"

say "Servicios"
run sudo systemctl enable --now NetworkManager.service
run sudo systemctl enable --now bluetooth.service || warn "bluetooth no arrancó (¿no hay adaptador?)"

say "Caché de fuentes"
run fc-cache -f

# ── 5. Pantalla de login ─────────────────────────────────────────────────────
if [ "$SDDM" = yes ]; then
  say "SDDM + tema simple_sddm_2"
  if [ ! -d "$SDDM_THEME_DIR" ]; then
    run sudo git clone --depth 1 "$SDDM_THEME_REPO" "$SDDM_THEME_DIR"
  fi
  # SDDMWallpaperSync.sh escribe ahí el wallpaper y los colores sin sudo
  run sudo chown -R "$USER:" "$SDDM_THEME_DIR"
  if ((DRY)); then echo "   [dry-run] /etc/sddm.conf.d/theme.conf → Current=simple_sddm_2"
  else
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=simple_sddm_2\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
  fi
  run sudo systemctl enable sddm.service
else
  say "Pantalla de login: se deja la que ya hay"
fi

# ── Listo ────────────────────────────────────────────────────────────────────
echo
say "Listo. Al entrar a Hyprland por primera vez se pone un wallpaper, se"
say "generan los colores y sale un aviso con los atajos (SUPER+H)."
echo "   Tus wallpapers (imágenes o videos) van en $pics/wallpapers"
if ((!DRY)) && [ -t 0 ]; then
  read -r -p "¿Reiniciar ahora? [s/N] " ans
  case "$ans" in s|S|y|Y) sudo systemctl reboot ;; esac
fi
