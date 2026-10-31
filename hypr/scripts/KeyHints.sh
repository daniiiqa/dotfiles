#!/usr/bin/env bash
# Cheat sheet (SUPER+H) — lo esencial, en rofi con el estilo del look actual.
# Escribir filtra. La lista completa y siempre al día está en SUPER+Shift+K
# (sale directo de conf/keybinds.conf). Idioma: hypr/discada.conf.
#
# Formato de la lista: "# Sección|Section" o "tecla|acción|action[|key]"
# (la última columna solo si la tecla también se traduce).

pidof rofi >/dev/null && pkill rofi
pidof yad >/dev/null && pkill yad
. "$HOME/.config/hypr/scripts/lang.sh"

read -r -d '' SHEET <<'EOF'
# Apps|Apps
Super Space|Lanzador de apps|App launcher
Super Enter|Terminal|Terminal
Super Shift Enter|Terminal dropdown|Dropdown terminal
Super E|Archivos (taco)|Files (taco)
Super B|Navegador|Browser
Super M|Música (rola)|Music (rola)
vato|Audio, bluetooth, red y sistema (en la terminal)|Audio, bluetooth, network and system (terminal)
Super S|Buscar en la web|Web search
Super Ctrl S|Cambiar de ventana|Window switcher
Super Alt V|Portapapeles|Clipboard
Super Alt E|Emojis|Emoji
Super Alt C|Calculadora|Calculator
Super Shift N|Notificaciones|Notifications
Super Shift E|Ajustes de discada|discada settings
Super Shift K|Buscar todos los atajos|Search all shortcuts
# Look|Look
Super T|Cambiar look (arriba: shader on/off)|Switch look (top: shader on/off)
Super W|Elegir wallpaper|Pick wallpaper
Super Shift W|Efectos de wallpaper|Wallpaper effects
Ctrl Alt W|Wallpaper aleatorio|Random wallpaper
Super Alt R|Recargar barra y menús|Reload bar and menus
Super Ctrl Alt B|Mostrar/ocultar la barra|Show/hide the bar
Super O|Opacidad de la ventana|Window opacity
Super Alt O|Blur normal/ligero|Normal/light blur
Super Shift G|Game mode|Game mode
# Barra|Bar
Click en app|Enfocar (otra vez: siguiente ventana)|Focus (again: next window)|Click an app
Click medio en app|Cerrar esa ventana|Close that window|Middle-click an app
App tenue|Fijada y cerrada: click la abre|Pinned and closed: click opens it|Dimmed app
Mouse sobre ⊞ N|Ver el resto (con 6+ apps)|See the rest (6+ apps)|Hover ⊞ N
Click en el ojo|Stay awake: no bloquear ni suspender|Stay awake: no lock or sleep|Click the eye
Barras de audio|Música: click anterior · medio pausa · derecho siguiente|Music: click previous · middle pause · right next|Audio bars
Rueda en las barras|Volumen (en pausa quedan planas y tenues)|Volume (flat and dim while paused)|Wheel on the bars
Grabación (con tiempo)|click detiene · medio pausa · derecho menú|click stops · middle pauses · right menu|Recording (timer)
Replay en la barra|Encendido: click guarda|On: click saves|Replay on the bar
Batería (laptop)|click perfil de energía · derecho ahorro|click power profile · right saver|Battery (laptop)
# Grabar|Record
Alt Z|Menú de grabación|Recording menu
Alt F9|Grabar pantalla (otra vez: detener)|Record screen (again: stop)
Alt Ctrl F9|Grabar una región|Record a region
Alt Shift F9|Grabar la ventana activa|Record the active window
Alt F7|Pausar / seguir|Pause / resume
Alt F10|Guardar replay|Save replay
Alt Shift F10|Replay on/off (arranca al iniciar sesión)|Replay on/off (starts at login)
Al grabar|No molestar automático; videos en ~/Videos|Do not disturb on; videos in ~/Videos|While recording
# Taco (dentro del explorador)|Taco (inside the file manager)
h  j  k  l|Moverse · subir · entrar|Move · up · enter
Enter  o  e|Abrir · abrir con · editar|Open · open with · edit
Espacio|Marcar|Mark|Space
y  x  p|Copiar · cortar · pegar|Copy · cut · paste
d  D|Papelera · borrar para siempre|Trash · delete forever
r  a|Renombrar · nuevo (con / es carpeta)|Rename · new (ending in / makes a folder)
/  z  f|Filtrar · zoxide · buscar con fzf|Filter · zoxide · find with fzf
g  M|Ir a (h d p c t u…) · memorias USB|Go to (h d p c t u…) · USB drives
.  s|Ocultos · orden|Hidden · sort
?|Todas las teclas|Every key
# Rola (dentro del reproductor)|Rola (inside the player)
/|Buscar|Search
Enter|Reproducir / abrir|Play / open
Espacio|Pausa|Pause|Space
n  p|Siguiente / anterior|Next / previous
<  >|−5 s / +5 s|−5 s / +5 s
+  -|Volumen|Volume
s  r  a|Aleatorio · repetir · autoplay|Shuffle · repeat · autoplay
z|Mandar a la cola|Add to queue
R|Radio de la canción|Song radio
L|Me gusta|Like
P|Añadir a una playlist|Add to a playlist
y  c|Letra · portada|Lyrics · cover
h  l  Tab|Cambiar de panel|Switch panel
j  k  g  G|Moverse|Move around
Backspace|Atrás|Back
o  ?|Ajustes · ayuda|Settings · help
d  J  K|En la cola: quitar · mover|In the queue: remove · move
q|Salir (guarda la cola y por dónde ibas)|Quit (keeps the queue and position)
# Ventanas|Windows
Super C|Cerrar ventana|Close window
Super Shift C|Matar proceso|Kill process
Super F|Flotante|Float
Super Shift F|Pantalla completa|Fullscreen
Super Ctrl F|Maximizar|Maximize
Super flechas|Mover el foco|Move focus|Super arrows
Super Ctrl flechas|Mover ventana|Move window|Super Ctrl arrows
Super Alt flechas|Intercambiar ventana|Swap window|Super Alt arrows
Super Shift flechas|Redimensionar|Resize|Super Shift arrows
Super J  K|Siguiente / anterior ventana|Next / previous window
Super Alt L|Dwindle / Master|Dwindle / Master
Super Shift I|Girar división (dwindle)|Rotate split (dwindle)
Super G|Agrupar|Group
# Workspaces|Workspaces
Super 1-0|Ir a workspace|Go to workspace
Super Shift 1-0|Mover ventana a workspace|Move window to workspace
Super Ctrl 1-0|Mover sin seguirla|Move without following
Super Tab|Workspace siguiente|Next workspace
Super U  Shift U|Workspace especial / mover ahí|Special workspace / move there
Super Alt rueda|Zoom|Zoom|Super Alt wheel
# Capturas|Screenshots
Super Print|Pantalla|Screen
Super Shift Print|Área|Area
Super Shift S|Área + editar (swappy)|Area + edit (swappy)
Alt Print|Ventana activa|Active window
Super Ctrl Print|Pantalla en 5 s|Screen in 5 s
# vato (dentro de la app)|vato (inside the app)
1-4  tab|Audio · bluetooth · red · sistema|Audio · bluetooth · network · system
h  l|Volumen (audio)|Volume (audio)
enter|Predeterminada · conectar · emparejar|Make default · connect · pair
m|Mudo (audio)|Mute (audio)
s  p|Buscar · encender bluetooth|Scan · power bluetooth
c  m  x|Ordenar cpu/mem · cerrar proceso|Sort cpu/mem · kill process
# Sistema|System
Alt Shift|Cambiar distribución de teclado|Switch keyboard layout
Teclas multimedia|Volumen, mute, play/pausa, siguiente|Volume, mute, play/pause, next|Media keys
Ctrl Alt L|Bloquear|Lock
Ctrl Alt P|Menú de apagado|Power menu
Ctrl Alt Del|Salir de Hyprland|Exit Hyprland
EOF

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; printf '%s' "${s//>/&gt;}"; }

rows=() headers=()
while IFS='|' read -r key es en key_en; do
  [ -z "$key" ] && continue
  if [[ $key == "# "* ]]; then
    headers+=("${#rows[@]}")
    rows+=("<b>$(esc "$(L "${key#\# }" "$es")")</b>")
  else
    [ "$DISCADA_LANG" = en ] && [ -n "$key_en" ] && key=$key_en
    act=$(L "$es" "$en")
    # la tecla en negrita y rellenada a lo ancho (las fuentes de rofi son mono)
    pad=$(( 21 - ${#key} )); (( pad < 1 )) && pad=1
    rows+=("  <b>$(esc "$key")</b>$(printf '%*s' $pad '')$(esc "$act")")
  fi
done <<<"$SHEET"

look=$(cat "$HOME/.config/hypr/looks/.current" 2>/dev/null)
printf '%s\n' "${rows[@]}" |
  rofi -dmenu -i -markup-rows -no-custom -p "$(L atajos shortcuts)" \
    -a "$(IFS=,; echo "${headers[*]}")" \
    -config "$HOME/.config/rofi/config-cheatsheet.rasi" \
    -mesg "discada · $(L "escribe para filtrar · Super Shift K: todos los atajos" "type to filter · Super Shift K: all shortcuts")${look:+ · look: $look}" \
    >/dev/null
