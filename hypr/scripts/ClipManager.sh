#!/usr/bin/env bash
# Custom (dany): jale (el launcher, antes rofi) vive en ~/.local/bin,
# fuera del PATH de Hyprland
PATH="$HOME/.local/bin:$PATH"
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Variables
jale_theme="$HOME/.config/jale/config-clipboard.rasi"
msg='enter: copy  ·  ctrl+del: delete  ·  alt+del: wipe all'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Check if rofi is already running
if pidof jale > /dev/null; then
  pkill -x jale
fi

while true; do
    result=$(
        jale -dmenu -p clipboard \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -config $jale_theme < <(cliphist list) \
			-mesg "$msg" 
    )

    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<<"$result"
            ;;
        11)
            cliphist wipe
            ;;
    esac
done

