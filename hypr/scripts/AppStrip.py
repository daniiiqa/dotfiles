#!/usr/bin/env python3
"""Apps abiertas en waybar, con iconos de la fuente (los tiñe cada look).

  AppStrip.py daemon        escucha los eventos de Hyprland (socket2) y escribe
                            un archivo por slot en $XDG_RUNTIME_DIR/appstrip/;
                            luego avisa a waybar con SIGRTMIN+9
  AppStrip.py focus SLOT    enfoca la app del slot (si ya está enfocada, cicla
                            entre sus ventanas)
  AppStrip.py close SLOT    cierra la ventana más reciente de esa app

Slots: i1..i5 = en línea (con 1-5 apps); more = botón del menú y d1..d8 =
el cajón que se despliega (con 6+ apps). Un slot vacío escribe texto ""
y waybar lo oculta. Una app = una class; las ventanas en workspaces
especiales (dropterm, scratchpad) no cuentan.
"""
import json
import os
import re
import socket
import subprocess
import sys
import time

RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "appstrip")
SIG = 9
INLINE_MAX = 5
DRAWER_SLOTS = 8

# (regex sobre la class en minúsculas, glyph, nombre bonito)
ICONS = [
    (r"^kitty", "", "Terminal"),
    (r"^(zen|zen-browser)$", "", "Zen"),
    (r"firefox", "", "Firefox"),
    (r"^discord|vesktop", "\U000f066f", "Discord"),
    (r"^steam$", "\U000f04d3", "Steam"),
    (r"^steam_app_|gamescope|lutris|catalyst", "\U000f02b4", "Juego"),
    (r"prismlauncher", "\U000f0373", "Prism Launcher"),
    (r"thunar|nautilus", "", "Archivos"),
    (r"spotify", "", "Spotify"),
    (r"godot", "", "Godot"),
    (r"^(mpv|vlc)$", "", "Video"),
    (r"pavucontrol|pwvucontrol", "", "Audio"),
    (r"github", "", "GitHub Desktop"),
    (r"obsidian", "", "Obsidian"),
    (r"gimp|krita|aseprite", "", "Arte"),
    (r"blender", "", "Blender"),
    (r"code|codium|zed", "", "Editor"),
    (r"qalculate|calculator", "", "Calculadora"),
    (r"mousepad|texteditor", "", "Texto"),
    (r"nwg-|qt[56]ct|kvantum|blueman|nm-connection", "", "Ajustes"),
]
DEFAULT = ("", None)
MORE_ICON = ""


def icon_for(cls):
    low = cls.lower()
    for rx, glyph, name in ICONS:
        if re.search(rx, low):
            return glyph, name
    return DEFAULT[0], cls


def hypr(*args):
    out = subprocess.run(["hyprctl", *args], capture_output=True, text=True).stdout
    return json.loads(out) if "-j" in args else out


def visible_clients():
    return [c for c in hypr("clients", "-j")
            if c["mapped"] and c["workspace"]["id"] > 0 and c["class"]]


def write(slot, text="", cls="", tooltip="", klass=()):
    with open(os.path.join(RUN, slot), "w") as f:
        json.dump({"text": text, "tooltip": tooltip, "class": list(klass)}, f,
                  ensure_ascii=False)
        f.write("\n")
    with open(os.path.join(RUN, slot + ".class"), "w") as f:
        f.write(cls)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


order = []  # classes en orden de aparición (estable mientras sigan abiertas)


def render():
    clients = visible_clients()
    active = hypr("activewindow", "-j") or {}
    active_cls = active.get("class", "") if isinstance(active, dict) else ""

    apps = {}
    for c in clients:
        apps.setdefault(c["class"], []).append(c)
    for cls in apps:
        if cls not in order:
            order.append(cls)
    order[:] = [c for c in order if c in apps]

    entries = []
    for cls in order:
        glyph, name = icon_for(cls)
        wins = apps[cls]
        titles = "\n".join("· " + esc(w["title"][:60]) for w in wins)
        tip = f"<b>{esc(name)}</b>" + (f"  ({len(wins)})" if len(wins) > 1 else "")
        tip += "\n" + titles + "\nclick: enfocar · medio: cerrar"
        klass = ["app"] + (["active"] if cls == active_cls else []) + \
                (["multi"] if len(wins) > 1 else [])
        entries.append((glyph, cls, tip, klass))

    collapsed = len(entries) > INLINE_MAX
    for i in range(INLINE_MAX):
        slot = f"i{i + 1}"
        if not collapsed and i < len(entries):
            g, cls, tip, k = entries[i]
            write(slot, g, cls, tip, k)
        else:
            write(slot)

    if collapsed:
        names = "\n".join("· " + esc(icon_for(c)[1]) for c in order)
        k = ["app-more"] + (["active"] if active_cls in apps else [])
        write("more", f"{MORE_ICON} {len(entries)}", "",
              f"<b>{len(entries)} apps abiertas</b>\n{names}\npasa el mouse para verlas", k)
    else:
        write("more")
    for i in range(DRAWER_SLOTS):
        slot = f"d{i + 1}"
        if collapsed and i < len(entries):
            g, cls, tip, k = entries[i]
            write(slot, g, cls, tip, k)
        else:
            write(slot)

    subprocess.run(["pkill", f"-RTMIN+{SIG}", "-x", "waybar"])


def daemon():
    os.makedirs(RUN, exist_ok=True)
    # una sola instancia
    lock = os.path.join(RUN, "daemon.pid")
    try:
        old = int(open(lock).read())
        if old != os.getpid() and os.path.exists(f"/proc/{old}") and \
                "AppStrip" in open(f"/proc/{old}/cmdline").read():
            sys.exit(0)
    except (OSError, ValueError):
        pass
    open(lock, "w").write(str(os.getpid()))

    sock_path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                             os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
    wanted = ("openwindow", "closewindow", "movewindow", "activewindow",
              "changefloatingmode", "configreloaded")
    render()
    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            buf = b""
            s.settimeout(None)
            while True:
                data = s.recv(4096)
                if not data:
                    break
                buf += data
                lines = buf.split(b"\n")
                buf = lines.pop()
                if any(l.split(b">>")[0].decode(errors="ignore").startswith(wanted)
                       for l in lines):
                    # juntar ráfagas de eventos (abrir una app dispara varios)
                    s.settimeout(0.05)
                    try:
                        while True:
                            more = s.recv(4096)
                            if not more:
                                break
                            buf += more
                    except socket.timeout:
                        pass
                    s.settimeout(None)
                    buf = buf.split(b"\n")[-1]  # lo ya leído se descarta
                    render()
        except OSError:
            time.sleep(1)


def windows_of(slot):
    try:
        cls = open(os.path.join(RUN, slot + ".class")).read().strip()
    except OSError:
        return [], None
    wins = [c for c in visible_clients() if c["class"] == cls]
    wins.sort(key=lambda c: c["focusHistoryID"])  # 0 = la más reciente
    return wins, cls


def focus(slot):
    wins, cls = windows_of(slot)
    if not wins:
        return
    active = hypr("activewindow", "-j") or {}
    target = wins[0]
    if isinstance(active, dict) and active.get("class") == cls and len(wins) > 1:
        target = wins[-1]  # ya está enfocada: ir a la ventana menos reciente
    hypr("dispatch", "focuswindow", f"address:{target['address']}")


def close(slot):
    wins, _ = windows_of(slot)
    if wins:
        hypr("dispatch", "closewindow", f"address:{wins[0]['address']}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "daemon":
        daemon()
    elif cmd == "focus" and len(sys.argv) > 2:
        focus(sys.argv[2])
    elif cmd == "close" and len(sys.argv) > 2:
        close(sys.argv[2])
    else:
        print(__doc__)
        sys.exit(2)
