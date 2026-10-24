#!/usr/bin/env python3
"""Apps que no caben en su tile flotan solas, y vuelven al tile cuando cabe.

Algunas apps tienen tamaño mínimo (Discord no baja de 832x542). Si el layout
les da un tile más chico, Hyprland las recorta. Este daemon escucha los
eventos de ventanas y:
  - si una app de MIN_SIZE queda azulejada en un tile más chico que su
    mínimo, la pone flotante, centrada y a FLOAT_SIZE;
  - si una ventana que flotó él queda con a lo más una ventana azulejada más
    en su workspace (o sea, le tocaría media pantalla), la regresa al tile.
Las ventanas que flotas tú a mano no se tocan.

Hyprland no expone el tamaño mínimo de una ventana: va en la tabla.
Para medir otra app: flotarla, encogerla al mínimo y ver `hyprctl clients`.
"""
import json
import os
import socket
import subprocess
import sys
import time

# class → (ancho, alto) mínimos que acepta la app
MIN_SIZE = {
    "discord": (832, 542),
}
FLOAT_SIZE = (1100, 700)

floated = set()   # direcciones que flotó este daemon
retried = {}      # dirección → nº de ventanas cuando se re-azulejó (evita ciclos)


def hypr(*args):
    out = subprocess.run(["hyprctl", *args], capture_output=True, text=True).stdout
    return json.loads(out) if "-j" in args else out


def float_centered(c, monitors):
    mon = next((m for m in monitors if m["id"] == c["monitor"]), monitors[0])
    rl, rt, rr, rb = mon["reserved"]
    aw, ah = mon["width"] - rl - rr, mon["height"] - rt - rb
    w, h = min(FLOAT_SIZE[0], aw - 40), min(FLOAT_SIZE[1], ah - 40)
    x, y = mon["x"] + rl + (aw - w) // 2, mon["y"] + rt + (ah - h) // 2
    a = c["address"]
    hypr("--batch", f"dispatch setfloating address:{a}; "
                    f"dispatch resizewindowpixel exact {w} {h},address:{a}; "
                    f"dispatch movewindowpixel exact {x} {y},address:{a}")
    floated.add(a)


def check():
    clients = [c for c in hypr("clients", "-j") if c["mapped"] and c["workspace"]["id"] > 0]
    alive = {c["address"] for c in clients}
    floated.intersection_update(alive)
    for a in list(retried):
        if a not in alive:
            del retried[a]

    monitors = None
    for c in clients:
        mn = MIN_SIZE.get(c["class"].lower())
        if not mn or c["fullscreen"]:
            continue
        a, ws = c["address"], c["workspace"]["id"]
        others = sum(1 for o in clients if o["workspace"]["id"] == ws
                     and not o["floating"] and o["address"] != a)
        w, h = c["size"]
        if not c["floating"] and (w < mn[0] or h < mn[1]):
            # si fue re-azulejada y no cupo, retried[a] ya guarda el nº de
            # ventanas: no se reintenta hasta que ese número cambie
            monitors = monitors or hypr("monitors", "-j")
            float_centered(c, monitors)
        elif c["floating"] and a in floated and others <= 1 and retried.get(a) != others:
            floated.discard(a)
            retried[a] = others
            hypr("dispatch", "settiled", f"address:{a}")


def main():
    sock_path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                             os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
    wanted = (b"openwindow>>", b"closewindow>>", b"movewindow>>", b"movewindowv2>>")
    check()
    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            buf = b""
            while True:
                data = s.recv(4096)
                if not data:
                    break
                buf += data
                lines = buf.split(b"\n")
                buf = lines.pop()
                if any(l.startswith(wanted) for l in lines):
                    # dejar que el layout se acomode (y juntar ráfagas)
                    s.settimeout(0.15)
                    try:
                        while s.recv(4096):
                            pass
                    except socket.timeout:
                        pass
                    s.settimeout(None)
                    buf = b""
                    check()
        except OSError:
            time.sleep(1)


if __name__ == "__main__":
    # una sola instancia
    lock = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "fitguard.pid")
    try:
        old = int(open(lock).read())
        if os.path.exists(f"/proc/{old}") and "FitGuard" in open(f"/proc/{old}/cmdline").read():
            sys.exit(0)
    except (OSError, ValueError):
        pass
    open(lock, "w").write(str(os.getpid()))
    main()
