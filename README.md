# dotfiles — rice de Hyprland

Mi versión propia del rice, originalmente basada en los
[Hyprland-Dots de JaKooLit](https://github.com/JaKooLit/Hyprland-Dots) (v2.3.20),
ahora auto-gestionada. **El updater de KooL está desactivado a propósito** —
cualquier cambio entra por git, no por `copy.sh`.

## Qué trackea

Solo las carpetas del rice (whitelist en `.gitignore`): `hypr`, `waybar`, `rofi`,
`swaync`, `wallust`, `kitty`, `ghostty`, `cava`, `btop`, `fastfetch`, `wlogout`,
`Kvantum`, `qt5ct`, `qt6ct`, `quickshell`, `swappy`, `wezterm`.
Todo lo demás de `~/.config` se ignora.

## Instalar en una máquina nueva

```bash
# 1. Paquetes base (Arch): hyprland, waybar, rofi-wayland, swaync, swww,
#    wallust, kitty, sddm, y lo que uses de: ghostty, cava, btop, fastfetch, wlogout
# 2. Clonar encima de ~/.config (respeta lo que ya exista fuera del whitelist):
cd ~/.config
git init -b main
git remote add origin <URL-del-repo>
git fetch origin
git checkout -f main   # ojo: pisa las carpetas del rice si ya existían
# 3. Sesión: cerrar sesión y entrar a Hyprland desde SDDM
```

## Piezas custom (no vienen de KooL)

- **Wallpapers independientes por monitor**: swww (imágenes/gifs) siempre vivo;
  mpvpaper una instancia por monitor solo donde hay video. La persistencia vive
  en `hypr/UserConfigs/LiveWallpaper.conf` (regenerado por WallpaperSelect.sh).
  Requiere `mpvpaper` (AUR). GameMode pausa video+swww y los revive al salir.
- **El theme cambia también con wallpapers vivos**: WallpaperSelect.sh extrae el
  fotograma de en medio del video (cache en `~/.cache/video_frame/`) y lo pasa
  por wallust — mismos colores en waybar/rofi/kitty y mismo fondo en SDDM.
- **`hypr/scripts/Refresh.sh` recarga en caliente** (waybar SIGUSR2, swaync-client);
  ya no mata/relanza, la barra no parpadea al cambiar de fondo.

- `hypr/UserScripts/SDDMWallpaperSync.sh` — sincroniza wallpaper + colores de
  wallust al tema `simple_sddm_2` de SDDM, silencioso y sin sudo (requiere que
  el tema en `/usr/share/sddm/themes/simple_sddm_2` sea escribible por el usuario).
  Se dispara desde el final de `hypr/scripts/WallustSwww.sh`.
- `waybar/config` sin `group/laptop` y `waybar/Modules` con `"bat": "BAT0"` —
  fix del crash de waybar al desconectar un control bluetooth (el módulo battery
  adoptaba la batería del control y tronaba al desaparecer el nodo).
- `hypr/scripts/Tak0-*.sh`, `hypr/UserScripts/Tak0-*.sh` — scripts propios.
- `hypr/scripts/KooLsDotsUpdate.sh` — neutralizado: solo avisa que la config
  es auto-gestionada.

## Notas

- Los colores generados por wallust (`waybar/wallust/`, `rofi/wallust/`, etc.)
  sí se trackean para que un clone fresco arranque con un tema funcional;
  cambian con cada wallpaper, así que generan diffs — commitear cuando se quiera.
- `hypr/wallpaper_effects/` (binarios del wallpaper actual) está ignorado.
