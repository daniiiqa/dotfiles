# dotfiles — rice de Hyprland

Rice minimal: barra flotante delgada, un solo acento por tema y colores que
salen del wallpaper (incluidos los de video) vía wallust.

## Qué trackea

Solo las carpetas del rice (whitelist en `.gitignore`): `hypr`, `waybar`, `rofi`,
`swaync`, `wallust`, `kitty`, `cava`, `btop`, `fastfetch`, `wlogout`,
`Kvantum`, `qt5ct`, `qt6ct`, `swappy`. Todo lo demás de `~/.config` se ignora.

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

```bash
# 1. Paquetes (Arch): hyprland, hypridle, hyprlock, waybar, rofi-wayland,
#    swaync, swww, mpvpaper (AUR), wallust, kitty, wlogout, cliphist, yad,
#    nwg-displays, nwg-look, qt5ct, qt6ct, kvantum, sddm
# 2. Clonar encima de ~/.config (respeta lo que ya exista fuera del whitelist):
cd ~/.config
git init -b main
git remote add origin <URL-del-repo>
git fetch origin
git checkout -f main   # ojo: pisa las carpetas del rice si ya existían
# 3. Sesión: cerrar sesión y entrar a Hyprland desde SDDM
```

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
- **`FitGuard.py`**: las apps con tamaño mínimo (Discord no baja de 832x542)
  flotan centradas cuando el layout les da un tile más chico, y vuelven al
  tile cuando les tocaría media pantalla. La tabla de mínimos va en el script.
- **Legibilidad con cualquier wallpaper**: wallust con `check_contrast` y luego
  `ContrastFix.py` sube a 4.5:1 (WCAG AA) cualquier color de texto que haya
  quedado pegado al fondo, y re-renderiza todos los templates.
- **Atajos**: `SUPER+H` cheat sheet, `SUPER+Shift+K` buscador (lee directo de
  `conf/keybinds.conf`), `SUPER+Shift+E` ajustes rápidos.
- `Tak0-*.sh` — cambio de layout de teclado por ventana / autodispatch.

## Notas

- Los colores generados por wallust (`waybar/wallust/`, `rofi/wallust/`, etc.)
  sí se trackean para que un clone fresco arranque con un tema funcional;
  cambian con cada wallpaper, así que generan diffs — commitear cuando se quiera.
- `hypr/wallpaper_effects/` (binarios del wallpaper actual) está ignorado.

## Créditos

Varios scripts nacieron de los Hyprland-Dots de JaKooLit (GPL-3.0).
