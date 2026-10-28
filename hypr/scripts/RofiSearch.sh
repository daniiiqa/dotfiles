#!/usr/bin/env bash
# For Searching via web browsers

if ! command -v jq >/dev/null 2>&1; then
    notify-send -u low "Rofi Search" "jq is required for URL encoding. Please install jq."
    exit 1
fi

# el buscador sale de hypr/conf/defaults (.lua o .conf)
eval "$("$HOME/.config/hypr/scripts/Hypr.sh" defaults)"
Search_Engine=$search_engine
if [[ -z "$Search_Engine" ]]; then
    echo "Error: search_engine is not set in hypr/conf/defaults"
    exit 1
fi

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='opens in your default browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Open Rofi and pass the selected query to xdg-open for the configured search engine
query=$(printf '' | rofi -dmenu -p search -config "$rofi_theme" -mesg "$msg")

if [[ -z "$query" ]]; then
    exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
xdg-open "${Search_Engine}${encoded_query}" >/dev/null 2>&1 &
