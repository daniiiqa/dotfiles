#!/usr/bin/env bash
# Cheat sheet (SUPER+H) — lo esencial. La lista completa y siempre al día
# está en SUPER+Shift+K (sale directo de conf/keybinds.conf).

pidof rofi >/dev/null && pkill rofi
pidof yad >/dev/null && pkill yad

GDK_BACKEND=wayland yad \
  --title="Atajos" \
  --center \
  --no-buttons \
  --list \
  --column="Tecla" \
  --column="Acción" \
  --timeout-indicator=bottom \
  "Esc"                  "Cerrar esta ventana" \
  "" "" \
  "Super Space"          "Lanzador de apps" \
  "Super Enter"          "Terminal" \
  "Super Shift Enter"    "Terminal dropdown" \
  "Super E"              "Archivos" \
  "Super B"              "Navegador" \
  "Super S"              "Buscar en la web" \
  "Super Ctrl S"         "Cambiar de ventana" \
  "Super Alt V"          "Portapapeles" \
  "Super Alt E"          "Emojis" \
  "Super Alt C"          "Calculadora" \
  "Super Shift N"        "Notificaciones" \
  "Super Shift E"        "Ajustes rápidos" \
  "Super Shift K"        "Buscar todos los atajos" \
  "" "" \
  "Super T"              "Cambiar look" \
  "Super W"              "Elegir wallpaper" \
  "Super Shift W"        "Efectos de wallpaper" \
  "Ctrl Alt W"           "Wallpaper aleatorio" \
  "Super Alt R"          "Recargar barra y menús" \
  "Super Ctrl Alt B"     "Mostrar/ocultar waybar" \
  "Super O"              "Opacidad de la ventana" \
  "Super Alt O"          "Blur normal/ligero" \
  "Super Shift G"        "Game mode" \
  "" "" \
  "Super C"              "Cerrar ventana" \
  "Super Shift C"        "Matar proceso" \
  "Super F"              "Flotante" \
  "Super Shift F"        "Pantalla completa" \
  "Super Ctrl F"         "Maximizar" \
  "Super Alt L"          "Dwindle / Master" \
  "Super J / K"          "Siguiente / anterior ventana" \
  "Super G"              "Agrupar" \
  "Super U / Shift U"    "Workspace especial / mover ahí" \
  "Super 1-0"            "Ir a workspace" \
  "Super Shift 1-0"      "Mover ventana a workspace" \
  "Super Alt scroll"     "Zoom" \
  "" "" \
  "Super Print"          "Captura" \
  "Super Shift Print"    "Captura de área" \
  "Super Shift S"        "Captura con swappy" \
  "Alt Print"            "Captura de ventana" \
  "" "" \
  "Ctrl Alt L"           "Bloquear" \
  "Ctrl Alt P"           "Menú de apagado" \
  "Ctrl Alt Del"         "Salir de Hyprland"
