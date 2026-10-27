#!/usr/bin/env bash
# Brillo de la pantalla y del teclado (laptops) con brightnessctl.
#   Brightness.sh --inc | --dec            pantalla, de 5 en 5 (curva exponencial)
#   Brightness.sh --inc-precise | --dec-precise   de 1 en 1
#   Brightness.sh --kbd-inc | --kbd-dec    luz del teclado
#   Brightness.sh --waybar                 JSON para custom/backlight
#   Brightness.sh --idle-dim | --idle-restore     lo llama hypridle
#   Brightness.sh --has                    sale con 0 si hay pantalla con brillo

sDIR="$HOME/.config/hypr/scripts"
iDIR="$HOME/.config/swaync/images"
. "$sDIR/lang.sh"

has_backlight() { compgen -G "/sys/class/backlight/*" >/dev/null; }
kbd_dev() { brightnessctl -l -m -c leds 2>/dev/null | cut -d, -f1 | grep -m1 kbd_backlight; }

get_pct() { brightnessctl -m -c backlight 2>/dev/null | cut -d, -f4 | tr -d '%'; }

refresh_bar() { pkill -RTMIN+12 -x waybar; }

notify_user() {
  local level; level=$(get_pct)
  notify-send -e -h int:value:"$level" -h string:x-canonical-private-synchronous:brightness_notif \
    -h boolean:SWAYNC_BYPASS_DND:true -u low -a discada -i "$iDIR/bell.png" \
    "$(L "Brillo" "Brightness")" "${level}%"
  refresh_bar
}

need() {
  command -v brightnessctl >/dev/null && return 0
  notify-send -i "$iDIR/error.png" "$(L "Falta brightnessctl" "brightnessctl is missing")" "sudo pacman -S brightnessctl"
  exit 1
}

screen() {
  has_backlight || exit 0
  need
  # nunca hasta 0: con algunas pantallas 0 es apagada
  brightnessctl -q -c backlight -e --min-value=1 set "$1" && notify_user
}

kbd() {
  need
  local dev; dev=$(kbd_dev)
  [ -n "$dev" ] || exit 0
  brightnessctl -q -d "$dev" set "$1"
  local pct; pct=$(brightnessctl -m -d "$dev" | cut -d, -f4 | tr -d '%')
  notify-send -e -h int:value:"$pct" -h string:x-canonical-private-synchronous:kbd_notif \
    -u low -a discada -i "$iDIR/bell.png" "$(L "Luz del teclado" "Keyboard light")" "${pct}%"
}

waybar() {
  has_backlight && command -v brightnessctl >/dev/null || { echo; exit 0; }
  local pct; pct=$(get_pct)
  printf '{"text": "%s", "percentage": %s, "tooltip": "%s %s%%\\n\\n%s"}\n' \
    "$pct" "$pct" "$(L "Brillo" "Brightness")" "$pct" \
    "$(L "Rueda: subir o bajar · clic: 100% · clic derecho: 30%" "Wheel: up or down · click: 100% · right click: 30%")"
}

case "$1" in
  --inc)          screen +5% ;;
  --dec)          screen 5%- ;;
  --inc-precise)  screen +1% ;;
  --dec-precise)  screen 1%- ;;
  --set)          screen "$2" ;;
  --kbd-inc)      kbd +1 ;;
  --kbd-dec)      kbd 1- ;;
  --waybar)       waybar ;;
  # -s guarda el brillo actual, -r lo devuelve; solo baja si estaba más alto
  --idle-dim)
    has_backlight && [ "$(get_pct)" -gt 15 ] || exit 0
    mkdir -p "$XDG_RUNTIME_DIR/discada" && touch "$XDG_RUNTIME_DIR/discada/dimmed"
    brightnessctl -q -s -c backlight set 10% ;;
  --idle-restore)
    rm "$XDG_RUNTIME_DIR/discada/dimmed" 2>/dev/null || exit 0
    brightnessctl -q -r -c backlight; refresh_bar ;;
  --has)          has_backlight ;;
  *)              get_pct ;;
esac
