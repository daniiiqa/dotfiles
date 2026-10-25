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
  # portapapeles y capturas
  wl-clipboard cliphist grim slurp swappy
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
  # fuentes (Mono para iconos alineados, Adwaita Mono para el visualizador)
  ttf-jetbrains-mono-nerd ttf-fantasque-nerd adwaita-fonts noto-fonts noto-fonts-emoji
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
CONFIG_DIRS=(hypr waybar rofi swaync wallust kitty cava btop fastfetch wlogout yazi rola Kvantum qt5ct qt6ct swappy)
ROLA_REPO="https://github.com/daniiiqa/rola.git"

# ── Opciones ─────────────────────────────────────────────────────────────────
DRY=0 SDDM=auto AUR=1 YES=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --sddm) SDDM=yes ;;
    --no-sddm) SDDM=no ;;
    --no-aur) AUR=0 ;;
    -y|--yes) YES=(--noconfirm) ;;
    -h|--help) sed -n '2,19p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
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

# ── 1. Paquetes de los repos ─────────────────────────────────────────────────
say "Paquetes de los repos oficiales (${#REPO_PKGS[@]})"
run sudo pacman -Syu --needed "${YES[@]}" "${REPO_PKGS[@]}"
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

say "Look inicial"
if [ ! -f "$CFG/hypr/looks/.current" ]; then
  if ((DRY)); then echo "   [dry-run] echo minimal > $CFG/hypr/looks/.current"
  else echo minimal > "$CFG/hypr/looks/.current"; fi
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
