#!/usr/bin/env python3
"""Visualizador de audio para waybar: solo mientras suena música.

El módulo cava de waybar reacciona a cualquier sonido (llamadas de Discord
incluidas). Esto sigue el estado de los reproductores con
`playerctl -F status` y solo corre cava mientras alguno está en Playing; al
pausar, cava se apaga y el módulo se oculta (texto vacío).

Salida: una línea JSON por cuadro para un módulo custom de waybar sin
interval (modo continuo). Los colores los pone el CSS de cada look (.playing).
"""
import ctypes
import json
import os
import signal
import subprocess
import sys
import threading

BARS = 16          # dos barras por carácter braille → 8 caracteres
FPS = 24
LEVELS = 4         # alto de una columna braille
# puntos braille de abajo hacia arriba: columna izquierda y derecha
LEFT = (0x40, 0x04, 0x02, 0x01)
RIGHT = (0x80, 0x20, 0x10, 0x08)
CONF = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-visualizer.cava")

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


def die_with_parent():
    # si este script muere (waybar recarga), cava muere con él
    ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG


def emit(text, klass=""):
    try:
        sys.stdout.write(json.dumps({"text": text, "class": klass, "tooltip": ""}) + "\n")
        sys.stdout.flush()
    except BrokenPipeError:
        os._exit(0)  # waybar cerró el pipe (recarga): salir sin ruido


def braille(vals):
    """Barras finas: cada carácter braille dibuja dos columnas de 4 niveles."""
    out = []
    for i in range(0, len(vals) - 1, 2):
        # mínimo 1: en silencio queda una línea de puntos, no un hueco
        a, b = max(1, min(vals[i], LEVELS)), max(1, min(vals[i + 1], LEVELS))
        code = 0x2800
        for n in range(a):
            code |= LEFT[n]
        for n in range(b):
            code |= RIGHT[n]
        out.append(chr(code))
    return "".join(out)


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
            emit(braille([int(v) for v in vals]), "playing")


def stop_cava():
    global cava
    with lock:
        p, cava = cava, None
    if p:
        p.terminate()
        try:
            p.wait(timeout=1)
        except subprocess.TimeoutExpired:
            p.kill()
    emit("")


def main():
    with open(CONF, "w") as f:
        f.write(CAVA_CONF)
    signal.signal(signal.SIGTERM, lambda *_: (stop_cava(), sys.exit(0)))
    emit("")
    # una línea por cambio de estado de cualquier reproductor
    follow = subprocess.Popen(
        ["playerctl", "--all-players", "-F", "status", "-f", "{{status}}"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        preexec_fn=die_with_parent)
    for _ in follow.stdout:
        # con varios reproductores, basta con que uno esté sonando
        statuses = subprocess.run(["playerctl", "--all-players", "status"],
                                  capture_output=True, text=True).stdout.split()
        playing = "Playing" in statuses
        with lock:
            running = cava is not None
        if playing and not running:
            threading.Thread(target=run_cava, daemon=True).start()
        elif not playing and running:
            stop_cava()


if __name__ == "__main__":
    main()
