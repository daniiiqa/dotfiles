#!/usr/bin/env bash
# Custom (dany) — silent SDDM wallpaper + colors sync.
# Called from WallustSwww.sh after wallust regenerates colors, so SDDM
# always matches the current wallpaper. No sudo needed: the simple_sddm_2
# theme files are owned by this user. Safe to run anytime; exits quietly
# if anything is missing or not writable.

wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
rofi_wallust="$HOME/.config/rofi/wallust/colors-rofi.rasi"

# Resolve SDDM themes directory (standard paths and NixOS path)
sddm_themes_dir="/usr/share/sddm/themes"
if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
fi
sddm_simple="$sddm_themes_dir/simple_sddm_2"
sddm_theme_conf="$sddm_simple/theme.conf"

# Silent guards: only act when everything is in place and user-writable
[ -f "$wallpaper_current" ] || exit 0
[ -f "$rofi_wallust" ] || exit 0
[ -w "$sddm_simple/Backgrounds" ] || exit 0
[ -w "$sddm_theme_conf" ] || exit 0

extract_color() {
    grep -oP "$1:\s*\K#[A-Fa-f0-9]+" "$rofi_wallust" | head -n1
}

color1=$(extract_color "color0")
color7=$(extract_color "color14")
color10=$(extract_color "color10")
color12=$(extract_color "color12")
color13=$(extract_color "color13")

# If wallust hasn't produced colors yet, still sync the wallpaper itself
if [ -n "$color13" ] && [ -n "$color12" ] && [ -n "$color10" ] && [ -n "$color7" ] && [ -n "$color1" ]; then
    sed -i \
        -e "s/HeaderTextColor=\"#[^\"]*\"/HeaderTextColor=\"$color13\"/" \
        -e "s/DateTextColor=\"#[^\"]*\"/DateTextColor=\"$color13\"/" \
        -e "s/TimeTextColor=\"#[^\"]*\"/TimeTextColor=\"$color13\"/" \
        -e "s/DropdownSelectedBackgroundColor=\"#[^\"]*\"/DropdownSelectedBackgroundColor=\"$color13\"/" \
        -e "s/SystemButtonsIconsColor=\"#[^\"]*\"/SystemButtonsIconsColor=\"$color13\"/" \
        -e "s/SessionButtonTextColor=\"#[^\"]*\"/SessionButtonTextColor=\"$color13\"/" \
        -e "s/VirtualKeyboardButtonTextColor=\"#[^\"]*\"/VirtualKeyboardButtonTextColor=\"$color13\"/" \
        -e "s/HighlightBackgroundColor=\"#[^\"]*\"/HighlightBackgroundColor=\"$color12\"/" \
        -e "s/LoginFieldTextColor=\"#[^\"]*\"/LoginFieldTextColor=\"$color12\"/" \
        -e "s/PasswordFieldTextColor=\"#[^\"]*\"/PasswordFieldTextColor=\"$color12\"/" \
        -e "s/DropdownBackgroundColor=\"#[^\"]*\"/DropdownBackgroundColor=\"$color1\"/" \
        -e "s/HighlightTextColor=\"#[^\"]*\"/HighlightTextColor=\"$color10\"/" \
        -e "s/PlaceholderTextColor=\"#[^\"]*\"/PlaceholderTextColor=\"$color7\"/" \
        -e "s/UserIconColor=\"#[^\"]*\"/UserIconColor=\"$color7\"/" \
        -e "s/PasswordIconColor=\"#[^\"]*\"/PasswordIconColor=\"$color7\"/" \
        "$sddm_theme_conf"
fi

# Copy wallpaper into the theme (default + any shipped fallbacks)
cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default" || exit 0
[ -e "$sddm_simple/Backgrounds/default.jpg" ] && cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default.jpg"
[ -e "$sddm_simple/Backgrounds/default.png" ] && cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default.png"

exit 0
