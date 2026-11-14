#!/usr/bin/env bash
# Custom (dany): la entrada de discada, el "boot" del rice. Al iniciar sesión
# el telón (farula) tapa todo con un saludo sobre tu wallpaper borroso (el
# saludo según la hora, el día, el look y una frase del motd) mientras todo
# carga por debajo; luego suena la campanita, el telón se abre con el efecto
# del look y en cascada entran la barra (deslizándose), el barrido del
# teclado (chispa saludo), tus notas y los bichos.
#
# ENTRADA en hypr/discada.conf (menú SUPER+Shift+E): yes | quiet (sin
# sonido) | no. El sonido es hypr/sounds/entrada.ogg, o el del look si trae
# uno (hypr/looks/<look>/entrada.ogg). Las frases: Motd.sh (de lo que traes:
# Steam, rola, tus repos, el día) o hypr/motd/<idioma>.txt.
#
#   Entrada.sh inicio             startup.lua, lo primero
#   Entrada.sh luego S CMD…       startup.lua: CMD entra S segundos después de
#                                 abrir el telón (o a los 8 s, pase lo que pase)
#   Entrada.sh imagen [SALIDA]    el telón con el saludo (PPM); imprime la ruta
#   Entrada.sh revelar            sonido, abrir, barrido, y que entren los demás
#   Entrada.sh demo               para verla sin cerrar sesión
#   Entrada.sh activa             sale con 0 si la entrada está prendida
#
# Con autologin el candado hace de login (LockScreen.sh inicio): ahí la
# entrada es al quitarlo, y LockScreen.sh usa `imagen` y `revelar`.

PATH="$HOME/.local/bin:$PATH"
hypr="$HOME/.config/hypr"
scripts="$hypr/scripts"
. "$scripts/lang.sh"
run="${XDG_RUNTIME_DIR:-/tmp}"
lista="$run/discada-entrada-${HYPRLAND_INSTANCE_SIGNATURE:-sesion}.lista"

modo=$(sed -nE 's/^ENTRADA=([a-z]+).*/\1/p' "$hypr/discada.conf" 2>/dev/null | head -n1)
modo=${modo:-yes}
activa() { [ "$modo" != no ] && command -v farula >/dev/null && [ ! -e "$hypr/farula.off" ]; }
autologin() { [ "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value 2>/dev/null)" = sddm-autologin ]; }
listo() { : > "$lista"; }

# ── el telón con el saludo ────────────────────────────────────────────────────
imagen() {
  local out="${1:-$run/discada-entrada.ppm}"
  local wall="$hypr/wallpaper_effects/.wallpaper_current"
  [ -f "$wall" ] || return 1
  local geo
  geo=$(hyprctl monitors -j 2>/dev/null | jq -r '([.[] | select(.focused)] + .)[0] | "\(.width)x\(.height)"')
  [[ $geo =~ ^[0-9]+x[0-9]+$ ]] || geo=1920x1080
  local h=${geo#*x}

  # los colores del look: el theme de kitty que pone leña
  local theme
  theme=$(sed -nE 's/^include +([^ #]+).*/\1/p' "$HOME/.config/kitty/kitty.conf" | while read -r p; do
    p="${p/#\~/$HOME}"; [[ $p == /* ]] || p="$HOME/.config/kitty/$p"
    grep -q '^background' "$p" 2>/dev/null && echo "$p"; done | tail -n1)
  col() { awk -v k="$1" '$1 == k { print $2; exit }' "$theme" 2>/dev/null; }
  local fg acc mut
  fg=$(col foreground); acc=$(col color12); mut=$(col color7)
  fg=${fg:-#eeeeee}; acc=${acc:-$fg}; mut=${mut:-$fg}

  # las fuentes del look: la de mostrar para lo grande, la de siempre para lo chico
  local look toml fam disp
  look=$(cat "$hypr/looks/.current" 2>/dev/null)
  toml="$hypr/looks/$look/look.toml"
  fam=$(sed -nE '/^\[font\]/,/^\[/ s/^family *= *"([^"]+)".*/\1/p' "$toml" 2>/dev/null | head -n1)
  disp=$(sed -nE '/^\[font\]/,/^\[/ s/^display *= *"([^"]+)".*/\1/p' "$toml" 2>/dev/null | head -n1)
  fam=${fam:-sans}; disp=${disp:-$fam}
  local f_big f_small
  f_big=$(fc-match -f '%{file}' "$disp:style=Regular")
  f_small=$(fc-match -f '%{file}' "$fam:style=Regular")

  # lo que dice
  local hour hola dias meses fecha motd
  hour=$((10#$(date +%H)))
  if   ((hour < 5));  then hola=$(L "ya duérmete, $USER" "go to sleep, $USER")
  elif ((hour < 12)); then hola=$(L "buenos días, $USER" "good morning, $USER")
  elif ((hour < 19)); then hola=$(L "buenas tardes, $USER" "good afternoon, $USER")
  else                     hola=$(L "buenas noches, $USER" "good evening, $USER"); fi
  if [ "$DISCADA_LANG" = es ]; then
    dias=(domingo lunes martes miércoles jueves viernes sábado)
    meses=(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)
    fecha="${dias[$(date +%w)]} $((10#$(date +%d))) de ${meses[$((10#$(date +%m) - 1))]}"
  else
    dias=(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    meses=(January February March April May June July August September October November December)
    fecha="${dias[$(date +%w)]}, ${meses[$((10#$(date +%m) - 1))]} $((10#$(date +%d)))"
  fi
  fecha="$fecha   ·   $look"
  # el motd: juguetón, de lo que traes ahorita (Motd.sh), o uno de hypr/motd
  motd=$("$scripts/Motd.sh" --guardar 2>/dev/null)

  # el wallpaper borroso y oscuro (más en las orillas), y el texto al centro
  local big=$((h * 7 / 100)) mid=$((h * 26 / 1000)) small=$((h * 18 / 1000))
  local args=(
    -gravity center
    -font "$f_big" -pointsize "$big" -fill "$fg" -annotate "+0-$((h * 4 / 100))" "$hola"
  )
  # el motd en la fuente de siempre (las cursivas de algunas fuentes vienen
  # incompletas: a la de Terminess le faltan letras) y sin comillas, que no
  # todas traen
  [ -n "$motd" ] && args+=(-font "$f_big" -pointsize "$mid" -fill "$acc" -annotate "+0+$((h * 4 / 100))" "$motd")
  args+=(-font "$f_small" -pointsize "$small" -fill "$mut" -annotate "+0+$((h * 10 / 100))" "$fecha")
  magick "${wall}[0]" -resize "${geo}^" -gravity center -extent "$geo" \
    -resize 25% -blur 0x10 -resize "${geo}!" -evaluate multiply 0.55 \
    \( -size "$geo" radial-gradient:'rgba(0,0,0,0)-rgba(0,0,0,0.6)' \) -compose over -composite \
    "${args[@]}" "ppm:$out" 2>/dev/null && echo "$out"
}

# ── abrir ────────────────────────────────────────────────────────────────────
revelar() {
  if [ "$modo" = yes ]; then
    local look snd
    look=$(cat "$hypr/looks/.current" 2>/dev/null)
    snd="$hypr/looks/$look/entrada.ogg"
    [ -f "$snd" ] || snd="$hypr/sounds/entrada.ogg"
    [ -f "$snd" ] && { pw-play --volume 0.8 "$snd" || paplay "$snd"; } >/dev/null 2>&1 &
  fi
  # la barra entra deslizándose solo esta vez: siempre va sin animación (al
  # recargar vuelve al instante, ver windowrules.lua); en 2 s, como estaba
  hyprctl eval 'hl.layer_rule({ match = { namespace = "empalme" }, no_anim = false, animation = "slide top" })' >/dev/null 2>&1
  ( sleep 2; hyprctl eval 'hl.layer_rule({ match = { namespace = "empalme" }, no_anim = true })' ) >/dev/null 2>&1 &
  sleep 0.12   # que la campanita llegue con el telón
  farula reveal >/dev/null 2>&1
  listo
  ( sleep 0.3; chispa saludo ) >/dev/null 2>&1 &
}

case "${1:-}" in
  inicio)
    if ! activa || autologin; then
      # con autologin la entrada es al quitar el candado (LockScreen.sh)
      autologin && activa || listo
      exit 0
    fi
    img=$(imagen) || { listo; exit 0; }
    # sin --hold: si algo se cae aquí, el telón se abre solo a los 15 s
    farula freeze --image "$img" || { listo; exit 0; }
    # que todo cargue por debajo: el wallpaper ya puesto (awww) y un respiro
    for _ in $(seq 1 30); do awww query 2>/dev/null | grep -q 'image:' && break; sleep 0.1; done
    sleep 1.4
    revelar
    ;;
  luego)
    d=${2:-0}; shift 2
    if activa && [ ! -e "$lista" ]; then
      n=0
      while [ ! -e "$lista" ]; do
        sleep 0.1
        # con el candado puesto (autologin) se espera lo que dure; si no, 8 s
        pidof hyprlock chapa >/dev/null || n=$((n + 1))
        ((n >= 80)) && break
      done
      sleep "$d"
    fi
    exec "$@"
    ;;
  imagen) imagen "${2:-}" ;;
  activa) activa ;;
  revelar) revelar ;;
  demo)
    img=$(imagen) || exit 1
    farula freeze --image "$img" || exit 1
    pkill -USR1 -x empalme   # la barra se esconde bajo el telón…
    sleep 1.8
    revelar
    sleep 0.15
    pkill -USR1 -x empalme   # …y entra
    ;;
  *) sed -n '2,25p' "$0"; exit 1 ;;
esac
