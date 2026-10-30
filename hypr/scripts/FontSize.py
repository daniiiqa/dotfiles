#!/usr/bin/env python3
"""Tamaño de letra de discada (FONT_SIZE en hypr/discada.conf, de -2 a +4).

Suma ese tanto a las fuentes de los archivos vivos del look: waybar y swaync
(font-size en px), empalme (los "font-size" de empalme/bar.json), kitty
(font_size) y rofi (rofi/discada-font.rasi, que config.rasi importa después
del theme). Lo aplicado se guarda en hypr/looks/.fontsize; LookSwitch.sh hace
`unapply` antes de guardar el look (así las carpetas de looks se quedan con sus
tamaños originales) y `apply` después de copiar el nuevo.

  FontSize.py apply [--no-reload]   llevar lo vivo a FONT_SIZE
  FontSize.py unapply               quitar lo aplicado (tamaños del look)
  FontSize.py set N                 guardar FONT_SIZE=N y aplicar
"""
import os
import re
import subprocess
import sys

CFG = os.path.expanduser("~/.config")
DISCADA = os.path.join(CFG, "hypr/discada.conf")
APPLIED = os.path.join(CFG, "hypr/looks/.fontsize")
ROFI_OVERRIDE = os.path.join(CFG, "rofi/discada-font.rasi")
MIN, MAX = -2, 4


def read_int(path, pattern, default=0):
    try:
        m = re.search(pattern, open(path).read(), re.M)
        return int(m.group(1)) if m else default
    except (OSError, ValueError):
        return default


def wanted():
    return max(MIN, min(MAX, read_int(DISCADA, r"^FONT_SIZE=\s*([+-]?\d+)")))


def applied():
    return read_int(APPLIED, r"^\s*([+-]?\d+)")


def num(x, like=""):
    # mismo formato que el original (12.0 sigue siendo 12.0, 14 sigue siendo 14)
    return f"{x:.1f}" if "." in like or x != int(x) else str(int(x))


def shift_file(path, rx, d, floor):
    try:
        text = open(path).read()
    except OSError:
        return
    new = re.sub(rx, lambda m: m.group(1) + num(max(floor, float(m.group(2)) + d), m.group(2)) + m.group(3), text, flags=re.M)
    if new != text:
        open(path, "w").write(new)


def shift(d):
    if not d:
        return
    for f in ("waybar/style.css", "swaync/style.css"):
        shift_file(os.path.join(CFG, f), r"(font-size:\s*)(\d+(?:\.\d+)?)(px)", d, 6)
    shift_file(os.path.join(CFG, "empalme/bar.json"), r'("font-size":\s*)(\d+(?:\.\d+)?)()', d, 6)
    shift_file(os.path.join(CFG, "kitty/kitty.conf"), r"(^font_size\s+)(\d+(?:\.\d+)?)()", d, 6)


def rofi_override(total):
    """Las mismas reglas de fuente del theme efectivo, con el tamaño cambiado."""
    head = "/* tamaño de letra de discada (FontSize.py): no editar a mano */\n"
    if not total:
        open(ROFI_OVERRIDE, "w").write(head)
        return
    open(ROFI_OVERRIDE, "w").write(head)  # que no cuente al leer el theme
    dump = subprocess.run(["rofi", "-config", os.path.join(CFG, "rofi/config.rasi"), "-dump-theme"],
                          capture_output=True, text=True).stdout
    rules, sel = [], None
    for line in dump.splitlines():
        m = re.match(r"^(\S[^{]*?)\s*\{\s*$", line)
        if m:
            sel = m.group(1)
        elif line.strip() == "}":
            sel = None
        else:
            f = re.match(r'^\s*font:\s*"(.*?)\s+(\d+(?:\.\d+)?)"\s*;', line)
            if f and sel:
                rules.append((sel, f.group(1), float(f.group(2))))
    if not any(s == "*" for s, _, _ in rules):
        conf = subprocess.run(["rofi", "-config", os.path.join(CFG, "rofi/config.rasi"), "-dump-config"],
                              capture_output=True, text=True).stdout
        f = re.search(r'^\s*font:\s*"(.*?)\s+(\d+(?:\.\d+)?)"\s*;', conf, re.M)
        if f:
            rules.insert(0, ("*", f.group(1), float(f.group(2))))
    body = "".join(f'{s} {{ font: "{fam} {num(max(6, size + total))}"; }}\n' for s, fam, size in rules)
    open(ROFI_OVERRIDE, "w").write(head + body)


def reload():
    # empalme relee bar.json solo
    subprocess.run(["pkill", "-SIGUSR2", "-x", "waybar"])
    subprocess.run(["pkill", "-USR1", "-x", "kitty"])


def write_applied(n):
    open(APPLIED, "w").write(f"{n}\n")


def apply(do_reload=True):
    target, now = wanted(), applied()
    shift(target - now)
    rofi_override(target)
    write_applied(target)
    if do_reload and target != now:
        reload()


def unapply():
    shift(-applied())
    rofi_override(0)
    write_applied(0)


def set_size(n):
    n = max(MIN, min(MAX, n))
    text = open(DISCADA).read() if os.path.exists(DISCADA) else ""
    if re.search(r"^FONT_SIZE=", text, re.M):
        text = re.sub(r"^FONT_SIZE=[^ \t#\n]*", f"FONT_SIZE={n}", text, flags=re.M)
    else:
        text = text.rstrip("\n") + f"\nFONT_SIZE={n}         # -2 … +4 sobre el tamaño de cada look\n"
    open(DISCADA, "w").write(text)
    apply()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "apply":
        apply("--no-reload" not in sys.argv)
    elif cmd == "unapply":
        unapply()
    elif cmd == "set" and len(sys.argv) > 2:
        set_size(int(sys.argv[2]))
    else:
        print(__doc__)
        sys.exit(2)
