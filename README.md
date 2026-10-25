# dotfiles — rice de Hyprland

Rice minimal: barra flotante delgada, un solo acento por tema y colores que
salen del wallpaper (incluidos los de video) vía wallust.

## Qué trackea

Solo las carpetas del rice (whitelist en `.gitignore`): `hypr`, `waybar`, `rofi`,
`swaync`, `wallust`, `kitty`, `cava`, `btop`, `fastfetch`, `wlogout`, `yazi`,
`ytm`, `Kvantum`, `qt5ct`, `qt6ct`, `swappy`. Todo lo demás de `~/.config` se ignora.

## Estructura

```
hypr/
  hyprland.conf          solo hace `source` de conf/*
  conf/                  defaults, env, startup, settings, decorations,
                         animations, windowrules, keybinds, livewallpaper
  monitors.conf          los escribe nwg-displays
  workspaces.conf
  hypridle.conf / hyprlock.conf
  scripts/               todos los scripts
  wallust/               colores generados para Hyprland
  shaders/               screen shaders de los looks (outsider: grano)
waybar/config, style.css
rofi/config.rasi + themes/Dany-*.rasi (uno por look), menu.rasi (base de los
                         menús -dmenu) + un config-*.rasi por menú
swaync/  wlogout/  kitty/
wallust/wallust.toml + templates/
```

## Instalar en una máquina nueva

En un Arch recién instalado (con internet y tu usuario con sudo):

```bash
curl -fsSL https://raw.githubusercontent.com/daniiiqa/dotfiles/main/install.sh | bash
```

Eso es todo: al terminar ofrece reiniciar, entras a Hyprland desde SDDM y
el primer arranque pone un wallpaper, genera los colores y muestra los
atajos. Tus wallpapers (imágenes o videos) van en `~/Pictures/wallpapers`.

Qué hace `install.sh` (también se puede correr desde un clone: `./install.sh`,
y `--dry-run` muestra todo sin tocar nada):

- clona el repo en `~/dotfiles` si se corrió con curl
- paquetes: repos oficiales con pacman; swww, mpvpaper, wallust y wlogout de
  AUR con yay/paru (si no hay ninguno, instala yay)
- copia las carpetas del rice a `~/.config`, respaldando lo que pise en
  `~/.config-backup-<fecha>/`; las pantallas quedan en detección automática
- yazi como explorador por defecto, NetworkManager y bluetooth activos
- SDDM con el tema simple_sddm_2 si no hay otro display manager
  (`--no-sddm` / `--sddm` para forzar)
- en el primer login, `hypr/scripts/FirstRun.sh` termina el resto (wallpaper
  generado si no hay ninguno, colores, tema oscuro e iconos para GTK)

Se puede correr varias veces sin romper nada.

## Piezas

- **Wallpapers independientes por monitor**: swww (imágenes/gifs) siempre vivo;
  mpvpaper una instancia por monitor solo donde hay video. La persistencia vive
  en `hypr/conf/livewallpaper.conf` (regenerado por `WallpaperSelect.sh`).
  GameMode pausa video+swww y los revive al salir.
- **El theme cambia también con wallpapers vivos**: `WallpaperSelect.sh` extrae el
  fotograma de en medio del video (cache en `~/.cache/video_frame/`) y lo pasa
  por wallust — mismos colores en waybar/rofi/kitty/swaync/hyprlock y en SDDM.
- **`Refresh.sh` recarga en caliente** (waybar SIGUSR2, swaync-client); no
  mata/relanza, la barra no parpadea al cambiar de fondo.
- **`SDDMWallpaperSync.sh`** — sincroniza wallpaper + colores de wallust al tema
  `simple_sddm_2` de SDDM, silencioso y sin sudo (requiere que
  `/usr/share/sddm/themes/simple_sddm_2` sea escribible por el usuario).
  Se dispara al final de `WallustSwww.sh`.
- **Looks** (`SUPER+T`): `hypr/looks/<nombre>/` guarda los archivos que cambian
  por look (decoraciones, animaciones, hyprlock, waybar, rofi, swaync, wlogout,
  kitty, fastfetch y la paleta de wallust). `LookSwitch.sh` guarda lo vivo en el look
  actual y copia el nuevo encima. Looks: minimal, classic, brutalist, pastel, glass, retro, neon, paper, nord, outsider.
- **Apps abiertas en la barra** (`AppStrip.py`): un daemon escucha los eventos
  de Hyprland y waybar muestra un icono por app (iconos de la fuente, teñidos
  por el look). Con 6+ apps abiertas se colapsan en un botón que se despliega
  al pasar el mouse. Click enfoca (o cicla ventanas), click medio cierra.
  Las fijadas en `hypr/conf/pinned.conf` siempre se ven; cerradas salen
  tenues y el click las abre.
- **Archivos: yazi** en kitty (`SUPER+E`, y también para "abrir carpeta" desde
  apps vía `~/.local/share/applications/yazi-kitty.desktop`). Colores e iconos
  con nombres ANSI → sigue al look y al wallpaper sin configurar nada.
- **`FitGuard.py`**: las apps con tamaño mínimo (Discord no baja de 832x542)
  flotan centradas cuando el layout les da un tile más chico, y vuelven al
  tile cuando les tocaría media pantalla. La tabla de mínimos va en el script.
- **Legibilidad con cualquier wallpaper**: wallust con `check_contrast` y luego
  `ContrastFix.py` sube a 4.5:1 (WCAG AA) cualquier color de texto que haya
  quedado pegado al fondo, y re-renderiza todos los templates.
- **Atajos**: `SUPER+H` cheat sheet, `SUPER+Shift+K` buscador (lee directo de
  `conf/keybinds.conf`), `SUPER+Shift+E` ajustes rápidos.
- `Tak0-*.sh` — cambio de layout de teclado por ventana / autodispatch.
- **Música: [ytm](https://github.com/daniiiqa/ytm)** — YouTube Music en la
  terminal (mpv + mpv-mpris, así sale en el módulo mpris de waybar).
  `install.sh` lo compila a `~/.local/bin/ytm`; `ytm --login` conecta la cuenta.
  Ajustes en `ytm/config.json`; cada look trae su `ytm/look.json` (bordes,
  mayúsculas, barra, color) y los colores salen del theme de kitty, así que
  sigue al look y al wallpaper solo.

## Notas

- Los colores generados por wallust (`waybar/wallust/`, `rofi/wallust/`, etc.)
  sí se trackean para que un clone fresco arranque con un tema funcional;
  cambian con cada wallpaper, así que generan diffs — commitear cuando se quiera.
- `hypr/wallpaper_effects/` (binarios del wallpaper actual) está ignorado.

## Créditos

Varios scripts nacieron de los Hyprland-Dots de JaKooLit (GPL-3.0).
