#!/usr/bin/env bash
# Custom (dany) — SDDM sigue al rice: wallpaper, colores de wallust y el look.
# Lo llaman WallustSwww.sh (al cambiar wallpaper) y LookSwitch.sh (al cambiar
# de look). Sin sudo: los archivos del tema simple_sddm_2 son de este usuario.
# Se puede correr cuando sea; si falta algo o no se puede escribir, sale
# en silencio.
#
# Orden: 1) colores de wallust  2) ~/.config/sddm/look.conf del look actual
# (fuente, esquinas, posición, blur… y paleta fija en nord/outsider; gana
# sobre wallust)  3) wallpaper.

wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
rofi_wallust="$HOME/.config/rofi/wallust/colors-rofi.rasi"
look_conf="$HOME/.config/sddm/look.conf"

# Resolve SDDM themes directory (standard paths and NixOS path)
sddm_themes_dir="/usr/share/sddm/themes"
if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
fi
sddm_simple="$sddm_themes_dir/simple_sddm_2"
sddm_theme_conf="$sddm_simple/theme.conf"

# Silent guards: only act when the theme is in place and user-writable
[ -w "$sddm_theme_conf" ] || exit 0

# Key="value" en [General]: reemplaza si existe, si no lo agrega al final
set_key() {
    if grep -q "^$1=" "$sddm_theme_conf"; then
        sed -i "s|^$1=.*|$1=\"$2\"|" "$sddm_theme_conf"
    else
        sed -i "/^\[General\]/a $1=\"$2\"" "$sddm_theme_conf"
    fi
}

extract_color() {
    grep -oP "(^|\s)$1:\s*\K#[A-Fa-f0-9]+" "$rofi_wallust" | head -n1
}

# 1) colores de wallust
if [ -f "$rofi_wallust" ]; then
    bg=$(extract_color "background-color")
    fg=$(extract_color "foreground")
    c0=$(extract_color "color0")
    c10=$(extract_color "color10")
    c12=$(extract_color "color12")
    c13=$(extract_color "color13")
    c14=$(extract_color "color14")
    if [ -n "$bg" ] && [ -n "$fg" ] && [ -n "$c0" ] && [ -n "$c10" ] && \
       [ -n "$c12" ] && [ -n "$c13" ] && [ -n "$c14" ]; then
        for k in HeaderTextColor DateTextColor TimeTextColor DropdownSelectedBackgroundColor \
                 SystemButtonsIconsColor SessionButtonTextColor VirtualKeyboardButtonTextColor \
                 HoverSystemButtonsIconsColor HoverSessionButtonTextColor \
                 HoverVirtualKeyboardButtonTextColor; do
            set_key "$k" "$c13"
        done
        for k in HighlightBackgroundColor LoginFieldTextColor PasswordFieldTextColor \
                 LoginButtonBackgroundColor; do
            set_key "$k" "$c12"
        done
        for k in BackgroundColor DimBackgroundColor FormBackgroundColor \
                 LoginFieldBackgroundColor PasswordFieldBackgroundColor; do
            set_key "$k" "$bg"
        done
        for k in UserIconColor PasswordIconColor PlaceholderTextColor \
                 HoverUserIconColor HoverPasswordIconColor; do
            set_key "$k" "$c14"
        done
        set_key DropdownBackgroundColor "$c0"
        set_key HighlightTextColor "$bg"
        set_key HighlightBorderColor "$c12"
        set_key LoginButtonTextColor "$bg"
        set_key DropdownTextColor "$fg"
        set_key WarningColor "$c10"
    fi
fi

# 2) el look actual (líneas Key="value"; # comenta)
if [ -f "$look_conf" ]; then
    while IFS='=' read -r k v; do
        case "$k" in ''|\#*) continue ;; esac
        v=${v#\"}; v=${v%\"}
        # "@acc": un color del look (los nombres están en los colores de rofi)
        if [[ $v == @* ]]; then
            v=$(extract_color "${v#@}")
            [ -n "$v" ] || continue
        fi
        set_key "$k" "$v"
    done < "$look_conf"
fi

# 3) wallpaper (default + any shipped fallbacks)
if [ -f "$wallpaper_current" ] && [ -w "$sddm_simple/Backgrounds" ]; then
    cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default"
    [ -e "$sddm_simple/Backgrounds/default.jpg" ] && cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default.jpg"
    [ -e "$sddm_simple/Backgrounds/default.png" ] && cp -f "$wallpaper_current" "$sddm_simple/Backgrounds/default.png"
fi

exit 0
