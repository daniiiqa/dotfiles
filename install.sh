#!/usr/bin/env bash
# Instalador de discada, el rice de los looks (Arch Linux + Hyprland).
# discada installer (Arch Linux + Hyprland) — run with --help for English.
# En una máquina nueva basta con:
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
#   --lang=L     idioma de los menús y avisos: en o es (sin esto pregunta;
#                con -y o sin terminal, en)
#   --update     actualizar una instalación: conserva idioma, looks, look
#                actual y tus ajustes (discada.conf, recorder.conf, monitores,
#                apps fijadas…); solo instala paquetes que falten. Lo usa
#                "actualizar discada" del menú (hypr/scripts/Update.sh)
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
  nwg-displays nwg-look qt5ct qt6ct kvantum papirus-icon-theme adw-gtk-theme
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
  [fundidora]=ttf-martian-mono-nerd [ofrenda]=otf-monaspace-nerd
  [loteria]=otf-codenewroman-nerd  [talavera]=otf-monaspace-nerd
)
declare -A LOOK_DESC_ES=(
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
  [fundidora]="acero regio: carbón, alto horno, el Cerro de la Silla"
  [ofrenda]="Día de Muertos: cempasúchil, papel picado, luz de vela"
  [loteria]="las cartas: papel viejo, contornos negros, colores de imprenta"
  [talavera]="loza de Puebla: esmalte crema y trazo cobalto"
)
declare -A LOOK_DESC_EN=(
  [brutalist]="solid blocks, zero corners, UPPERCASE"
  [classic]="the original: icons, blur, JetBrainsMono"
  [glass]="frosted glass, bottom bar, rounded"
  [minimal]="clean and quiet, thin icons"
  [neon]="glowing colors, filled icons"
  [nord]="fixed Nord palette, floating bar"
  [outsider]="lo-fi cassette, lowercase, film grain"
  [paper]="paper and ink, serif touches"
  [pastel]="soft and round, cute icons"
  [retro]="phosphor terminal, all text"
  [fundidora]="Monterrey steel: charcoal, blast furnace, Cerro de la Silla"
  [ofrenda]="Day of the Dead: marigolds, papel picado, candlelight"
  [loteria]="the card game: old paper, black outlines, print colors"
  [talavera]="Puebla pottery: cream glaze and cobalt linework"
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
# tus ajustes: --update no los pisa
KEEP_ON_UPDATE=(hypr/discada.conf hypr/recorder.conf hypr/monitors.conf hypr/workspaces.conf
                hypr/conf/pinned.conf hypr/conf/defaults.conf hypr/conf/livewallpaper.conf)

# ── Opciones ─────────────────────────────────────────────────────────────────
DRY=0 SDDM=auto AUR=1 YES=() LOOKS_ARG="" UI_LANG="" UPDATE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --looks=*) LOOKS_ARG=${arg#--looks=} ;;
    --lang=es|--lang=en) UI_LANG=${arg#--lang=} ;;
    --update) UPDATE=1 ;;
    --sddm) SDDM=yes ;;
    --no-sddm) SDDM=no ;;
    --no-aur) AUR=0 ;;
    -y|--yes) YES=(--noconfirm) ;;
    -h|--help)
      if [[ ${LANG:-} == es* ]]; then sed -n '2,24p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'
      else cat <<'HELP'
discada installer — the rice of looks (Arch Linux + Hyprland).

  curl -fsSL https://raw.githubusercontent.com/daniiiqa/dotfiles/main/install.sh | bash
  or, from a clone:  ./install.sh

  --dry-run    show what it would do without touching anything
  --no-sddm    don't install a login screen (by default SDDM is installed only
               when no display manager is enabled)
  --sddm       install/configure SDDM even if another one is enabled
  --no-aur     skip AUR packages
  --looks=L    which looks to install without asking: all, none (classic only)
               or a list like retro,nord. Without it, it asks; with -y or no
               terminal it installs them all
  --lang=L     language for menus and notifications: en or es (asks without
               it; with -y or no terminal, en)
  --update     update an existing install: keeps language, looks, current look
               and your settings (discada.conf, recorder.conf, monitors, pinned
               apps…); only installs missing packages. Used by "update discada"
               in the settings menu (hypr/scripts/Update.sh)
  -y           no pacman/yay confirmations

Safe to run more than once: packages use --needed and only changed files are
backed up. The first Hyprland login finishes the setup (hypr/scripts/FirstRun.sh).
HELP
      fi
      exit 0 ;;
    *) echo "unknown option / opción desconocida: $arg (--help)"; exit 2 ;;
  esac
done

# idioma: L "español" "english"
L() { if [ "$UI_LANG" = es ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
say()  { printf '\033[1;35m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
run()  { if ((DRY)); then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }

# ── Comprobaciones ───────────────────────────────────────────────────────────
command -v pacman >/dev/null || { echo "discada is for Arch Linux (pacman not found) / es para Arch Linux (no encontré pacman)."; exit 1; }
[ "$EUID" -ne 0 ] || { echo "Run it as your user, not root / Córrelo como tu usuario, no como root."; exit 1; }

# ── 0. Arranque desde curl: clonar el repo y seguir desde ahí ────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)"
if [ ! -d "$REPO_DIR/hypr/conf" ]; then
  say "discada → $CLONE_DIR"
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  if [ -d "$CLONE_DIR/.git" ]; then git -C "$CLONE_DIR" pull --ff-only
  else git clone --depth 1 "$REPO_URL" "$CLONE_DIR"; fi
  # stdin era el propio script (curl | bash): devolverle la terminal
  exec bash "$CLONE_DIR/install.sh" "$@" </dev/tty
fi

# ── Idioma ───────────────────────────────────────────────────────────────────
# al actualizar: el que ya tienes
if ((UPDATE)) && [ -z "$UI_LANG" ]; then
  UI_LANG=$(sed -nE 's/^LANGUAGE=([a-z]+).*/\1/p' "$HOME/.config/hypr/discada.conf" 2>/dev/null)
  [ "$UI_LANG" = es ] || UI_LANG=en
fi
if [ -z "$UI_LANG" ]; then
  UI_LANG=en
  if [ -t 0 ] && ((${#YES[@]} == 0)); then
    printf '\033[1;35m::\033[0m discada — language / idioma:  1) English  2) Español\n'
    read -r -p "   [Enter = English] " ans
    case "$ans" in 2|es|ES|español|Español|espanol) UI_LANG=es ;; esac
  fi
fi

CFG="$HOME/.config"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
NEW_MACHINE=0
[ "$REPO_DIR" != "$CFG" ] && NEW_MACHINE=1

((UPDATE)) && SDDM=no   # actualizar no toca la pantalla de login
if [ "$SDDM" = auto ]; then
  if systemctl is-enabled display-manager.service >/dev/null 2>&1; then SDDM=no
  else SDDM=yes; fi
fi

# ── Looks: cuáles instalar y con cuál empezar ────────────────────────────────
in_list() { local x; for x in "${@:2}"; do [ "$x" = "$1" ] && return 0; done; return 1; }

mapfile -t ALL_LOOKS < <(find "$REPO_DIR/hypr/looks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
LOOKS=() INITIAL=""
if ((UPDATE)) && [ -z "$LOOKS_ARG" ]; then
  # los looks que ya tienes (y que sigan existiendo) y el que está puesto
  for l in "${ALL_LOOKS[@]}"; do [ -d "$CFG/hypr/looks/$l" ] && LOOKS+=("$l"); done
  ((${#LOOKS[@]})) || LOOKS=("${ALL_LOOKS[@]}")
  cur=$(cat "$CFG/hypr/looks/.current" 2>/dev/null)
  in_list "$cur" "${LOOKS[@]}" && INITIAL=$cur
elif [ -n "$LOOKS_ARG" ]; then
  case "$LOOKS_ARG" in
    all) LOOKS=("${ALL_LOOKS[@]}") ;;
    none) LOOKS=(classic) ;;
    *) IFS=, read -ra LOOKS <<< "$LOOKS_ARG" ;;
  esac
elif [ -t 0 ] && ((${#YES[@]} == 0)); then
  say "$(L "Looks: cada uno cambia barra, fuentes, colores, iconos y login (SUPER+T)" \
          "Looks: each one changes the bar, fonts, colors, icons and login (SUPER+T)")"
  i=1
  for l in "${ALL_LOOKS[@]}"; do
    if [ "$UI_LANG" = es ]; then desc=${LOOK_DESC_ES[$l]:-}; else desc=${LOOK_DESC_EN[$l]:-}; fi
    printf '   %2d) %-10s %s\n' "$i" "$l" "$desc"
    i=$((i + 1))
  done
  while ((${#LOOKS[@]} == 0)); do
    read -r -p "   $(L "¿Cuáles? [Enter = todos · números separados por espacio · 0 = ninguno, solo classic]" \
                     "Which ones? [Enter = all · numbers separated by spaces · 0 = none, classic only]") " ans
    if [ -z "$ans" ]; then LOOKS=("${ALL_LOOKS[@]}")
    elif [ "$ans" = 0 ]; then LOOKS=(classic)
    else
      for n in $ans; do
        if [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#ALL_LOOKS[@]})); then
          in_list "${ALL_LOOKS[n - 1]}" "${LOOKS[@]}" || LOOKS+=("${ALL_LOOKS[n - 1]}")
        else
          warn "$(L "no entendí" "didn't get") \"$n\""; LOOKS=(); break
        fi
      done
    fi
  done
  if ((${#LOOKS[@]} > 1)); then
    def=${LOOKS[0]}
    in_list minimal "${LOOKS[@]}" && def=minimal
    while [ -z "$INITIAL" ]; do
      read -r -p "   $(L "¿Con cuál empezar?" "Which one to start with?") (${LOOKS[*]}) [Enter = $def] " ans
      ans=${ans:-$def}
      if in_list "$ans" "${LOOKS[@]}"; then INITIAL=$ans; else warn "\"$ans\" $(L "no está en la lista" "is not in the list")"; fi
    done
  fi
else
  LOOKS=("${ALL_LOOKS[@]}")
fi
for l in "${LOOKS[@]}"; do
  in_list "$l" "${ALL_LOOKS[@]}" || { echo "$(L "look desconocido" "unknown look"): $l (${ALL_LOOKS[*]})"; exit 2; }
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
say "Looks: ${LOOKS[*]} ($(L "empieza en" "starting with") $INITIAL)"

# ── 1. Paquetes de los repos ─────────────────────────────────────────────────
say "$(L "Paquetes de los repos oficiales" "Official repo packages") (${#REPO_PKGS[@]} + ${#LOOK_PKGS[@]} $(L "fuentes de looks" "look fonts"))"
if ((UPDATE)); then
  # solo lo que falte (paquetes nuevos de discada o de un look)
  mapfile -t missing < <(pacman -T "${REPO_PKGS[@]}" "${LOOK_PKGS[@]}" 2>/dev/null)
  if ((${#missing[@]})); then run sudo pacman -Syu --needed "${YES[@]}" "${missing[@]}"
  else echo "   $(L "nada nuevo que instalar" "nothing new to install")"; fi
else
  run sudo pacman -Syu --needed "${YES[@]}" "${REPO_PKGS[@]}" "${LOOK_PKGS[@]}"
fi
[ "$SDDM" = yes ] && run sudo pacman -S --needed "${YES[@]}" "${SDDM_PKGS[@]}"

# ── 2. AUR ───────────────────────────────────────────────────────────────────
if ((AUR)); then
  helper=""
  for h in yay paru; do command -v "$h" >/dev/null && { helper=$h; break; }; done
  if [ -z "$helper" ]; then
    say "$(L "No hay ayudante de AUR: instalando yay-bin" "No AUR helper: installing yay-bin")"
    run sudo pacman -S --needed "${YES[@]}" base-devel git
    tmp=$(mktemp -d)
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    if ((DRY)); then printf '   [dry-run] (cd %s && makepkg -si)\n' "$tmp/yay-bin"
    else (cd "$tmp/yay-bin" && makepkg -si "${YES[@]}"); fi
    helper=yay
  fi
  say "$(L "Paquetes de AUR con" "AUR packages with") $helper: ${AUR_PKGS[*]}"
  if ((UPDATE)); then
    mapfile -t missing < <(pacman -T "${AUR_PKGS[@]}" 2>/dev/null)
    ((${#missing[@]})) && run "$helper" -S --needed "${YES[@]}" "${missing[@]}"
  else
    run "$helper" -S --needed "${YES[@]}" "${AUR_PKGS[@]}"
  fi
else
  warn "$(L "Saltando AUR: sin swww/mpvpaper/wallust no hay wallpapers ni colores dinámicos" \
            "Skipping AUR: without swww/mpvpaper/wallust there are no wallpapers or dynamic colors")"
fi

# ── 3. Dotfiles ──────────────────────────────────────────────────────────────
if ((NEW_MACHINE)); then
  say "$(L "Copiando dotfiles a $CFG (lo que se pise va a $BACKUP)" "Copying dotfiles to $CFG (anything overwritten goes to $BACKUP)")"
  keep=""
  if ((UPDATE)) && ! ((DRY)); then
    keep=$(mktemp -d)
    for f in "${KEEP_ON_UPDATE[@]}"; do
      [ -e "$CFG/$f" ] && { mkdir -p "$keep/$(dirname "$f")"; cp -a "$CFG/$f" "$keep/$f"; }
    done
  fi
  for d in "${CONFIG_DIRS[@]}"; do
    [ -d "$REPO_DIR/$d" ] || continue
    # respaldar solo los archivos que existen y son distintos
    while IFS= read -r -d '' f; do
      rel=${f#"$REPO_DIR/"}
      # al actualizar, tus ajustes se quedan como están
      if ((UPDATE)) && [ -e "$CFG/$rel" ] && in_list "$rel" "${KEEP_ON_UPDATE[@]}"; then
        continue
      fi
      if [ -e "$CFG/$rel" ] && ! cmp -s "$f" "$CFG/$rel"; then
        run mkdir -p "$BACKUP/$(dirname "$rel")"
        run cp -a "$CFG/$rel" "$BACKUP/$rel"
      fi
    done < <(find "$REPO_DIR/$d" -type f -print0)
    run mkdir -p "$CFG/$d"
    # --remove-destination: hay archivos de solo lectura (plugins de yazi)
    run cp -a --remove-destination "$REPO_DIR/$d/." "$CFG/$d/"
  done
  if [ -n "$keep" ]; then
    cp -a "$keep/." "$CFG/" && rm -rf "$keep"
  fi
  [ -d "$BACKUP" ] && say "$(L "Respaldo en" "Backup in") $BACKUP"

  # semillas de lo que no se trackea porque cambia solo (colores de wallust,
  # ajustes de rola): solo si faltan
  seed="$REPO_DIR/hypr/seed"
  while IFS= read -r -d '' f; do
    rel=${f#"$seed/"}
    [ "$rel" = README.md ] && continue
    if [ ! -e "$CFG/$rel" ]; then
      run mkdir -p "$CFG/$(dirname "$rel")"
      run cp "$f" "$CFG/$rel"
    fi
  done < <(find "$seed" -type f -print0)

  # el monitors.conf del repo es el de la máquina original (DP-1, posición
  # fija): aquí, que Hyprland detecte las pantallas. nwg-displays lo reescribe.
  if ! ((UPDATE)); then
    say "$(L "Pantallas: detección automática" "Displays: automatic detection")"
    if ((DRY)); then echo "   [dry-run] monitors.conf → monitor=,preferred,auto,1"
    else
      printf '# Detección automática. Para acomodar pantallas: nwg-displays\nmonitor=,preferred,auto,1\n' > "$CFG/hypr/monitors.conf"
    fi
  fi
else
  say "$(L "El repo ya vive en ~/.config: nada que copiar" "The repo already lives in ~/.config: nothing to copy")"
fi

# ── 4. Ajustes que no viven en el repo ───────────────────────────────────────
say "$(L "Scripts ejecutables" "Executable scripts")"
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
  warn "$(L "El repo vive en ~/.config: no se borran looks (serían archivos del repo)" \
            "The repo lives in ~/.config: looks are not deleted (they'd be repo files)")"
fi

# Los archivos vivos del repo son del último look con el que se hizo commit,
# no necesariamente el elegido: aplicar el look encima (como LookSwitch.sh) para
# que lo vivo y .current coincidan. Si ya hay look activo aquí, se respeta.
if ((NEW_MACHINE)) || [ ! -f "$looks_dir/.current" ]; then
  say "$(L "Look inicial" "Starting look"): $INITIAL"
  if ((DRY)); then echo "   [dry-run] copiar $looks_dir/$INITIAL/* sobre $CFG y .current = $INITIAL"
  else
    (cd "$looks_dir/$INITIAL" && find . -type f -printf '%P\n') | while read -r f; do
      mkdir -p "$(dirname "$CFG/$f")"
      cp "$looks_dir/$INITIAL/$f" "$CFG/$f"
    done
    echo "$INITIAL" > "$looks_dir/.current"
    echo 0 > "$looks_dir/.fontsize"   # lo vivo está en el tamaño del look; FontSize.py lo vuelve a aplicar
    # rofi importa este archivo (tamaño de letra, FontSize.py); vacío al empezar
    [ -f "$CFG/rofi/discada-font.rasi" ] || printf '/* FontSize.py */\n' > "$CFG/rofi/discada-font.rasi"
  fi
fi

# idioma de discada (menús, avisos, cheat sheet) y de rola
if ((NEW_MACHINE)) || [[ " $* " == *" --lang="* ]]; then
  say "$(L "Idioma: español" "Language: English")"
  if ((DRY)); then echo "   [dry-run] hypr/discada.conf → LANGUAGE=$UI_LANG"
  else
    sed -i -E "s/^LANGUAGE=[a-z]+/LANGUAGE=$UI_LANG/" "$CFG/hypr/discada.conf"
    rola_cfg="$CFG/rola/config.json"
    [ -f "$rola_cfg" ] && sed -i -E "s/\"lang\": *\"[a-z]+\"/\"lang\": \"$UI_LANG\"/" "$rola_cfg"
  fi
fi

say "$(L "yazi como explorador de carpetas por defecto" "yazi as the default folder browser")"
desk="$HOME/.local/share/applications/yazi-kitty.desktop"
if ((DRY)); then echo "   [dry-run] escribir $desk + xdg-mime default"
else
  mkdir -p "$(dirname "$desk")"
  cat > "$desk" <<EOF
[Desktop Entry]
Name=$(L "Archivos (yazi)" "Files (yazi)")
Comment=$(L "Explorador de archivos en terminal" "Terminal file manager")
Exec=kitty --class yazi -e yazi %f
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
  xdg-mime default yazi-kitty.desktop inode/directory
fi

say "rola ($(L "YouTube Music en la terminal" "YouTube Music in the terminal")) → ~/.local/bin/rola"
if ! rustup show active-toolchain >/dev/null 2>&1; then run rustup default stable; fi
run cargo install --git "$ROLA_REPO" --root "$HOME/.local" --locked
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "$(L "~/.local/bin no está en el PATH: agrégalo para correr rola" "~/.local/bin is not in PATH: add it to run rola")" ;; esac

say "$(L "Carpetas de usuario y de wallpapers" "User and wallpaper folders")"
run xdg-user-dirs-update
pics="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
run mkdir -p "$pics/wallpapers"

say "$(L Servicios Services)"
run sudo systemctl enable --now NetworkManager.service
run sudo systemctl enable --now bluetooth.service || warn "$(L "bluetooth no arrancó (¿no hay adaptador?)" "bluetooth didn't start (no adapter?)")"

say "$(L "Caché de fuentes" "Font cache")"
run fc-cache -f

# ── 5. Pantalla de login ─────────────────────────────────────────────────────
if [ "$SDDM" = yes ]; then
  say "SDDM + $(L tema theme) simple_sddm_2"
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
  say "$(L "Pantalla de login: se deja la que ya hay" "Login screen: keeping the current one")"
fi

# ── Listo ────────────────────────────────────────────────────────────────────
echo
if ((UPDATE)); then
  say "$(L "discada actualizada." "discada updated.")"
  exit 0
fi
say "$(L "Listo, discada servida. Al entrar a Hyprland por primera vez se pone un" \
        "Done, discada is served. On the first Hyprland login a wallpaper is set,")"
say "$(L "wallpaper, se generan los colores y sale un aviso con los atajos." \
        "colors are generated and a notification shows the shortcuts.")"
echo "   SUPER+H $(L atajos shortcuts) · SUPER+Shift+E $(L ajustes settings) · SUPER+T looks"
echo "   $(L "Tus wallpapers (imágenes o videos) van en" "Your wallpapers (images or videos) go in") $pics/wallpapers"
if ((!DRY)) && ((!UPDATE)) && [ -t 0 ]; then
  read -r -p "$(L "¿Reiniciar ahora? [s/N]" "Reboot now? [y/N]") " ans
  case "$ans" in s|S|y|Y) sudo systemctl reboot ;; esac
fi
