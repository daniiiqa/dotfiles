# Semillas

Copias de arranque de archivos que **no** se trackean porque cambian solos:
los colores que wallust genera con cada wallpaper (waybar, rofi, hypr, kitty,
cava), los ajustes de rola (`rola/config.json`, rola los reescribe), los de
discada y del grabador (`hypr/discada.conf`, `hypr/recorder.conf`, los cambia
el menú) y los videos de fondo (`hypr/conf/livewallpaper.conf`). En una
máquina nueva `install.sh` los copia a `~/.config` solo si no existen; desde
ahí wallust y rola los mantienen.

Los demás archivos vivos (waybar/config, kitty/kitty.conf, …) tampoco se
trackean: son copias del look activo y salen de `hypr/looks/<look>/`.
