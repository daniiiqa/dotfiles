#!/usr/bin/env bash
# Custom (dany): jale (el launcher, antes rofi) vive en ~/.local/bin,
# fuera del PATH de Hyprland
PATH="$HOME/.local/bin:$PATH"
# Calculadora: qalc + rofi. El resultado se copia al portapapeles.

jale_theme="$HOME/.config/jale/config-calc.rasi"

# Kill Rofi if already running before execution
if pgrep -x "jale" >/dev/null; then
    pkill -x jale
fi

# main function

while true; do
    result=$(
        jale -dmenu -p calc \
            -config $jale_theme \
            -mesg "${result:+$result  =  $calc_result  (copied)}${result:-enter to calculate · result is copied}"
    )

    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -n "$result" ]; then
        calc_result=$(qalc -t "$result")
        echo "$calc_result" | wl-copy
    fi
done
