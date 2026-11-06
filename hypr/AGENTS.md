# discada — guía para agentes

discada es el rice de Hyprland de dany. Este archivo es para cualquier agente
o modelo que trabaje en él (Claude, opencode/Odysseus, codecompanion en nvim).

## Reglas de la casa

- **Rust, nunca Python**, para herramientas nuevas. Un binario en
  `~/.local/bin`, su repo en `~/<nombre>`. Para pegar cosas, bash está bien.
  Los `.py` que ya existen en `scripts/` (LookBuild, ContrastFix, FontSize…)
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
  conf/*.conf            la config vieja, ya no se carga: no se edita (salvo los de abajo)
  discada.conf, recorder.conf, conf/pinned.conf, conf/livewallpaper.conf
                         datos de discada, NO son config de Hyprland: siguen vivos
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
3. `LookBuild.py` arma los archivos del look (`{{font}}`, `@acc`, colores) y
   `ContrastFix.py` corrige el contraste.
4. `farula` (el telón) tapa el cambio y lo revela con un iris.
5. Las apps leen el look: las de Rust a través de **disco**.

## Las herramientas (Rust)

| nombre | qué es | repo |
|---|---|---|
| disco | la base compartida: el look y cómo dibujar (`features = ["paint"]`) | `~/disco`, github.com/daniiiqa/disco |
| empalme | la barra | `~/empalme` |
| jale | launcher y menús (dmenu, lee los `.rasi` de rofi) | `~/jale` |
| arre | notificaciones | `~/arre` |
| brasa | OSD: volumen, brillo, mic, teclado | `~/brasa` |
| rollo | vista de los workspaces en miniatura | `~/rollo` |
| farula | el telón de los cambios de look/wallpaper | `~/farula` |
| rola | YouTube Music en la terminal (TUI) | `~/rola` |
| vato | audio, bluetooth, red y sistema (TUI) | `~/vato` |
| taco | explorador de archivos (TUI) | `~/taco` |
| fierro | hardware de la laptop | `~/fierro` |
| picha | Quick Share con Android | `~/picha` |
| compa | agente de IA en la terminal (Ollama local o Claude), con herramientas sobre el rice | `~/compa` |

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
- `looks/README.md` todavía dice `rofi/`; las carpetas ya son `jale/`.

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
~/.config/hypr/scripts/LookBuild.py apply <look>
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
