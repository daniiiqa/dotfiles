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
- paquetes: repos oficiales con pacman; swww, mpvpaper, wallust y wlogout de
  AUR con yay/paru (si no hay ninguno, instala yay). Solo las fuentes de los
  looks que elegiste
- copia las carpetas del rice a `~/.config`, respaldando lo que pise en
  `~/.config-backup-<fecha>/`; las pantallas quedan en detección automática
- yazi como explorador por defecto, NetworkManager y bluetooth activos
- SDDM con el tema simple_sddm_2 si no hay otro display manager
  (`--no-sddm` / `--sddm` para forzar)
- compila [rola](https://github.com/daniiiqa/rola) en `~/.local/bin`
- en el primer login, `hypr/scripts/FirstRun.sh` termina el resto (wallpaper
  generado si no hay ninguno, colores, tema oscuro e iconos para GTK)

Se puede correr varias veces sin romper nada.

## Lo esencial

| teclas | |
|---|---|
| `SUPER+H` | cheat sheet (con el estilo del look, escribe para filtrar) |
| `SUPER+Shift+E` | **ajustes de discada**: look, shader, idioma, visualizador, grabador, game mode, blur, editar config, herramientas |
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
grabador), rofi, swaync, wlogout, kitty, fastfetch, rola, SDDM y la paleta de
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
- **Login (SDDM)**: sigue al look (fuente, forma, paleta) y a los colores del
  wallpaper, sin sudo (`SDDMWallpaperSync.sh`).
- **Wallpapers por monitor**: swww para imágenes/gifs, un mpvpaper por monitor
  solo donde hay video. Game mode los pausa y los revive al salir.
- **Colores desde wallpapers de video**: el fotograma de en medio pasa por
  wallust, así waybar, rofi, kitty, swaync, hyprlock y SDDM combinan.
- **Legible con cualquier wallpaper**: wallust con `check_contrast` y luego
  `ContrastFix.py` sube cualquier color de texto a 4.5:1 (WCAG AA).
- **Archivos: yazi** en kitty (`SUPER+E`, y para "abrir carpeta" desde apps).
- **`FitGuard.py`**: las apps con tamaño mínimo (Discord) flotan centradas
  cuando su tile queda chico.
- **Música: [rola](https://github.com/daniiiqa/rola)** — YouTube Music en la
  terminal. `rola --login` conecta tu cuenta. Cada look trae su
  `rola/look.json`.

## Estructura

```
hypr/
  hyprland.conf          solo hace `source` de conf/*
  conf/                  defaults, env, startup, settings, decorations,
                         animations, windowrules, keybinds, pinned, livewallpaper
  discada.conf           idioma
  recorder.conf          ajustes del grabador
  looks/<look>/          lo que cambia cada look
  scripts/               todos los scripts
  shaders/               screen shaders de los looks (outsider: grano)
waybar/  rofi/  swaync/  wlogout/  kitty/  sddm/  rola/
wallust/wallust.toml + templates/
```

## Notas

- Los colores generados por wallust (`waybar/wallust/`, `rofi/wallust/`, …) sí
  se trackean para que un clone fresco arranque con un tema funcional; cambian
  con cada wallpaper, así que salen en los diffs.
- `hypr/wallpaper_effects/` y `hypr/looks/.current` están ignorados.

## Créditos

Varios scripts nacieron de los Hyprland-Dots de JaKooLit (GPL-3.0).
