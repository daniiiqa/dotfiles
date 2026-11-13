#!/usr/bin/env bash
# Idioma de discada (hypr/discada.conf → LANGUAGE=es|en). Se usa con
#   . "$HOME/.config/hypr/scripts/lang.sh"
#   notify-send "$(L 'Guardado' 'Saved')"
# Sin el archivo (o con otro valor) sale en inglés.

DISCADA_LANG=$(sed -nE 's/^LANGUAGE=([a-z]+).*/\1/p' "$HOME/.config/hypr/discada.conf" 2>/dev/null)
[ "$DISCADA_LANG" = es ] || DISCADA_LANG=en

L() { if [ "$DISCADA_LANG" = es ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
