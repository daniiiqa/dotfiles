#!/usr/bin/env python3
"""Visualizador de audio para waybar, y los controles del reproductor.

El módulo cava de waybar reacciona a cualquier sonido (llamadas de Discord
incluidas). Esto sigue a los reproductores con `playerctl -F` y solo corre
cava mientras alguno está en Playing. En pausa quedan las barras planas
(clase "paused") para poder darle click; sin reproductor el módulo se oculta.
Los clicks (anterior / pausa / siguiente) los pone el config de waybar.

El estilo lo elige cada look en ~/.config/waybar/visualizer.json:
  {"style": "braille" | "peaks" | "chars", "bars": 16, "chars": "▁▂▃▄▅▆▇█"}
  braille  dos barras finas por carácter (4 niveles)
  peaks    como braille pero solo el punto de arriba (una línea que baila)
  chars    un carácter por barra; "chars" va de silencio a máximo
Si el archivo cambia (LookSwitch), el script se reinicia solo.

Salida: una línea JSON por cuadro para un módulo custom de waybar sin
interval (modo continuo). Los colores los pone el CSS de cada look.
"""
import ctypes
import json
import os
import signal
import subprocess
import sys
import threading
import time

FPS = 24
# puntos braille de abajo hacia arriba: columna izquierda y derecha
LEFT = (0x40, 0x04, 0x02, 0x01)
RIGHT = (0x80, 0x20, 0x10, 0x08)
CONF = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-visualizer.cava")
LOOK = os.path.expanduser("~/.config/waybar/visualizer.json")


def lang():
    """Idioma de discada (hypr/discada.conf → LANGUAGE=es|en); por defecto inglés."""
    try:
        for line in open(os.path.expanduser("~/.config/hypr/discada.conf")):
            if line.startswith("LANGUAGE="):
                return "es" if line.split("=", 1)[1].split()[0] == "es" else "en"
    except (OSError, IndexError):
        pass
    return "en"


ES = lang() == "es"


def load_look():
    try:
        look = json.load(open(LOOK))
    except (OSError, ValueError):
        look = {}
    style = look.get("style", "braille")
    chars = look.get("chars", "▁▂▃▄▅▆▇█")
    if style not in ("braille", "peaks", "chars") or (style == "chars" and len(chars) < 2):
        style = "braille"
    bars = max(2, min(int(look.get("bars", 16)), 48))
    if style != "chars":
        bars += bars % 2  # braille: dos barras por carácter
    levels = len(chars) - 1 if style == "chars" else 4
    return style, bars, chars, levels


STYLE, BARS, CHARS, LEVELS = load_look()

CAVA_CONF = f"""
[general]
bars = {BARS}
framerate = {FPS}
sleep_timer = 0

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = {LEVELS}
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
monstercat = 1
noise_reduction = 77
"""

lock = threading.Lock()
cava = None
follow = None
tooltip = ""
restart = threading.Event()


def die_with_parent():
    # si este script muere (waybar recarga), cava muere con él
    ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG


def emit(text, klass=""):
    try:
        sys.stdout.write(json.dumps({"text": text, "class": klass, "tooltip": tooltip}) + "\n")
        sys.stdout.flush()
    except BrokenPipeError:
        os._exit(0)  # waybar cerró el pipe (recarga): salir sin ruido


def render(vals):
    # mínimo 1 (o el primer carácter): en silencio queda una línea, no un hueco
    vals = [max(0 if STYLE == "chars" else 1, min(v, LEVELS)) for v in vals]
    if STYLE == "chars":
        return "".join(CHARS[v] for v in vals)
    out = []
    for i in range(0, len(vals) - 1, 2):
        a, b = vals[i], vals[i + 1]
        if STYLE == "peaks":
            code = 0x2800 | LEFT[a - 1] | RIGHT[b - 1]
        else:
            code = 0x2800
            for n in range(a):
                code |= LEFT[n]
            for n in range(b):
                code |= RIGHT[n]
        out.append(chr(code))
    return "".join(out)


FLAT = render([0] * BARS)


def run_cava():
    global cava
    p = subprocess.Popen(["cava", "-p", CONF], stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, text=True, preexec_fn=die_with_parent)
    with lock:
        cava = p
    for line in p.stdout:
        vals = [v for v in line.strip().split(";") if v]
        if not vals:
            continue
        with lock:
            if cava is not p:
                break
            emit(render([int(v) for v in vals]), "playing")


def stop_cava(text="", klass=""):
    global cava
    with lock:
        p, cava = cava, None
    if p:
        p.terminate()
        try:
            p.wait(timeout=1)
        except subprocess.TimeoutExpired:
            p.kill()
    emit(text, klass)


def players():
    """[(estado, "artista - título")], los que suenan primero."""
    out = subprocess.run(
        ["playerctl", "--all-players", "metadata", "-f", "{{status}}\t{{artist}} - {{title}}"],
        capture_output=True, text=True).stdout
    rows = [tuple(l.split("\t", 1)) for l in out.splitlines() if "\t" in l]
    return sorted(rows, key=lambda r: r[0] != "Playing")


def watch_look():
    """Al cambiar de look o de idioma, reiniciar."""
    def mtime():
        # el estilo del look y el idioma (tooltip)
        out = []
        for f in (LOOK, os.path.expanduser("~/.config/hypr/discada.conf")):
            try:
                out.append(os.path.getmtime(f))
            except OSError:
                out.append(None)
        return out
    start = mtime()
    while True:
        time.sleep(1)
        if mtime() != start and follow:
            # main() sale del for al cortar playerctl y se reinicia
            restart.set()
            follow.terminate()
            return


def main():
    global follow, tooltip
    with open(CONF, "w") as f:
        f.write(CAVA_CONF)
    signal.signal(signal.SIGTERM, lambda *_: (stop_cava(), sys.exit(0)))
    threading.Thread(target=watch_look, daemon=True).start()
    emit("")
    # una línea por cambio de estado o de canción de cualquier reproductor
    follow = subprocess.Popen(
        ["playerctl", "--all-players", "-F", "metadata", "-f", "{{status}}{{title}}"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        preexec_fn=die_with_parent)
    for _ in follow.stdout:
        rows = [r for r in players() if r[0] in ("Playing", "Paused")]
        playing = bool(rows) and rows[0][0] == "Playing"
        if rows:
            icon = "\uf04b" if playing else "\uf04c"
            tooltip = (f"{icon} {rows[0][1]}".replace("&", "&amp;").replace("<", "&lt;")
                       + ("\nclick: anterior · medio: pausa · derecho: siguiente" if ES
                          else "\nclick: previous · middle: pause · right: next"))
        else:
            tooltip = ""
        with lock:
            running = cava is not None
        if playing and not running:
            threading.Thread(target=run_cava, daemon=True).start()
        elif not playing:
            stop_cava(FLAT if rows else "", "paused" if rows else "")
    if restart.is_set():
        stop_cava()
        os.execv(sys.executable, [sys.executable] + sys.argv)


if __name__ == "__main__":
    main()
