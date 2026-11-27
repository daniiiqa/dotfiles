# discada — guía para agentes

discada es el rice de Hyprland de dany. Este archivo es para cualquier agente
o modelo que trabaje en él (Claude, opencode/Odysseus, codecompanion en nvim).

## Reglas de la casa

- **Rust, nunca Python**, para herramientas nuevas. Un binario en
  `~/.local/bin`, su repo en `~/<nombre>`. Para pegar cosas, bash está bien.
  Los `.py` que ya existen en `scripts/` (FontSize, AppStrip, Battery…)
  son legado: se arreglan, pero no se agregan nuevos.
- **Todo en español**: comentarios, mensajes y docs. Tono regio, casual.
  Lo que cambia dany sobre algo heredado se marca con `Custom (dany):`.
- **Herramienta nueva = preguntar el nombre primero.** Se explica qué haría y
  dany le pone el nombre (regio, de Monterrey: discada, empalme, arre…). Antes
  de proponer uno, revisar que no exista en `~/`, `~/.local/bin` o el PATH.
  Arreglar o extender una herramienta que ya existe no necesita esto.
- Cambios chicos y al punto. No reescribir lo que funciona.

## Mapa

```
~/.config/hypr/
  hyprland.lua           la config activa (Hyprland 0.57+, que ya no lee .conf)
  conf/*.lua             keybinds, windowrules, startup, decorations… lo que carga Hyprland
  discada.conf, recorder.conf, conf/pinned.conf, conf/livewallpaper.conf
                         datos de discada, NO son config de Hyprland (no hay .conf de Hyprland)
  hypridle.conf, hyprlock.conf   siguen en .conf (son de otros programas)
  scripts/               el pegamento (bash): Look*, Wallpaper*, Hypr.sh…
  looks/<look>/          un look: look.toml + espejo de ~/.config con lo que cambia
  wallust/               plantillas de colores a partir del wallpaper
```

Atajos clave: SUPER+T looks (`LookSwitch.sh`), SUPER+W wallpaper
(`WallpaperSelect.sh`), CTRL+ALT+W wallpaper al azar (`WallpaperRandom.sh`).

## Cómo fluye un cambio de look o wallpaper

1. `LookSwitch.sh` / `WallpaperSelect.sh` → `awww` (imagen) o `mpvpaper` (video, uno por monitor).
2. `wallust` saca los colores del wallpaper (color0…color15).
3. **leña** (`~/.local/bin/lena`, repo `~/lena`) arma los archivos del look
   (`{{font}}`, `@acc`, colores), corrige el contraste (`lena contrast`) y les
   pasa los colores a GTK/Qt (`lena apps`). Su matemática de color está en disco.
4. `farula` (el telón) tapa el cambio y lo revela con un iris.
5. Las apps leen el look: las de Rust a través de **disco**.

## Las herramientas (Rust)

| nombre | qué es | repo |
|---|---|---|
| disco | la base compartida: el look y cómo dibujar (`features = ["paint"]`) | `~/disco`, github.com/daniiiqa/disco |
| empalme | la barra | `~/empalme` |
| jale | launcher y menús (dmenu). Se dibuja como TUI, en celdas con disco y el `[style]` del look (como machaca); de los `.rasi` solo toma la forma de cada menú (ancho, renglones, columnas, íconos). `JALE_ESTILO=rasi` dibuja como antes, con el theme de rofi | `~/jale` |
| arre | notificaciones | `~/arre` |
| brasa | OSD: volumen, brillo, mic, teclado | `~/brasa` |
| rollo | vista de los workspaces en miniatura | `~/rollo` |
| farula | el telón de los cambios de look/wallpaper | `~/farula` |
| rola | YouTube Music en la terminal (TUI) | `~/rola` |
| vato | audio, bluetooth, red y sistema (TUI) | `~/vato` |
| taco | explorador de archivos (TUI) | `~/taco` |
| fierro | hardware de la laptop | `~/fierro` |
| carbon | el updater ("actualizar discada"): pasos y log a la izquierda, la discada en la lumbre a la derecha; `carbon revisa` es el antiguo UpdateCheck.py | `~/carbon` |
| picha | Quick Share con Android | `~/picha` |
| bicho | los animalitos del escritorio (bicho, michi, baba): caminan, trepan ventanas, bailan; menú `bicho menu` (SUPER+Shift+B), config `~/.config/bicho/config.json` | `~/bicho` |
| maceta | la dalia de letras de fondo (layer-shell abajo de las ventanas); su submenú en discada (SUPER+Shift+E › maceta), `maceta estado` / `maceta pon CLAVE V`, arranque `maceta --auto` (si `al_iniciar = si`), config `~/.config/maceta/config` | `~/maceta` |
| compa | agente de IA en la terminal (Ollama local o Claude), con herramientas sobre el rice | `~/compa` |
| cacha | el sucesor de fastfetch: lee el fastfetch de cada look y lo dibuja en vivo (info, pixel art animado de `~/.config/cacha/pixel`, visualizador de cava); estilo en `FETCH_STYLE` (discada.conf), lo lanza `scripts/FetchHook.sh` | `~/cacha` |
| chapa | el candado de discada en vez de hyprlock (`LOCKER=chapa` en discada.conf, lo lanza `scripts/LockScreen.sh`; si falla, sigue hyprlock): lee el `hyprlock.conf` del look (labels con `cmd[…]`, como el motd), huella con fprintd, log en `~/.local/state/chapa/chapa.log` | `~/chapa` |
| machín | la pantalla de la otra compu como monitor extra, en las dos direcciones: `machin` (SUPER+Shift+M) busca la otra por mDNS (`_machin._tcp`), crea el monitor virtual `MACHIN` (headless) del tamaño de su pantalla, Sunshine lo transmite (`output_name = MACHIN`, por nombre) y la otra lo abre en Moonlight tras *Aceptar / Siempre / No*; `machin escucha` (startup.lua) atiende en el 47392, solo a compus emparejadas en Moonlight; `machin vigila` re-aplica la regla del monitor en cada recarga; binario `machin`, symlink `machín` | `~/machin` |
| chispa | la luz del AULA F75 desde la terminal (solo luz, por cable, 2.4 GHz o Bluetooth; los cambios de color se sostienen en vivo con `chispa hold` y se guardan al bloquear la pantalla, suspender o salir) | `~/chispa` |
| trompo | la compu desde el cel: una PWA con el look (colores, fuente y estilo vía disco) para música, volumen, brillo, looks, wallpapers, machín, bloquear y suspender. `trompo sirve` (startup.lua) sirve http 47420 (bienvenida: bajar su CA) y https 47421 (la app y su API, por SSE); `trompo` enseña un QR de un solo uso (5 min) para emparejar un cel; `trompo cels` / `trompo olvida N`. Su propia CA en `~/.config/trompo/` (name constraints: solo IPs privadas y `.local`), los cels en `confianza.json` (solo el sha256 de cada llave). Aplica wallpapers con `WallpaperSelect.sh <ruta>` | `~/trompo` |
| machaca | el panel de discada (SUPER+Shift+E, vía `QuickSettings.sh` sin argumentos; `QuickSettings.sh lista` abre el menú viejo de jale): cabecera con el wallpaper y el look, columnas Apariencia / Sistema / Tus compus y el cel, fila de herramientas, página de looks. Solo es la cara: lee con `QuickSettings.sh estado`, los submenús son páginas del panel descritas por `QuickSettings.sh pagina X` (opcion, interruptor, elige, botones, abre) y todo se cambia con `QuickSettings.sh hacer CLAVE [V]` (`menu X` sigue para el menú viejo). Layer `machaca` (blur en windowrules.lua; opaco si el look no tiene blur). Para probar sin teclado: `MACHACA_TECLAS="Tab Down Return"` | `~/machaca` |
| jardín (`jardin`) | lo que hemos hecho juntos, sembrado (lo hizo Claude): cada repo de discada es una planta (mezquite, anacahuita, maguey, nopal, girasol, palma, biznaga) y cada commit con `Co-Authored-By: Claude` es parte de ella; cielo según la hora, viento, colores del look. `TuiApp.sh jardin` (SUPER+Shift+J); `scripts/Protector.sh` lo pone a pantalla completa a los 8 min sin uso (hypridle), antes del bloqueo. **Repo privado** (`install.sh` lo baja con la sesión de gh; sin acceso se salta) | `~/jardin` |
| MCServers (`mcservers`) | los servers de Minecraft de la compu (TUI, SUPER+Shift+O): cada carpeta de `~/MinecraftServers/` con `server.properties` (otra carpeta: `"carpeta"` en `~/.config/mcservers/config.json`; las `~/mc-*` de antes también cuentan); prender/apagar/reiniciar, consola (fifo `consola`, salida `servidor.out`), log, RAM/CPU, jugadores (whitelist/op), Chunky, respaldos; crear uno (N: vanilla o Fabric optimizado, y la versión), duplicar (D) y semilla nueva (S: respaldando el mundo o no). El Java se comparte en `~/MinecraftServers/.java/<versión>`. CLI: `mcservers lista|prende|apaga|reinicia|manda|respalda|versiones|crea|duplica|semilla`. Nombre provisional | `~/mcservers` |

Las gráficas son clientes Wayland con smithay-client-toolkit + layer-shell +
tiny-skia; las TUI usan ratatui. Todas toman colores y estilo de disco.

## Trampas conocidas

- **El PATH de Hyprland NO incluye `~/.local/bin`.** Lo que se lance desde un
  atajo usa la ruta completa o hace `PATH="$HOME/.local/bin:$PATH"`. Probar las
  herramientas con un entorno como el de Hyprland, no solo desde la shell.
- **Hablarle a Hyprland siempre con `scripts/Hypr.sh`.** Con Lua ya no existen
  `hyprctl keyword` ni `dispatch workspace N`.
- **No borrar ni renombrar `hyprland.lua`.** Sin él, Hyprland genera uno de
  ejemplo y discada no carga (no regresa al `.conf`).
- `hyprctl eval` responde `ok` aunque el nombre no exista (`type(hl.x)` da
  `nil`, sin error). Para probar que existe: `if hl.x == nil then error("no") end`.
- Las layer rules van en `conf/windowrules.lua`.
- Una superficie layer-shell tiene que poner su cursor (`ThemedPointer`), o
  Hyprland no pinta ninguno encima.
- Imágenes grandes (wallpapers): nunca decodificar a tamaño completo en el
  hilo que dibuja. Miniaturas en caché (`~/.cache/<herramienta>`) y en hilos.
- **Puede haber otro escritorio (KDE) en la misma compu.** Lo de discada no
  se le pasa: programas por defecto en `~/.config/hyprland-mimeapps.list`
  (`mime_hypr` en install.sh; nunca `xdg-mime default` ni `xdg-settings`, que
  escriben en el de todos), arre solo arranca en Hyprland, el fetch en KDE es
  fastfetch, y `scripts/FueraDeHyprland.sh` (desde
  `~/.config/plasma-workspace/env/discada.sh`) quita el import de leña en
  `gtk.css` y le regresa a KDE su tema, iconos y cursor (gsettings y settings.ini, una copia por escritorio en `~/.local/state/discada/escritorio`); `FueraDeHyprland.sh regresa` + `lena apps` en startup.lua ponen los de discada. Kvantum y btop.conf no se pisan al actualizar; el colorscheme de nvim y «tu semana» solo en Hyprland; taco con `OnlyShowIn=Hyprland`; con otro escritorio instalado no se toca SDDM y fierro deja prendido power-profiles-daemon (pone los perfiles con powerprofilesctl).

## Recetas (cómo se hace cada cosa, sin adivinar)

Los scripts NO están en el PATH: siempre `~/.config/hypr/scripts/<X>`.

**Dónde vive cada cosa de un look** (`~/.config/hypr/looks/<look>/`):
- ventanas (rounding, gaps, bordes, blur, sombras, opacidad):
  `hypr/conf/decorations.lua` — NO en look.toml
- animaciones: `hypr/conf/animations.lua`
- barra, fuente, estilo de las TUI, farula, paleta: `look.toml`
- lo vivo (lo que Hyprland carga) está en `~/.config/hypr/conf/`; el look se
  copia ahí al aplicarlo.

**Crear un look nuevo**: NUNCA con cp/mkdir/sed a mano. Siempre:
`~/.config/hypr/scripts/LookNew.sh <nombre> <base>` (copia la base completa y
le pone el nombre). Luego editar SOLO los archivos de `looks/<nombre>/` con
editar_archivo (no con sed). Si el look es `from = "wallpaper"`, los colores
salen de wallust: no se ponen hex en look.toml; se juega con `c.color0…15`
(arriba del archivo: `local c = require("wallust.wallust-hyprland")`). Las opciones válidas de `[style]`, `[bar]`, `[farula]`
están en `looks/README.md`: no inventar valores. Para colores fijos (no del
wallpaper): `from = "palette"` con `background`, `foreground`, `color0`…
`color15` en `[colors]`, como dice el README (no `hex = [...]` ni secciones
inventadas). Colores en archivos de Hyprland, como texto de Lua:
`"rgb(rrggbb)"`, `"rgba(rrggbbaa)"` (8 dígitos, sin comas) o `c.color0…c.color15`. Estilos de
animación de ventanas: `popin N%`, `slide`, `gnomed` (no `fade`).
Verificar DESPUÉS de aplicar (poner_look avisa los errores de Hyprland):
`--verify-config` antes de aplicar revisa la config vieja, no el look.

**Lo vivo no se edita a mano** cuando es parte de un look
(`conf/decorations.lua`, `conf/animations.lua`…): se edita el look y se aplica.
En compa: la herramienta `poner_look` pone o reaplica un look y avisa los
errores de Hyprland; úsala en vez de estos scripts.

**Aplicar otra vez el look actual** después de editar sus archivos
(`LookSwitch.sh` no hace nada si ya es el actual):
```
~/.config/hypr/scripts/FontSize.py unapply
~/.local/bin/lena apply <look>
~/.config/hypr/scripts/FontSize.py apply      # recarga Hyprland
```
Cambiar a OTRO look: `~/.config/hypr/scripts/LookSwitch.sh <look>`.

**Agregar un atajo**: primero buscar que la tecla no esté usada (en
`conf/keybinds.lua`). Luego AGREGAR un renglón nuevo (nunca reemplazar uno
que ya existe), junto a los parecidos:
```
conf/keybinds.lua:   hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd(scriptsDir .. "/Vato.sh"), { description = "descripción" })
```
Para agregar sin reemplazar: en editar_archivo, `buscar` = un renglón vecino
y `reemplazar` = ese mismo renglón + el nuevo. Después: `hyprctl reload`.
Las window rules igual: `conf/windowrules.lua`.

**Recargar Hyprland**: `hyprctl reload`. Errores de config:
`hyprctl configerrors`. Revisar sin aplicar:
`Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.

**Log de Hyprland** (no está en journalctl):
`grep -iE 'err|warn' "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" | tail -40`

**La barra (empalme)**: reiniciarla:
`pkill -x empalme; setsid ~/.config/hypr/scripts/Bar.sh >/dev/null 2>&1 &`
(nunca lanzar `empalme` a mano: Bar.sh la relanza si se cae).
`pkill -USR1 -x empalme` solo la esconde o la muestra.

**Si algo falla dos veces igual**, no lo repitas: lee el error, cambia de
enfoque o pregúntale a dany.

## Antes de dar algo por hecho

- Rust: `cargo build --release` y `cargo clippy` sin warnings nuevos; instalar
  con `install -m755 target/release/<x> ~/.local/bin/`.
- Lo visual: probarlo de verdad (abrirlo, `grim` para captura).
- Commits en español, chicos, en el repo de cada herramienta.
