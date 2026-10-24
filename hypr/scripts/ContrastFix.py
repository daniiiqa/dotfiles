#!/usr/bin/env python3
"""Garantiza que los colores de wallust se lean sobre el fondo.

Con algunos wallpapers wallust saca acentos casi del color del fondo (texto
invisible en waybar/rofi/swaync). Esto lee la paleta recién generada (del
template de kitty, que trae todos los colores), sube cada color de texto a un
contraste mínimo contra el fondo conservando su tono, y si cambió algo vuelve
a renderizar TODOS los templates con `wallust cs`, así waybar, rofi, hypr,
kitty y cava quedan iguales entre sí.

color0 y color8 no se tocan: son superficies/bordes, no texto.
Lo llama WallustSwww.sh después de `wallust run`.
"""
import colorsys
import json
import os
import re
import subprocess
import sys

KITTY = os.path.expanduser("~/.config/kitty/kitty-themes/01-Wallust.conf")
OUT = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "wallust-contrast.json")
MIN_TEXT = 4.5   # WCAG AA para texto normal
MIN_FG = 7.0
MARGIN = 0.25    # wallust cs redondea al re-renderizar; se sube un poco de más
TEXT_COLORS = [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]


def rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


def hexc(c):
    return "#" + "".join(f"{round(max(0, min(1, v)) * 255):02X}" for v in c)


def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = map(f, c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def lift(color, bg, target):
    """Aclara (fondo oscuro) u oscurece (fondo claro) en HLS hasta el contraste."""
    if ratio(color, bg) >= target:
        return color
    target += MARGIN
    h, l, s = colorsys.rgb_to_hls(*color)
    step = 0.01 if lum(bg) < 0.5 else -0.01
    while 0 <= l <= 1:
        l += step
        c = colorsys.hls_to_rgb(h, max(0, min(1, l)), s)
        if ratio(c, bg) >= target:
            return c
    return (1, 1, 1) if step > 0 else (0, 0, 0)


def main():
    try:
        t = open(KITTY).read()
    except OSError:
        return
    get = lambda k: re.search(r"^%s\s+(#[0-9A-Fa-f]{6})" % k, t, re.M).group(1).upper()
    try:
        special = {k: get(k) for k in ("background", "foreground", "cursor")}
        colors = {f"color{i}": get(f"color{i}") for i in range(16)}
    except AttributeError:
        return  # template incompleto: no adivinar

    bg = rgb(special["background"])
    changed = []
    fg = hexc(lift(rgb(special["foreground"]), bg, MIN_FG))
    if fg != special["foreground"]:
        changed.append(f"foreground {special['foreground']}→{fg}")
        special["foreground"] = fg
    for i in TEXT_COLORS:
        k = f"color{i}"
        new = hexc(lift(rgb(colors[k]), bg, MIN_TEXT))
        if new != colors[k]:
            changed.append(f"{k} {colors[k]}→{new}")
            colors[k] = new

    if not changed:
        return
    json.dump({"special": special, "colors": colors}, open(OUT, "w"))
    subprocess.run(["wallust", "cs", "-f", "pywal", "-s", "-q", OUT])
    if "-v" in sys.argv:
        print("\n".join(changed))


if __name__ == "__main__":
    main()
