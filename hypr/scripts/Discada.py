#!/usr/bin/env python3
"""El arte de "actualizar discada": la discada en la lumbre, meneada con la
cuchara, y un vaquero bailando cuando queda lista.

  Discada.py meneo [segundos]   la discada: cuchara, vapor, carne y lumbre (2.5 s)
  Discada.py lista [segundos]   el vaquero bailando: discada actualizada (2 s)

Solo se mueve en una terminal de verdad (si no, un renglón y ya) y sin
DISCADA_SIN_ARTE. Se borra/queda en su lugar: no pisa lo que viene después.
"""

import os
import shutil
import signal
import sys
import time

FPS = 8
W = 34  # ancho del dibujo

# los colores de la terminal (los de wallust en kitty): sin fijar hex
C = {
    "steam": "\033[2;37m",
    "spoon": "\033[1;33m",
    "rim": "\033[1;37m",
    "food": "\033[0;31m",
    "fat": "\033[0;33m",
    "fire": "\033[1;31m",
    "fire2": "\033[1;33m",
    "text": "\033[1;35m",
    "dim": "\033[2m",
    "off": "\033[0m",
}


def spanish():
    f = os.path.expanduser("~/.config/hypr/discada.conf")
    try:
        for line in open(f):
            if line.startswith("LANGUAGE="):
                return line.split("=", 1)[1].strip().startswith("es")
    except OSError:
        pass
    return False


ES = spanish()


def t(es, en):
    return es if ES else en


def paint(cells):
    """[(texto, color)] → un renglón con color."""
    return "".join(f"{C[c]}{s}{C['off']}" if c else s for s, c in cells)


# el vapor: tres versiones que se turnan (suben un renglón por cuadro)
STEAM = [
    "      (    )        (    )      ",
    "    )    (     (       )    (   ",
    "      (      )    (     )       ",
    "   (     )      )    (      )   ",
]


def meneo_frame(frame):
    """La discada de lado: la orilla de la col 2 a la 25, la carne adentro
    (cols 3–24) dando vueltas, la cuchara entrando de arriba a la derecha con la
    punta yendo y viniendo, vapor, patas y lumbre."""
    path = [6, 9, 12, 15, 18, 21, 18, 15, 12, 9]
    tip = path[frame % len(path)]

    grid = [[(" ", None)] * W for _ in range(9)]

    def put(r, c, ch, color):
        if 0 <= r < len(grid) and 0 <= c < W:
            grid[r][c] = (ch, color)

    # vapor (renglones 0–2), del más alto al más bajo, subiendo
    for r in range(3):
        line = STEAM[(frame // 2 + 2 - r) % len(STEAM)]
        for c, ch in enumerate(line[:W]):
            if ch != " " and 3 <= c <= 24:
                put(r, c, ch, "steam")
    # la orilla (renglón 3), la carne (4) y el fondo (5)
    for c in range(2, 26):
        put(3, c, "_", "rim")
    put(4, 2, "\\", "rim")
    put(4, 25, "/", "rim")
    food = "~°~ ·~ ~°~ ·~ ~°~ ·~ ~°"
    shift = frame % len(food)
    turned = food[shift:] + food[:shift]
    for k in range(22):
        ch = turned[k]
        put(4, 3 + k, ch, "food" if ch in "°·" else "fat")
    put(5, 3, "\\", "rim")
    for c in range(4, 24):
        put(5, c, "_", "rim")
    put(5, 24, "/", "rim")
    # la cuchara: la punta en la carne, el mango sube a la derecha
    put(4, tip, "U", "spoon")
    for k in range(1, 5):
        put(4 - k, tip + k, "/", "spoon")
    # las patas y la lumbre
    for c in (6, 21):
        put(6, c, "|", "rim")
    flames = "^ ^^ ^ ^^^ ^ ^^ ^"
    off = frame % 3
    for k in range(14):
        ch = flames[(k + off) % len(flames)]
        if ch != " ":
            put(7, 7 + k, ch, "fire" if (k + frame) % 2 else "fire2")
    rows = [paint(r) for r in grid[:8]]
    rows.append(paint([(f"   {t('meneando la discada…', 'stirring the discada…')}", "text")]))
    return rows


DANCE = [
    ["   \\o/  ", "    |   ", "   / \\  "],
    ["    o   ", "   /|\\  ", "   / \\  "],
    ["    o/  ", "   /|   ", "   / >  "],
    ["   \\o   ", "    |\\  ", "   < \\  "],
]


def lista_frame(frame):
    d = DANCE[frame % len(DANCE)]
    hat = "   _n_  "
    rows = [
        paint([(" " * 10 + hat, "spoon")]),
        paint([(" " * 10 + d[0], "rim")]),
        paint([(" " * 10 + d[1], "rim")]),
        paint([(" " * 10 + d[2], "rim")]),
        paint([("    " + ("♪ " if frame % 2 else " ♫") + " " * 18 + ("♫ " if frame % 2 else " ♪"), "fat")]),
        paint([(f"   {t('¡discada lista!', 'discada is ready!')}", "text")]),
    ]
    return rows


def play(make, seconds):
    if not sys.stdout.isatty() or os.environ.get("DISCADA_SIN_ARTE") or os.environ.get("TERM") == "dumb":
        import re
        print(re.sub(r"\033\[[0-9;]*m", "", make(0)[-1]).strip())
        return
    cols = shutil.get_terminal_size((80, 24)).columns
    pad = " " * max(0, (cols - W) // 2)
    first = make(0)
    height = len(first)
    out = sys.stdout

    def restore(*_):
        out.write("\033[?25h" + C["off"])
        out.flush()
        sys.exit(130)

    signal.signal(signal.SIGINT, restore)
    signal.signal(signal.SIGTERM, restore)
    out.write("\033[?25l")  # sin cursor mientras se mueve
    frames = max(1, int(seconds * FPS))
    for i in range(frames):
        lines = make(i)
        if i:
            out.write(f"\033[{height}F")  # al principio del dibujo
        for line in lines:
            out.write("\033[2K" + pad + line + "\n")
        out.flush()
        time.sleep(1 / FPS)
    out.write("\033[?25h")
    out.flush()


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "meneo"
    secs = float(sys.argv[2]) if len(sys.argv) > 2 else None
    if what == "meneo":
        play(meneo_frame, secs or 2.5)
    elif what == "lista":
        play(lista_frame, secs or 2.0)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
