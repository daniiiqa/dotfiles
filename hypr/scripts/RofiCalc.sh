#!/usr/bin/env bash
# Calculadora: qalc + rofi. El resultado se copia al portapapeles.

rofi_theme="$HOME/.config/rofi/config-calc.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# main function

while true; do
    result=$(
        rofi -i -dmenu -p calc \
            -config $rofi_theme \
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
