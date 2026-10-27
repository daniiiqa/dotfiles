#!/usr/bin/env bash
# Scripts for volume controls for audio and mic 

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"
. "$sDIR/lang.sh"

# un aviso que se reemplaza a sí mismo (volumen y micrófono comparten lugar)
note() {  # ícono, título, [nivel]
    notify-send -e -a discada -u low -h string:x-canonical-private-synchronous:volume_notif \
        -h boolean:SWAYNC_BYPASS_DND:true ${3:+-h int:value:$3} -i "$1" "$2"
}

# Get Volume
get_volume() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "Muted"
        return
    fi

    local volume
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq 0 ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# Get icons
get_icon() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "audio-volume-muted-symbolic"
        return
    fi

    current=$(pamixer --get-volume)
    if [[ "$current" -le 30 ]]; then
        echo "audio-volume-low-symbolic"
    elif [[ "$current" -le 60 ]]; then
        echo "audio-volume-medium-symbolic"
    else
        echo "audio-volume-high-symbolic"
    fi
}

# Notify
notify_user() {
    local muted="$(pamixer --get-mute)"
    local level="$(pamixer --get-volume)"

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        note "$(get_icon)" "$(L "Volumen: silenciado" "Volume: muted")"
    else
        note "$(get_icon)" "$(L Volumen Volume)" "$level" && "$sDIR/Sounds.sh" --volume
    fi
}

# Increase Volume
inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -i "$1" --allow-boost --set-limit 150 && notify_user
    fi
}

# Decrease Volume
dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -d "$1" && notify_user
    fi
}

# Toggle Mute
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m && notify_user
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify_user
	fi
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m && notify_mic_user
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer --default-source -u && notify_mic_user
	fi
}
# Get Mic Icon
get_mic_icon() {
    local muted="$(pamixer --default-source --get-mute)"
    local current="$(pamixer --default-source --get-volume)"
    if [[ "$muted" == "true" || "$current" -eq "0" ]]; then
        echo "microphone-disabled-symbolic"
    else
        echo "audio-input-microphone-symbolic"
    fi
}

# Get Microphone Volume
get_mic_volume() {
    if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
        echo "Muted"
        return
    fi

    local volume
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq 0 ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# Notify for Microphone
notify_mic_user() {
    local muted="$(pamixer --default-source --get-mute)"
    local level="$(pamixer --default-source --get-volume)"
    local icon message

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        icon="microphone-disabled-symbolic"
        note "$icon" "$(L "Micrófono: silenciado" "Microphone: muted")"
    else
        icon="audio-input-microphone-symbolic"
        note "$icon" "$(L Micrófono Microphone)" "$level"
    fi
}

# Increase MIC Volume
inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -i 5 && notify_mic_user
    fi
}

# Decrease MIC Volume
dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -d 5 && notify_mic_user
    fi
}

# Execute accordingly
case "$1" in
"--get")
  get_volume
  ;;
"--inc")
  inc_volume 5
  ;;
"--inc-precise")
  inc_volume 1
  ;;
"--dec")
  dec_volume 5
  ;;
"--dec-precise")
  dec_volume 1
  ;;
"--toggle")
  toggle_mute
  ;;
"--toggle-mic")
  toggle_mic
  ;;
"--get-icon")
  get_icon
  ;;
"--get-mic-icon")
  get_mic_icon
  ;;
"--mic-inc")
  inc_mic_volume
  ;;
"--mic-dec")
  dec_mic_volume
  ;;
*)
  get_volume
  ;;
esac
