#!/usr/bin/env bash
# Script for changing blurs on the fly

. "$HOME/.config/hypr/scripts/lang.sh"
H="$HOME/.config/hypr/scripts/Hypr.sh"

STATE=$("$H" get decoration:blur:passes)

if [ "${STATE}" == "2" ]; then
	"$H" set decoration:blur:size 2 decoration:blur:passes 1
	notify-send -e -u low -a discada -i "preferences-system-notifications-symbolic" "Blur: $(L ligero light)"
else
	"$H" set decoration:blur:size 5 decoration:blur:passes 2
	notify-send -e -u low -a discada -i "preferences-system-notifications-symbolic" "Blur: normal"
fi
