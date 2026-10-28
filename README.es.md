# discada

**Un rice de Hyprland hecho de looks.** La discada es el platillo norteño donde
un montón de carnes se cocinan juntas en el disco y salen en un solo plato,
limpio y delicioso. Aquí las carnes son catorce looks — cada uno cambia la barra,
fuentes, iconos, colores, menús, pantalla de bloqueo y login — servidos en un
solo rice. Los colores salen del wallpaper (también de los de video) con wallust.

Hecho en Monterrey, N.L. 🇲🇽 · [Read in English](README.md)

## Instalar

En un Arch recién instalado (con internet y tu usuario con sudo):

```bash
curl -fsSL https://raw.githubusercontent.com/daniiiqa/dotfiles/main/install.sh | bash
```

Pregunta el idioma (English / Español), qué looks quieres y con cuál empezar,
y al final ofrece reiniciar. Entras a Hyprland desde SDDM y el primer arranque
pone un wallpaper, genera los colores y muestra los atajos. Tus wallpapers
(imágenes o videos) van en `~/Pictures/wallpapers`.

Qué hace `install.sh` (también corre desde un clone: `./install.sh`;
`--dry-run` muestra todo sin tocar nada; `--help` lista las opciones):

- clona el repo en `~/dotfiles` si se corrió con curl
- paquetes: repos oficiales con pacman; mpvpaper, wallust, wlogout y Zen de
  AUR con yay/paru (si no hay ninguno, instala yay). Solo las fuentes de los
  looks que elegiste
- copia las carpetas del rice a `~/.config`, respaldando lo que pise en
  `~/.config-backup-<fecha>/`; las pantallas quedan en detección automática
- taco como explorador por defecto, Zen como navegador por defecto,
  NetworkManager y bluetooth activos
- en una laptop, brightnessctl y power-profiles-daemon (si no usas tlp)
- nvim: si no tienes config, el starter de LazyVim; y el colorscheme de
  discada de `hypr/nvim/` (lo demás de tu config no se toca)
- SDDM con el tema simple_sddm_2 si no hay otro display manager
  (`--no-sddm` / `--sddm` para forzar)
- compila [rola](https://github.com/daniiiqa/rola), [vato](https://github.com/daniiiqa/vato), [arre](https://github.com/daniiiqa/arre) y [taco](https://github.com/daniiiqa/taco) en `~/.local/bin`
- en el primer login, `hypr/scripts/FirstRun.sh` termina el resto (wallpaper
  generado si no hay ninguno, colores, tema oscuro e iconos para GTK)

Se puede correr varias veces sin romper nada.

## Lo esencial

| teclas | |
|---|---|
| `SUPER+H` | cheat sheet (con el estilo del look, escribe para filtrar) |
| `SUPER+Shift+E` | **ajustes de discada**: look, shader, idioma, tamaño de letra, visualizador, grabador, batería (laptops), game mode, blur, editar config, herramientas, actualizar |
| `SUPER+T` | cambiar de look (arriba: shader del look on/off) |
| `SUPER+W` | wallpaper |
| `SUPER+M` | música (rola) |
| `ALT+Z` | menú de grabación · `ALT+F9` grabar · `ALT+F10` guardar replay |
| `SUPER+Shift+K` | buscar todos los atajos |

## Looks

`brutalist` · `classic` · `glass` · `minimal` · `neon` · `nord` · `outsider` ·
`paper` · `pastel` · `retro`

Hechos en México: `fundidora` (acero regio, naranja de alto horno, el Cerro de
la Silla) · `ofrenda` (Día de Muertos: cempasúchil, papel picado, luz de vela)
· `loteria` (las cartas: cada módulo es una carta) · `talavera` (loza de
Puebla: esmalte crema, trazo cobalto)

Cada look vive en `hypr/looks/<nombre>/` como espejo de `~/.config` con solo
los archivos que cambia: decoraciones y animaciones de Hyprland, hyprlock,
waybar (config, estilo, iconos de apps, estilo del visualizador, etiquetas del
grabador), rofi, arre, wlogout, kitty, fastfetch, rola, SDDM y la paleta de
wallust. `LookSwitch.sh` guarda lo vivo en el look actual (así no se pierde lo
que edites a mano) y copia el nuevo encima.

## Piezas

- **Idioma**: español o inglés en todos los menús, avisos, tooltips y el cheat
  sheet (`hypr/discada.conf`, o el menú de ajustes). rola lo sigue.
- **Grabador** (`Recorder.sh`): gpu-screen-recorder sin su overlay. Pantalla,
  región o ventana activa; pausa; replay en RAM que arranca al iniciar sesión.
  Indicador en la barra con el estilo del look, aviso con miniatura al guardar
  y no molestar mientras graba para que los popups no salgan en el video.
  Ajustes en `hypr/recorder.conf` o en el menú de ajustes.
- **Visualizador de audio** (`Visualizer.py`): solo mientras suena música; también
  son los controles (click anterior, medio pausa, derecho siguiente, rueda
  volumen). Estilo por look: braille, peaks, bloques, ascii o lápiz.
- **Apps abiertas en la barra** (`AppStrip.py`): un icono por app, teñido por
  el look, con su set de iconos. Con 6+ apps se van a un cajón. Click enfoca (o
  cicla ventanas), click medio cierra. Las fijadas (`hypr/conf/pinned.conf`)
  siempre se ven; cerradas salen tenues y el click las abre.
- **Wallpaper por look**: los seis looks de paleta fija (fundidora, ofrenda,
  lotería, talavera, nord, outsider) traen su wallpaper (`hypr/wallpapers/`).
  Los tuyos (videos incluidos) se guardan y vuelven al cambiar a un look que
  sigue al wallpaper; si eliges otro estando en un look fijo, ese se queda.
- **Apps GTK y Qt con los colores del look**: `AppColors.py` lleva los colores
  del look (los de wallust o la paleta fija) a GTK 3 (adw-gtk3), GTK
  4/libadwaita y Qt (Fusion + paleta de qt5ct/qt6ct), en claro u oscuro.
- **Actualizar discada** desde el menú de ajustes: en una máquina instalada
  baja la versión nueva y corre `install.sh --update` (conserva idioma, looks,
  look actual y ajustes; solo instala lo que falte).
- **Login (SDDM)**: sigue al look (fuente, forma, paleta) y a los colores del
  wallpaper, sin sudo (`SDDMWallpaperSync.sh`).
- **Wallpapers por monitor**: swww para imágenes/gifs, un mpvpaper por monitor
  solo donde hay video. Game mode los pausa y los revive al salir.
- **Colores desde wallpapers de video**: el fotograma de en medio pasa por
  wallust, así waybar, rofi, kitty, arre, hyprlock y SDDM combinan.
- **Legible con cualquier wallpaper**: wallust con `check_contrast` y luego
  `ContrastFix.py` sube cualquier color de texto a 4.5:1 (WCAG AA).
- **Archivos: [taco](https://github.com/daniiiqa/taco)** — el explorador de
  discada en kitty (`SUPER+E`, y para "abrir carpeta" desde apps), con el look
  como vato: tres columnas, vista previa de imágenes, video y PDF, copiar y mover
  en otro hilo, papelera, memorias USB (`M`), zoxide (`z`) y fzf (`f`). `?` enseña
  las teclas.
- **Editor: nvim con LazyVim** siguiendo al look: el colorscheme `discada`
  (`hypr/nvim/`) saca los colores del theme de kitty del look y
  el estilo de `look.json` (bordes de las ventanas flotantes, cómo se marca lo
  elegido, fósforo o tinta, transparencia) y se recarga solo al cambiar de look
  o de wallpaper.
- **Laptops**: batería en la barra (clic cambia el perfil de energía, clic
  derecho el ahorro), brillo y luz del teclado con sus teclas (el nivel sale en
  el aviso de arre), avisos al 20/10/5 %, y en el menú de ajustes. El **ahorro de
  batería** (`Battery.py`) pone el perfil power-saver, quita blur, sombras y
  shader, y pausa el video del wallpaper; se prende solo con
  `BATTERY_SAVER_AT` (20 %) y se apaga al conectar el cargador. Sin actividad
  baja el brillo a los 2.5 min y, solo con batería, suspende a los 15. En una de
  escritorio nada de esto aparece.
- **`FitGuard.py`**: las apps con tamaño mínimo (Discord) flotan centradas
  cuando su tile queda chico.
- **Herramientas del sistema: [vato](https://github.com/daniiiqa/vato)** —
  audio, bluetooth, red y sistema en una sola app de terminal, con el look como
  rola. Los módulos de la barra la abren en su pestaña (`Vato.sh`); también
  `vato` desde cualquier terminal.
- **Música: [rola](https://github.com/daniiiqa/rola)** — YouTube Music en la
  terminal. `rola --login` conecta tu cuenta. Cada look trae su
  `rola/look.json`.

## Estructura

```
hypr/
  hyprland.conf          solo hace `source` de conf/*
  conf/                  defaults, env, startup, settings, decorations,
                         animations, windowrules, keybinds, pinned, livewallpaper
  discada.conf           idioma, tamaño de letra (no se trackea; sale de hypr/seed/)
  recorder.conf          ajustes del grabador (no se trackea; sale de hypr/seed/)
  wallpapers/            wallpapers de los looks de paleta fija
  looks/<look>/          lo que cambia cada look
  scripts/               todos los scripts
  shaders/               screen shaders de los looks (outsider: grano)
waybar/  rofi/  swaync/  wlogout/  kitty/  sddm/  rola/
wallust/wallust.toml + templates/
```

## Notas

- Lo que cambia solo no se trackea: las copias vivas del look activo (salen
  de `hypr/looks/<look>/`), los colores que wallust genera con cada wallpaper
  y los ajustes de rola. `install.sh` pone copias de arranque de `hypr/seed/`
  si faltan.
- `hypr/wallpaper_effects/` y `hypr/looks/.current` están ignorados.

## Créditos

Varios scripts nacieron de los Hyprland-Dots de JaKooLit (GPL-3.0).
