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
  "── Apps ──"           "" \
  "Super Space"          "Lanzador de apps" \
  "Super Enter"          "Terminal" \
  "Super Shift Enter"    "Terminal dropdown" \
  "Super E"              "Archivos (yazi)" \
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
  "── Look ──"           "" \
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
  "── Barra ──"          "" \
  "Click en app"         "Enfocar (otra vez: siguiente ventana)" \
  "Click medio en app"   "Cerrar esa ventana" \
  "App tenue"            "Fijada y cerrada: click la abre" \
  "Mouse sobre ⊞ N"      "Ver el resto (con 6+ apps)" \
  "Click en el ojo"      "Stay awake: no bloquear ni suspender" \
  "Barras de audio"      "Salen solas cuando suena música" \
  "" "" \
  "── Ventanas ──"       "" \
  "Super C"              "Cerrar ventana" \
  "Super Shift C"        "Matar proceso" \
  "Super F"              "Flotante" \
  "Super Shift F"        "Pantalla completa" \
  "Super Ctrl F"         "Maximizar" \
  "Super flechas"        "Mover el foco" \
  "Super Ctrl flechas"   "Mover ventana" \
  "Super Alt flechas"    "Intercambiar ventana" \
  "Super Shift flechas"  "Redimensionar" \
  "Super J / K"          "Siguiente / anterior ventana" \
  "Super Alt L"          "Dwindle / Master" \
  "Super Shift I"        "Girar división (dwindle)" \
  "Super G"              "Agrupar" \
  "" "" \
  "── Workspaces ──"     "" \
  "Super 1-0"            "Ir a workspace" \
  "Super Shift 1-0"      "Mover ventana a workspace" \
  "Super Ctrl 1-0"       "Mover sin seguirla" \
  "Super Tab"            "Workspace siguiente" \
  "Super U / Shift U"    "Workspace especial / mover ahí" \
  "Super Alt scroll"     "Zoom" \
  "" "" \
  "── Capturas ──"       "" \
  "Super Print"          "Pantalla" \
  "Super Shift Print"    "Área" \
  "Super Shift S"        "Área + editar (swappy)" \
  "Alt Print"            "Ventana activa" \
  "Super Ctrl Print"     "Pantalla en 5 s" \
  "" "" \
  "── Sistema ──"        "" \
  "Alt Shift"            "Cambiar distribución de teclado" \
  "Teclas multimedia"    "Volumen, mute, play/pausa, siguiente" \
  "Ctrl Alt L"           "Bloquear" \
  "Ctrl Alt P"           "Menú de apagado" \
  "Ctrl Alt Del"         "Salir de Hyprland"
