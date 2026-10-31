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
#   --no-recorder  no instalar el grabador (gpu-screen-recorder). Con una
#                NVIDIA sin su driver propietario (y sin otra GPU) no se
#                instala; con el driver, el replay no arranca solo
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
  # menús (la barra, empalme, y las notificaciones, arre, se compilan abajo)
  rofi yad
  # terminal y herramientas de terminal
  kitty fastfetch btop cava
  # taco (archivos) usa fd, fzf, zoxide y las miniaturas; nvim con LazyVim
  fd ripgrep zoxide resvg 7zip poppler ffmpegthumbnailer jq fzf udisks2 neovim
  # portapapeles, capturas y grabación (Recorder.sh)
  # (gpu-screen-recorder va aparte: depende de la GPU, ver abajo)
  wl-clipboard cliphist grim slurp swappy
  # audio (visualizador incluido). pipewire-jack y pipewire-alsa con nombre:
  # si no, pacman elige jack2 para cava/mpv/ffmpeg, que no va con PipeWire.
  # sof-firmware: sin él las laptops Intel (2019+) no tienen tarjeta de sonido
  pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack rtkit sof-firmware
  pamixer playerctl
  # wallpapers (imagen/gif con awww, antes swww) y colores
  awww imagemagick ffmpeg mpv
  # rola (YouTube Music en la terminal): audio por mpv, mpris para la barra
  yt-dlp mpv-mpris rustup
  # utilidades que usan los scripts
  libnotify libqalculate bc curl python xdg-user-dirs xdg-utils git
  # ajustes gráficos, red y bluetooth
  nwg-displays qt5ct qt6ct papirus-icon-theme adw-gtk-theme
  networkmanager bluez bluez-utils
  # fuentes base (JetBrainsMono Mono para iconos alineados, Adwaita Mono para
  # el visualizador, Noto Serif para paper); las de cada look: [font] package
  # en su look.toml
  ttf-jetbrains-mono-nerd adwaita-fonts noto-fonts noto-fonts-emoji
)
# Fuente y descripción de cada look: salen de hypr/looks/<look>/look.toml
# ([about] es/en, [font] package). Un look nuevo aparece aquí solo.
# (sin Python: en un Arch nuevo todavía puede no estar instalado)
look_get() {  # look_get LOOK SECCIÓN CLAVE
  awk -v sec="[$2]" -v key="$3" '
    /^\[/ { insec = ($0 == sec); next }
    insec && $1 == key { sub(/^[^=]*=[ \t]*"/, ""); sub(/".*$/, ""); print; exit }
  ' "$REPO_DIR/hypr/looks/$1/look.toml" 2>/dev/null
}
AUR_PKGS=(
  mpvpaper   # wallpapers de video
  wallust    # colores desde el wallpaper
  wlogout    # menú de apagado
  zen-browser-bin   # el navegador (SUPER+B)
)
SDDM_PKGS=(sddm qt6-svg qt6-declarative qt6-5compat qt6-multimedia qt6-multimedia-ffmpeg)   # el tema usa QtMultimedia (fondos de video)
# laptops (hay batería del equipo, no la de un mouse): brillo y perfiles de
# energía. power-profiles-daemon choca con tlp: si ya está tlp, se respeta
LAPTOP=0
for b in /sys/class/power_supply/*; do
  [ "$(cat "$b/type" 2>/dev/null)" = Battery ] && [ "$(cat "$b/scope" 2>/dev/null)" != Device ] && LAPTOP=1
done
LAPTOP_PKGS=(brightnessctl)
pacman -Q tlp &>/dev/null || LAPTOP_PKGS+=(power-profiles-daemon)
((LAPTOP)) && REPO_PKGS+=("${LAPTOP_PKGS[@]}")
# GPU Intel: el driver de video por hardware (VA-API). Sin él el grabador
# (gpu-screen-recorder) no encuentra codificador h264/hevc/av1. AMD ya lo trae
# en mesa y NVIDIA usa NVENC de nvidia-utils
for v in /sys/class/drm/card*/device/vendor; do
  [ "$(cat "$v" 2>/dev/null)" = 0x8086 ] && { REPO_PKGS+=(intel-media-driver vulkan-intel); break; }
done
# GPU NVIDIA: gpu-screen-recorder graba con NVENC, que solo viene con el driver
# propietario (nvidia-utils, también con nvidia-open). Con nouveau no hay
# codificador: si tampoco hay una GPU Intel o AMD que grabe, no se instala.
# Con el driver sí, pero el replay no arranca solo al iniciar sesión: tendría
# la NVIDIA codificando todo el tiempo (en una laptop no la deja dormir) y
# después de suspender deja de grabar si el driver no guarda la memoria de
# video (NVreg_PreserveVideoMemoryAllocations y los nvidia-suspend)
NVIDIA=0 OTHER_GPU=0
for v in /sys/class/drm/card*/device/vendor; do
  case "$(cat "$v" 2>/dev/null)" in
    0x10de) NVIDIA=1 ;;
    0x8086|0x1002) OTHER_GPU=1 ;;
  esac
done
NVIDIA_DRIVER=0
{ [ -d /sys/module/nvidia ] || pacman -Q nvidia-utils &>/dev/null; } && NVIDIA_DRIVER=1
RECORDER=1
((NVIDIA)) && ! ((OTHER_GPU)) && ! ((NVIDIA_DRIVER)) && RECORDER=0
SDDM_THEME_REPO="https://github.com/JaKooLit/simple-sddm-2.git"
SDDM_THEME_DIR="/usr/share/sddm/themes/simple_sddm_2"

# carpetas del repo que van a ~/.config (las mismas del whitelist de .gitignore)
CONFIG_DIRS=(hypr rofi swaync wallust kitty cava btop fastfetch wlogout rola sddm Kvantum qt5ct qt6ct swappy)
ROLA_REPO="https://github.com/daniiiqa/rola.git"
VATO_REPO="https://github.com/daniiiqa/vato.git"
ARRE_REPO="https://github.com/daniiiqa/arre.git"
TACO_REPO="https://github.com/daniiiqa/taco.git"
EMPALME_REPO="https://github.com/daniiiqa/empalme.git"
LAZYVIM_STARTER="https://github.com/LazyVim/starter"
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
    --no-recorder) RECORDER=0 ;;
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
  --no-recorder  don't install the screen recorder (gpu-screen-recorder).
               With an NVIDIA card and no proprietary driver (and no other
               GPU) it's skipped; with the driver, replay doesn't autostart
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

[ "$SDDM" = auto ] && ((UPDATE)) && SDDM=no   # actualizar no toca la pantalla de login (salvo --sddm)
if [ "$SDDM" = auto ]; then
  # si ya hay SDDM (CachyOS lo trae) se le pone el tema de discada; otro
  # display manager se respeta
  dm=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)
  if [[ "$dm" == */sddm.service ]] || ! systemctl is-enabled display-manager.service >/dev/null 2>&1; then SDDM=yes
  else SDDM=no; fi
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
    desc=$(look_get "$l" about "$UI_LANG")
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
  p=$(look_get "$l" font package)
  [ -n "$p" ] && ! in_list "$p" "${LOOK_PKGS[@]}" && LOOK_PKGS+=("$p")
done
say "Looks: ${LOOKS[*]} ($(L "empieza en" "starting with") $INITIAL)"

# ── Tus cambios: qué toca la actualización ──────────────────────────────────
# Lo que cambiaste en ~/.config desde la última instalación (REV_FILE, o el
# commit de antes del git pull): si discada no lo cambió se queda lo tuyo; si
# los dos lo cambiaron se reemplaza y lo tuyo va al respaldo. Se pregunta
# antes de tocar nada (hypr/scripts/UpdateCheck.py)
REV_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/discada/rev"
KEEP_MINE=() REPLACE_MINE=()
if ((UPDATE)) && ((NEW_MACHINE)); then
  base=$(cat "$REV_FILE" 2>/dev/null || true)
  git -C "$REPO_DIR" cat-file -e "${base:-x}^{commit}" 2>/dev/null ||
    base=$(git -C "$REPO_DIR" rev-parse -q --verify 'HEAD@{1}' 2>/dev/null || git -C "$REPO_DIR" rev-parse -q --verify ORIG_HEAD 2>/dev/null || true)
  if [ -n "$base" ] && command -v python3 >/dev/null; then
    while IFS=$'\t' read -r what rel; do
      case "$what" in
        keep) KEEP_MINE+=("$rel") ;;
        replace) REPLACE_MINE+=("$rel") ;;
      esac
    done < <(python3 "$REPO_DIR/hypr/scripts/UpdateCheck.py" "$REPO_DIR" "$base" 2>/dev/null)
  fi
  if ((${#KEEP_MINE[@]})); then
    say "$(L "Archivos que cambiaste y que la actualización no toca (se quedan como los tienes):" \
            "Files you changed that the update doesn't touch (they stay as you have them):")"
    printf '   %s\n' "${KEEP_MINE[@]}"
  fi
  if ((${#REPLACE_MINE[@]})); then
    warn "$(L "Archivos que cambiaste y que la actualización reemplaza (tu versión va a $BACKUP):" \
             "Files you changed that the update replaces (your version goes to $BACKUP):")"
    printf '   %s\n' "${REPLACE_MINE[@]}"
    if [ -t 0 ] && ((${#YES[@]} == 0)) && ! ((DRY)); then
      read -r -p "   $(L "¿Seguir con la actualización? [S/n]" "Continue with the update? [Y/n]") " ans
      case "$ans" in n|N|no|No) say "$(L "Actualización cancelada: no se tocó nada en ~/.config" "Update cancelled: nothing in ~/.config was touched")"; exit 1 ;; esac
    fi
  fi
fi

# ── 1. Paquetes de los repos ─────────────────────────────────────────────────
# el grabador: al actualizar, solo si ya estaba (si lo quitaste, no vuelve)
if ((UPDATE)) && ! pacman -Q gpu-screen-recorder &>/dev/null; then RECORDER=0; fi
((RECORDER)) && REPO_PKGS+=(gpu-screen-recorder)
if ((NVIDIA)) && ! ((UPDATE)); then
  if ((RECORDER)); then
    warn "$(L "NVIDIA: el grabador se instala, pero el replay no arranca solo (ALT+Shift+F10 lo prende)" \
              "NVIDIA: the recorder is installed, but replay won't autostart (ALT+Shift+F10 turns it on)")"
  elif ! ((NVIDIA_DRIVER)); then
    warn "$(L "NVIDIA sin driver propietario: sin grabador de pantalla (instala nvidia-utils y corre esto otra vez)" \
              "NVIDIA without the proprietary driver: no screen recorder (install nvidia-utils and run this again)")"
  fi
fi
say "$(L "Paquetes de los repos oficiales" "Official repo packages") (${#REPO_PKGS[@]} + ${#LOOK_PKGS[@]} $(L "fuentes de looks" "look fonts"))"
if ((UPDATE)); then
  # solo lo que falte (paquetes nuevos de discada o de un look)
  mapfile -t missing < <(pacman -T "${REPO_PKGS[@]}" "${LOOK_PKGS[@]}" 2>/dev/null)
  if ((${#missing[@]})); then run sudo pacman -Syu --needed --ask=4 "${YES[@]}" "${missing[@]}"
  else echo "   $(L "nada nuevo que instalar" "nothing new to install")"; fi
else
  # --ask=4: si ya estaba jack2, cambiarlo por pipewire-jack sin abortar
  run sudo pacman -Syu --needed --ask=4 "${YES[@]}" "${REPO_PKGS[@]}" "${LOOK_PKGS[@]}"
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
  warn "$(L "Saltando AUR: sin mpvpaper/wallust no hay wallpapers de video ni colores dinámicos" \
            "Skipping AUR: without mpvpaper/wallust there are no video wallpapers or dynamic colors")"
fi

# ── 3. Dotfiles ──────────────────────────────────────────────────────────────
if ((NEW_MACHINE)); then
  say "$(L "Copiando dotfiles a $CFG (lo que se pise va a $BACKUP)" "Copying dotfiles to $CFG (anything overwritten goes to $BACKUP)")"
  # Hyprland lee hyprland.lua antes que hyprland.conf: con la config Lua de
  # la distro (CachyOS, que arranca noctalia desde ahí) discada nunca cargaría
  # (el de discada empieza con "-- discada": ese se queda)
  if [ -f "$CFG/hypr/hyprland.lua" ] && ! head -n1 "$CFG/hypr/hyprland.lua" | grep -q '^-- discada'; then
    say "$(L "Apartando la config Lua de Hyprland (hyprland.lua y config/) a $BACKUP/hypr" \
            "Moving the Hyprland Lua config (hyprland.lua and config/) to $BACKUP/hypr")"
    run mkdir -p "$BACKUP/hypr"
    run mv "$CFG/hypr/hyprland.lua" "$BACKUP/hypr/"
    [ -d "$CFG/hypr/config" ] && run mv "$CFG/hypr/config" "$BACKUP/hypr/"
  fi
  for f in "${REPLACE_MINE[@]}"; do
    [ -e "$CFG/$f" ] || continue
    run mkdir -p "$BACKUP/$(dirname "$f")"
    run cp -a "$CFG/$f" "$BACKUP/$f"
  done
  mine=""
  if ((${#KEEP_MINE[@]})) && ! ((DRY)); then
    # sin el tamaño de letra de discada (Update.sh lo vuelve a aplicar a todo)
    [ -x "$CFG/hypr/scripts/FontSize.py" ] && python3 "$CFG/hypr/scripts/FontSize.py" unapply
    mine=$(mktemp -d)
    for f in "${KEEP_MINE[@]}"; do
      [ -e "$CFG/$f" ] && { mkdir -p "$mine/$(dirname "$f")"; cp -a "$CFG/$f" "$mine/$f"; }
    done
  fi
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
      if ((UPDATE)) && [ -e "$CFG/$rel" ] && in_list "$rel" "${KEEP_ON_UPDATE[@]}" "${KEEP_MINE[@]}"; then
        continue
      fi
      if [ -e "$CFG/$rel" ] && ! cmp -s "$f" "$CFG/$rel"; then
        run mkdir -p "$BACKUP/$(dirname "$rel")"
        run cp -a "$CFG/$rel" "$BACKUP/$rel"
      fi
    done < <(find "$REPO_DIR/$d" -type f -print0)
    run mkdir -p "$CFG/$d"
    # --remove-destination: por si hay archivos de solo lectura
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

  # NVIDIA o sin grabador: que el replay no arranque al iniciar sesión
  if ! ((UPDATE)) && { ((NVIDIA)) || ! ((RECORDER)); }; then
    if ((DRY)); then echo "   [dry-run] recorder.conf → REPLAY_ON_STARTUP=no"
    else sed -i 's/^REPLAY_ON_STARTUP=yes/REPLAY_ON_STARTUP=no /' "$CFG/hypr/recorder.conf"; fi
  fi

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
# el look: sus archivos con su fuente, sus colores y su estilo (LookBuild.py,
# desde su look.toml). Al actualizar también se vuelve a aplicar el que ya
# tenías: sus archivos pueden traer cambios
look=$INITIAL
if ! ((NEW_MACHINE)) && [ -f "$looks_dir/.current" ]; then
  cur=$(cat "$looks_dir/.current")
  in_list "$cur" "${LOOKS[@]}" && look=$cur
fi
say "$(L "Look" "Look"): $look"
if ((DRY)); then echo "   [dry-run] LookBuild.py apply $look y .current = $look"
else
  python3 "$CFG/hypr/scripts/LookBuild.py" apply "$look"
  echo "$look" > "$looks_dir/.current"
  echo 0 > "$looks_dir/.fontsize"   # lo vivo está en el tamaño del look; FontSize.py lo vuelve a aplicar
  # rofi importa este archivo (tamaño de letra, FontSize.py); vacío al empezar
  [ -f "$CFG/rofi/discada-font.rasi" ] || printf '/* FontSize.py */\n' > "$CFG/rofi/discada-font.rasi"
fi
# lo tuyo que discada no cambió, de vuelta (encima de la copia y del look)
if [ -n "${mine:-}" ]; then
  cp -a "$mine/." "$CFG/" && rm -rf "$mine"
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

say "$(L "taco como explorador de carpetas por defecto" "taco as the default folder browser")"
desk="$HOME/.local/share/applications/taco.desktop"
if ((DRY)); then echo "   [dry-run] escribir $desk + xdg-mime default"
else
  mkdir -p "$(dirname "$desk")"
  cat > "$desk" <<EOF
[Desktop Entry]
Name=$(L "Archivos (taco)" "Files (taco)")
Comment=$(L "Explorador de archivos en terminal" "Terminal file manager")
Exec=kitty --class taco -e taco %f
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
  xdg-mime default taco.desktop inode/directory
fi

# Zen como navegador por defecto (enlaces, SUPER+B, "abrir en el navegador")
if [ -e /usr/share/applications/zen.desktop ] || ((DRY)); then
  say "$(L "Zen como navegador por defecto" "Zen as the default browser")"
  run xdg-settings set default-web-browser zen.desktop
  run xdg-mime default zen.desktop x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
fi

say "rola ($(L "YouTube Music en la terminal" "YouTube Music in the terminal")) → ~/.local/bin/rola"
if ! rustup show active-toolchain >/dev/null 2>&1; then run rustup default stable; fi
run cargo install --git "$ROLA_REPO" --root "$HOME/.local" --locked
say "vato ($(L "audio, bluetooth, red y sistema en la terminal" "audio, bluetooth, network and system in the terminal")) → ~/.local/bin/vato"
run cargo install --git "$VATO_REPO" --root "$HOME/.local" --locked
say "arre ($(L "las notificaciones con el look de discada" "notifications with the discada look")) → ~/.local/bin/arre"
run cargo install --git "$ARRE_REPO" --root "$HOME/.local" --locked
say "taco ($(L "los archivos con el look de discada" "files with the discada look")) → ~/.local/bin/taco"
run cargo install --git "$TACO_REPO" --root "$HOME/.local" --locked
say "empalme ($(L "la barra de discada" "the discada bar")) → ~/.local/bin/empalme"
run cargo install --git "$EMPALME_REPO" --root "$HOME/.local" --locked

# nvim: si no hay config, el starter de LazyVim; luego el colorscheme de
# discada (sigue al look; vive en hypr/nvim/). Del resto de tu config no se
# toca nada.
say "nvim (LazyVim) $(L "con el look de discada" "with the discada look")"
nvim_dir="$CFG/nvim"
if [ ! -e "$nvim_dir/init.lua" ] && [ ! -e "$nvim_dir/init.vim" ]; then
  run git clone --depth 1 "$LAZYVIM_STARTER" "$nvim_dir" && run rm -rf "$nvim_dir/.git"
fi
nvim_files=(colors/discada.lua lua/discada.lua)
# el spec que lo pone como colorscheme solo tiene sentido con LazyVim
if ((DRY)) || [ -e "$nvim_dir/lazyvim.json" ] || grep -qs LazyVim "$nvim_dir/lua/config/lazy.lua"; then
  nvim_files+=(lua/plugins/discada.lua)
fi
for f in "${nvim_files[@]}"; do
  run mkdir -p "$nvim_dir/$(dirname "$f")"
  run cp "$REPO_DIR/hypr/nvim/$f" "$nvim_dir/$f"
done
# D-Bus lo arranca cuando llega la primera notificación (las de tu usuario
# ganan a las de /usr/share: si hay otro daemon instalado, gana arre)
dbus_dir="$HOME/.local/share/dbus-1/services"
if ((DRY)); then echo "   [dry-run] $dbus_dir/org.freedesktop.Notifications.service + org.discada.Arre.service"
else
  mkdir -p "$dbus_dir"
  for name in org.freedesktop.Notifications org.discada.Arre; do
    printf '[D-BUS Service]\nName=%s\nExec=%s\n' "$name" "$HOME/.local/bin/arre" > "$dbus_dir/$name.service"
  done
fi
# ~/.local/bin en el PATH (rola, vato, arre, taco y empalme viven ahí): en el perfil de
# login, que SDDM lee al entrar a Hyprland. En un Arch nuevo no viene
path_line='[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"  # discada'
for prof in "$HOME/.bash_profile" "$HOME/.zprofile"; do
  [ "$prof" = "$HOME/.zprofile" ] && [ ! -e "$prof" ] && [[ "$SHELL" != */zsh ]] && continue
  grep -qs '# discada$' "$prof" && continue
  if ((DRY)); then echo "   [dry-run] ~/.local/bin → PATH en $prof"; else printf '\n%s\n' "$path_line" >> "$prof"; fi
done
export PATH="$HOME/.local/bin:$PATH"

# fastfetch al abrir una terminal (con la config del look)
ff_line='[[ $- == *i* ]] && command -v fastfetch >/dev/null && fastfetch  # discada'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ "$rc" = "$HOME/.zshrc" ] && [ ! -e "$rc" ] && [[ "$SHELL" != */zsh ]] && continue
  grep -qs 'fastfetch' "$rc" && continue
  if ((DRY)); then echo "   [dry-run] fastfetch en $rc"; else printf '\n%s\n' "$ff_line" >> "$rc"; fi
done

say "$(L "Carpetas de usuario y de wallpapers" "User and wallpaper folders")"
run xdg-user-dirs-update
pics="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
run mkdir -p "$pics/wallpapers"

say "$(L Servicios Services)"
run sudo systemctl enable --now NetworkManager.service
run sudo systemctl enable --now bluetooth.service || warn "$(L "bluetooth no arrancó (¿no hay adaptador?)" "bluetooth didn't start (no adapter?)")"
if ((LAPTOP)) && in_list power-profiles-daemon "${LAPTOP_PKGS[@]}"; then
  run sudo systemctl enable --now power-profiles-daemon.service
fi

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
    # otro tema puesto en /etc/sddm.conf (se lee al último) o en un archivo
    # que va después ganaría: se comenta (queda .discada-bak)
    for f in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
      [ -f "$f" ] && [ "$f" != /etc/sddm.conf.d/theme.conf ] || continue
      grep -q '^Current=' "$f" && sudo sed -i.discada-bak 's/^Current=/#Current=/' "$f"
    done
  fi
  # con --sddm sobre otro display manager (CachyOS con noctalia usa greetd):
  # apagar ese o el alias display-manager.service no deja activar SDDM
  # (solo si existe: readlink -f de una ruta que no existe la regresa igual)
  dm=""
  [ -L /etc/systemd/system/display-manager.service ] && dm=$(readlink -f /etc/systemd/system/display-manager.service)
  if [ -n "$dm" ] && [[ "$dm" != */sddm.service ]]; then
    run sudo systemctl disable "$(basename "$dm")"
  fi
  run sudo systemctl enable sddm.service
else
  say "$(L "Pantalla de login: se deja la que ya hay" "Login screen: keeping the current one")"
fi

# ── Listo ────────────────────────────────────────────────────────────────────
# la versión instalada: la próxima actualización compara tus archivos con ella
if ((NEW_MACHINE)) && ! ((DRY)); then
  mkdir -p "$(dirname "$REV_FILE")"
  git -C "$REPO_DIR" rev-parse HEAD > "$REV_FILE" 2>/dev/null || true
fi
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
