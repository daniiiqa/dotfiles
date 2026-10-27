#!/usr/bin/env python3
"""Batería y ahorro de energía de discada (laptops; en una de escritorio no hace nada).

  Battery.py status        JSON para el módulo custom/battery de waybar
  Battery.py watch         daemon: avisos de batería baja, ahorro automático
                           y refresca la barra al conectar/desconectar
  Battery.py profile       siguiente perfil de energía (power-profiles-daemon)
  Battery.py saver [on|off|toggle]
  Battery.py idle-suspend  suspende solo si está con batería (lo llama hypridle)
  Battery.py has           sale con 0 si hay batería de laptop (exec-if)

El ahorro: perfil power-saver, sin blur, sombras ni shader del look y los
wallpapers de video en pausa. Se prende solo con BATTERY_SAVER_AT por ciento
(hypr/discada.conf, 0 = nunca) y se apaga solo al conectar el cargador si se
había prendido solo. Sobrevive a los reload de Hyprland (cambiar de look):
el daemon lo vuelve a poner con cada configreloaded.
"""
import json
import os
import selectors
import shutil
import socket
import subprocess
import sys
import time

PS = "/sys/class/power_supply"
RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "discada")
STATE = os.path.join(RUN, "saver.json")
DISCADA = os.path.expanduser("~/.config/hypr/discada.conf")
ICON = os.path.expanduser("~/.config/swaync/images/bell.png")
WARN_AT = (20, 10, 5)
SIGNAL = 11   # pkill -RTMIN+11 waybar


def conf(key, default):
    try:
        for line in open(DISCADA):
            if line.startswith(key + "="):
                return line.split("=", 1)[1].split()[0].strip('"')
    except (OSError, IndexError):
        pass
    return default


def T(es, en):
    return es if conf("LANGUAGE", "en") == "es" else en


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


# ── batería ──────────────────────────────────────────────────────────────────
def batteries():
    """Baterías del equipo; las de mouse/audífonos (scope=Device) no cuentan."""
    out = []
    try:
        names = sorted(os.listdir(PS))
    except OSError:
        return out
    for n in names:
        d = os.path.join(PS, n)
        if read(f"{d}/type") == "Battery" and read(f"{d}/scope", "System") != "Device":
            out.append(d)
    return out


def on_ac():
    for n in os.listdir(PS) if os.path.isdir(PS) else []:
        d = os.path.join(PS, n)
        if read(f"{d}/type") in ("Mains", "USB") and read(f"{d}/online") == "1":
            return True
    return False


def info():
    """{"pct", "status", "secs"} juntando todas las baterías, o None."""
    bats = batteries()
    if not bats:
        return None
    now = full = rate = 0
    statuses = []
    for d in bats:
        statuses.append(read(f"{d}/status", "Unknown"))
        # energy_* (µWh, µW) o charge_* (µAh, µA): da igual para el cociente
        kind = "energy" if os.path.exists(f"{d}/energy_now") else "charge"
        now += int(read(f"{d}/{kind}_now", "0") or 0)
        full += int(read(f"{d}/{kind}_full", "0") or 0)
        rate += abs(int(read(f"{d}/{'power' if kind == 'energy' else 'current'}_now", "0") or 0))
    if full:
        pct = round(100 * now / full)
    else:
        pct = round(sum(int(read(f"{d}/capacity", "0") or 0) for d in bats) / len(bats))
    pct = max(0, min(100, pct))
    if "Charging" in statuses:
        status, secs = "charging", (full - now) * 3600 / rate if rate else None
    elif "Discharging" in statuses and not on_ac():
        status, secs = "discharging", now * 3600 / rate if rate else None
    else:
        status, secs = "full" if pct >= 95 or on_ac() else "discharging", None
    return {"pct": pct, "status": status, "secs": secs}


def hm(secs):
    if not secs or secs > 48 * 3600:
        return ""
    m = int(secs // 60)
    return f"{m // 60}:{m % 60:02d}"


# ── perfiles (power-profiles-daemon) ─────────────────────────────────────────
PROFILES = ["power-saver", "balanced", "performance"]


def profile_name(p):
    return {"power-saver": T("ahorro", "power saver"), "balanced": T("balanceado", "balanced"),
            "performance": T("rendimiento", "performance")}.get(p, p or "?")


def profile_get():
    if not shutil.which("powerprofilesctl"):
        return None
    r = subprocess.run(["powerprofilesctl", "get"], capture_output=True, text=True)
    return r.stdout.strip() or None


def profile_set(p):
    if shutil.which("powerprofilesctl"):
        subprocess.run(["powerprofilesctl", "set", p], capture_output=True)


def profiles_available():
    r = subprocess.run(["powerprofilesctl", "list"], capture_output=True, text=True)
    return [p for p in PROFILES if f"{p}:" in r.stdout] or PROFILES[:2]


# ── ahorro ───────────────────────────────────────────────────────────────────
def hypr_opt(name):
    r = subprocess.run(["hyprctl", "-j", "getoption", name], capture_output=True, text=True)
    try:
        d = json.loads(r.stdout)
    except ValueError:
        return None
    for k in ("int", "str", "float"):
        if k in d:
            return d[k]
    return None


def saver_state():
    try:
        return json.load(open(STATE))
    except (OSError, ValueError):
        return None


def save_state(st):
    os.makedirs(RUN, exist_ok=True)
    with open(STATE, "w") as f:
        json.dump(st, f)


def capture_look(st):
    """Lo que el ahorro apaga, tal como lo dejó el look (para devolverlo)."""
    st["blur"] = hypr_opt("decoration:blur:enabled")
    st["shadow"] = hypr_opt("decoration:shadow:enabled")
    shader = hypr_opt("decoration:screen_shader")
    st["shader"] = "" if shader in (None, "[[EMPTY]]") else shader


def apply_saver():
    subprocess.run(["hyprctl", "--batch",
                    "keyword decoration:blur:enabled 0;"
                    "keyword decoration:shadow:enabled 0;"
                    "keyword decoration:screen_shader [[EMPTY]]"], capture_output=True)
    # el video se congela en el cuadro que iba (SIGCONT lo sigue)
    subprocess.run(["pkill", "-STOP", "-x", "mpvpaper"], capture_output=True)


def saver_on(why="manual"):
    if saver_state():
        return
    st = {"why": why, "profile": profile_get()}
    capture_look(st)
    save_state(st)
    profile_set("power-saver")
    apply_saver()
    refresh_bar()
    msg = T("Se prendió solo con la batería baja" if why == "auto" else "Menos efectos y menos consumo",
            "Turned on by itself, battery is low" if why == "auto" else "Fewer effects, less power")
    notify(T("Ahorro de batería: sí", "Battery saver: on"), msg)


def saver_off():
    st = saver_state()
    if not st:
        return
    os.remove(STATE)
    batch = []
    if st.get("blur") is not None:
        batch.append(f"keyword decoration:blur:enabled {st['blur']}")
    if st.get("shadow") is not None:
        batch.append(f"keyword decoration:shadow:enabled {st['shadow']}")
    if st.get("shader"):
        batch.append(f"keyword decoration:screen_shader {st['shader']}")
    if batch:
        subprocess.run(["hyprctl", "--batch", ";".join(batch)], capture_output=True)
    subprocess.run(["pkill", "-CONT", "-x", "mpvpaper"], capture_output=True)
    profile_set(st.get("profile") or "balanced")
    refresh_bar()
    notify(T("Ahorro de batería: no", "Battery saver: off"), "")


# ── barra y avisos ───────────────────────────────────────────────────────────
def refresh_bar():
    subprocess.run(["pkill", f"-RTMIN+{SIGNAL}", "-x", "waybar"], capture_output=True)


def notify(title, body, urgency="low"):
    subprocess.run(["notify-send", "-e", "-a", "discada", "-u", urgency, "-i", ICON,
                    "-h", "string:x-canonical-private-synchronous:battery", title, body],
                   capture_output=True)


def status():
    b = info()
    if not b:
        print("")
        return
    saver = saver_state()
    alt = "saver" if saver and b["status"] != "charging" else b["status"]
    cls = [b["status"]]
    if saver:
        cls.append("saver")
    if b["status"] == "discharging":
        if b["pct"] <= 10:
            cls.append("critical")
        elif b["pct"] <= 20:
            cls.append("low")
    state = {"charging": T("cargando", "charging"), "full": T("conectada", "plugged in"),
             "discharging": T("con batería", "on battery")}[b["status"]]
    left = hm(b["secs"])
    if left:
        state += f" · {left} " + (T("para llenarse", "to full") if b["status"] == "charging"
                                  else T("restantes", "left"))
    lines = [f"{T('Batería', 'Battery')} {b['pct']}% · {state}"]
    prof = profile_get()
    if prof:
        lines.append(f"{T('Perfil', 'Profile')}: {profile_name(prof)}")
    lines.append(f"{T('Ahorro', 'Saver')}: " + (T("sí", "on") if saver else T("no", "off")))
    lines.append("")
    if prof:
        lines.append(T("Clic: cambiar perfil", "Click: change profile"))
    lines.append(T("Clic derecho: ahorro de batería", "Right click: battery saver"))
    print(json.dumps({"text": str(b["pct"]), "percentage": b["pct"], "alt": alt,
                      "class": cls, "tooltip": "\n".join(lines)}))


def cycle_profile():
    if not shutil.which("powerprofilesctl"):
        notify(T("Falta power-profiles-daemon", "power-profiles-daemon is missing"),
               "sudo pacman -S power-profiles-daemon", "normal")
        return
    avail = profiles_available()
    cur = profile_get()
    nxt = avail[(avail.index(cur) + 1) % len(avail)] if cur in avail else "balanced"
    profile_set(nxt)
    refresh_bar()
    notify(T("Perfil de energía", "Power profile"), profile_name(nxt))


# ── daemon ───────────────────────────────────────────────────────────────────
class Watcher:
    def __init__(self):
        self.warned = set()
        self.last = None

    def check(self):
        b = info()
        if not b:
            return
        key = (b["status"], b["pct"])
        if key != self.last:
            self.last = key
            refresh_bar()
        st = saver_state()
        if b["status"] == "discharging":
            for lvl in WARN_AT:
                if b["pct"] <= lvl and lvl not in self.warned:
                    self.warned.update(l for l in WARN_AT if l >= lvl)
                    notify(T(f"Batería al {b['pct']}%", f"Battery at {b['pct']}%"),
                           T("Conecta el cargador", "Plug in the charger"),
                           "critical" if lvl <= 10 else "normal")
                    break
            try:
                auto_at = int(conf("BATTERY_SAVER_AT", "20"))
            except ValueError:
                auto_at = 20
            if auto_at and b["pct"] <= auto_at and not st:
                saver_on("auto")
        else:
            self.warned.clear()
            if st and st.get("why") == "auto":
                saver_off()

    def reapply(self):
        """Un reload de Hyprland regresa blur/sombras/shader: volver a apagarlos
        (y tomar lo del look nuevo, por si fue un cambio de look)."""
        st = saver_state()
        if st:
            capture_look(st)
            save_state(st)
            apply_saver()


def hypr_socket():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr", sig, ".socket2.sock"))
    except OSError:
        return None
    return s


def watch():
    if not batteries():
        return
    w = Watcher()
    sel = selectors.DefaultSelector()
    udev = None
    if shutil.which("udevadm"):
        udev = subprocess.Popen(["udevadm", "monitor", "--udev", "--subsystem-match=power_supply"],
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        os.set_blocking(udev.stdout.fileno(), False)
        sel.register(udev.stdout, selectors.EVENT_READ, "udev")
    hs, buf = hypr_socket(), b""
    if hs:
        sel.register(hs, selectors.EVENT_READ, "hypr")
    w.check()
    while True:
        events = sel.select(timeout=60)
        for key, _ in events:
            if key.data == "udev":
                try:
                    if not os.read(key.fileobj.fileno(), 65536):
                        sel.unregister(key.fileobj)
                except BlockingIOError:
                    pass
                time.sleep(0.5)   # que el kernel termine de actualizar /sys
            else:
                data = hs.recv(4096)
                if not data:
                    sel.unregister(hs)
                    hs = None
                    continue
                buf += data
                lines = buf.split(b"\n")
                buf = lines.pop()
                if any(l.startswith(b"configreloaded>>") for l in lines):
                    time.sleep(0.3)
                    w.reapply()
        w.check()


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    arg = sys.argv[2] if len(sys.argv) > 2 else "toggle"
    if cmd == "status":
        status()
    elif cmd == "has":
        sys.exit(0 if batteries() else 1)
    elif cmd == "watch":
        watch()
    elif cmd == "profile":
        cycle_profile()
    elif cmd == "saver":
        on = not saver_state() if arg == "toggle" else arg == "on"
        saver_on() if on else saver_off()
    elif cmd == "idle-suspend":
        b = info()
        if b and b["status"] == "discharging":
            subprocess.run(["systemctl", "suspend"])
    else:
        print(__doc__.strip())
        sys.exit(2)


if __name__ == "__main__":
    main()
