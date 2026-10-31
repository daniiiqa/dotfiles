#!/usr/bin/env python3
"""discada: cada look sale de un solo archivo, hypr/looks/<look>/look.toml
(colores, fuente, estilo de las apps). Los archivos de cada app en la carpeta
del look (empalme/, rofi/, hypr/…) no llevan ni colores ni fuentes escritos:
usan los nombres del look.toml. La barra (empalme) es el [bar] del look.toml.

  LookBuild.py apply LOOK      copiar el look a ~/.config, con {{font}} rellenado,
                               más su wallust.toml, el look.json de rola y la
                               barra de empalme (su [bar])
  LookBuild.py save LOOK       guardar lo vivo en el look (la fuente vuelve a {{font}})
  LookBuild.py colors [LOOK]   los archivos de colores de cada app: la paleta del
                               look (o la de wallust si sigue al wallpaper) más
                               sus nombres propios (acc, hi…)
  LookBuild.py get LOOK CLAVE  un valor del look.toml (font.family, about.es…)
  LookBuild.py bar-set MÓDULO JSON [LOOK]
                               cambiar claves del [bar.modules.MÓDULO] del look
                               (como el visualizador desde el menú de ajustes)
  LookBuild.py list            los looks, uno por línea

Colores en los archivos del look:
  wlogout (CSS)            @acc, alpha(@acc, 0.5)
  empalme ([bar])          acc, alpha(acc, 0.5)
  rofi                     @acc            con transparencia: @acc_a80
  hyprland / hyprlock      $acc  (c.acc en Lua)       con transparencia: $acc_a80
  sddm/look.conf           "@acc"
(_a80 = alpha en hex: 80 es la mitad. Se generan solas las que se usen.)
"""
import os
import re
import sys
import tomllib

CFG = os.environ.get("DISCADA_CFG") or os.path.expanduser("~/.config")   # DISCADA_CFG: probar en otra carpeta
LOOKS = os.path.join(CFG, "hypr/looks")
WALLUST_BASE = os.path.join(CFG, "wallust/wallust.base.toml")
WALLUST_TOML = os.path.join(CFG, "wallust/wallust.toml")
HYPR_COLORS = os.path.join(CFG, "hypr/wallust/wallust-hyprland.conf")
HYPR_LUA = os.path.join(CFG, "hypr/wallust/wallust-hyprland.lua")
ROLA_LOOK = os.path.join(CFG, "rola/look.json")
TERMINAL = ["background", "foreground", "cursor"] + [f"color{i}" for i in range(16)]
GENERATED = {"look.toml", "README.md"}   # de la carpeta del look que no se copian
MARK = "discada: nombres del look"


def current():
    try:
        return open(os.path.join(LOOKS, ".current")).read().strip()
    except OSError:
        return ""


def load(look):
    with open(os.path.join(LOOKS, look, "look.toml"), "rb") as f:
        return tomllib.load(f)


def look_files(look):
    d = os.path.join(LOOKS, look)
    for root, _, files in os.walk(d):
        for name in files:
            rel = os.path.relpath(os.path.join(root, name), d)
            if rel not in GENERATED:
                yield rel


def fonts(lk):
    f = lk.get("font", {})
    out = {"font": f.get("family", "")}
    out["font_display"] = f.get("display", out["font"])
    return out


def render(text, values):
    for k, v in values.items():
        text = text.replace("{{" + k + "}}", v)
    return text


# ── colores ──────────────────────────────────────────────────────────────────
def hexnorm(v):
    v = v.strip().lstrip("#")
    return v.lower() if re.fullmatch(r"[0-9a-fA-F]{6}", v) else None


def palette(lk, wallust_colors):
    """Todos los colores del look ya resueltos: nombre → 'rrggbb'."""
    c = lk.get("colors", {})
    raw = {}
    if c.get("from", "wallpaper") == "palette":
        raw.update({k: c[k] for k in TERMINAL if k in c})
        raw.setdefault("cursor", raw.get("foreground", "ffffff"))
    else:
        raw.update(wallust_colors)
    raw.update(c.get("named", {}))

    def resolve(name, seen=()):
        v = raw[name]
        h = hexnorm(v)
        if h:
            return h
        if v in raw and v not in seen:
            return resolve(v, seen + (name,))
        raise SystemExit(f"look.toml: el color «{name}» = «{v}» no es #rrggbb ni otro nombre")
    return {k: resolve(k) for k in raw}


def wallust_colors():
    """Lo que dejó wallust (y ContrastFix) en los colores de hyprland."""
    out = {}
    try:
        for name, v in re.findall(r"^\$(\w+)\s*=\s*rgb\(([0-9a-fA-F]{6})\)", open(HYPR_COLORS).read(), re.M):
            if name in TERMINAL:
                out[name] = v.lower()
    except OSError:
        pass
    return out


def alphas_used(look, names):
    """name_aXX que usan los archivos del look (rofi, hyprland, hyprlock)."""
    used = set()
    rx = re.compile(r"[@$.]([A-Za-z]\w*?)_a([0-9a-fA-F]{2})\b")
    for rel in look_files(look):
        try:
            text = open(os.path.join(LOOKS, look, rel), errors="ignore").read()
        except OSError:
            continue
        for n, a in rx.findall(text):
            if n in names:
                used.add((n, a.lower()))
    return sorted(used)


def templates():
    """[templates] del wallust.toml de discada: nombre → (plantilla, destino)."""
    with open(WALLUST_BASE, "rb") as f:
        t = tomllib.load(f).get("templates", {})
    return {k: (os.path.join(CFG, "wallust/templates", v["template"]), os.path.expanduser(v["target"]))
            for k, v in t.items()}


def fill(template, pal):
    def sub(m):
        name, flt = m.group(1), (m.group(2) or "").strip()
        h = pal.get(name)
        if h is None:
            return m.group(0)
        if flt == "strip":
            return h.upper()
        if flt == "rgb":
            return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))
        return "#" + h.upper()
    return re.sub(r"\{\{\s*(\w+)\s*(?:\|\s*(\w+)\s*)?\}\}", sub, template)


def strip_mark(text):
    i = text.find(MARK)
    if i < 0:
        return text
    return text[:text.rfind("\n", 0, i) + 1].rstrip() + "\n"


def named_block(kind, lk, pal, alphas):
    names = list(lk.get("colors", {}).get("named", {}))
    if not names and not alphas and kind != "kitty":
        return ""
    if kind == "css":
        lines = [f"\n/* {MARK} (LookBuild.py) */"]
        lines += [f"@define-color {n} #{pal[n]};" for n in names]
    elif kind == "rasi":
        lines = [f"\n/* {MARK} (LookBuild.py) */", "* {"]
        lines += [f"    {n}: #{pal[n]};" for n in names]
        lines += [f"    {n}_a{a}: #{pal[n]}{a};" for n, a in alphas]
        lines.append("}")
    elif kind == "kitty":
        extra = lk.get("kitty", {})
        if not extra:
            return ""
        lines = [f"\n# {MARK} (LookBuild.py)"]
        for k, v in extra.items():
            lines.append(f"{k} {v if v == 'none' else '#' + pal.get(v, hexnorm(v) or v)}")
    elif kind == "hypr":
        lines = [f"\n# {MARK} (LookBuild.py)"]
        lines += [f"${n} = rgb({pal[n]})" for n in names]
        lines += [f"${n}_a{a} = rgba({pal[n]}{a})" for n, a in alphas]
    else:
        return ""
    return "\n".join(lines) + "\n"


def write_lua():
    """Los mismos colores que wallust-hyprland.conf (ya con los nombres del
    look), para la config de Hyprland en Lua."""
    pairs = re.findall(r"^\$(\w+)\s*=\s*(rgba?\([0-9a-fA-F]+\))", open(HYPR_COLORS).read(), re.M)
    lines = ["-- Colores del look para Hyprland en Lua (LookBuild.py; no editar).",
             '-- En los looks: local c = require("wallust.wallust-hyprland")  →  c.acc', "", "return {"]
    lines += [f'    {n} = "{v}",' for n, v in dict(pairs).items()]
    lines.append("}")
    os.makedirs(os.path.dirname(HYPR_LUA), exist_ok=True)
    open(HYPR_LUA, "w").write("\n".join(lines) + "\n")


def colors(look):
    lk = load(look)
    from_palette = lk.get("colors", {}).get("from", "wallpaper") == "palette"
    pal = palette(lk, {} if from_palette else wallust_colors())
    alphas = alphas_used(look, pal)
    kinds = {".css": "css", ".rasi": "rasi"}
    for name, (tpl, target) in templates().items():
        if from_palette:
            text = fill(open(tpl).read(), pal)
        else:
            try:
                text = open(target).read()
            except OSError:
                continue
        text = strip_mark(text)
        kind = "hypr" if "hypr" in name else "kitty" if "kitty" in name else kinds.get(os.path.splitext(target)[1], "")
        text += named_block(kind, lk, pal, alphas)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        open(target, "w").write(text)
    write_lua()
    write_bar_colors(pal)


def write_bar_colors(pal):
    """Los colores del look ya resueltos (los de wallust y los nombres propios
    como rec o critical) para empalme, que los usa en sus formatos."""
    import json
    path = os.path.join(CFG, "empalme/colors.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump({k: "#" + v for k, v in pal.items()}, f, indent=2)
        f.write("\n")


# ── aplicar / guardar ────────────────────────────────────────────────────────
def write_wallust_toml(lk):
    base = open(WALLUST_BASE).read()
    pal = lk.get("wallust", {}).get("palette")
    if pal:
        base = re.sub(r'^palette\s*=.*$', f'palette = "{pal}"', base, count=1, flags=re.M)
    open(WALLUST_TOML, "w").write("# Lo escribe LookBuild.py (wallust.base.toml + el look); no editar.\n" + base)


def write_rola_look(lk):
    import json
    style = lk.get("style")
    if not style:
        return
    os.makedirs(os.path.dirname(ROLA_LOOK), exist_ok=True)
    with open(ROLA_LOOK, "w") as f:
        json.dump(style, f, indent=2)
        f.write("\n")


def write_bar(lk):
    """La barra de empalme (el [bar] del look); sin [bar], la de siempre."""
    import json
    path = os.path.join(CFG, "empalme/bar.json")
    bar = lk.get("bar")
    if not bar:
        if os.path.exists(path):
            os.remove(path)
        return
    # con el tamaño de letra que ya esté aplicado (FontSize.py), como lo demás vivo
    try:
        d = int(open(os.path.join(LOOKS, ".fontsize")).read().strip() or 0)
    except (OSError, ValueError):
        d = 0

    def shift(v):
        if isinstance(v, dict):
            return {k: (max(6, x + d) if k == "font-size" and isinstance(x, (int, float)) else shift(x)) for k, x in v.items()}
        return [shift(x) for x in v] if isinstance(v, list) else v
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(shift(bar) if d else bar, f, indent=2)
        f.write("\n")


def is_text(path):
    try:
        with open(path, "rb") as f:
            return b"\0" not in f.read(8192)
    except OSError:
        return False


def apply(look):
    # primero los colores: Hyprland recarga solo en cuanto cambia
    # decorations.conf, y ahí ya tienen que existir $acc y compañía
    colors(look)
    lk = load(look)
    values = fonts(lk)
    d = os.path.join(LOOKS, look)
    for rel in look_files(look):
        src, dst = os.path.join(d, rel), os.path.join(CFG, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if is_text(src):
            open(dst, "w").write(render(open(src).read(), values))
        else:
            with open(src, "rb") as a, open(dst, "wb") as b:
                b.write(a.read())
    write_wallust_toml(lk)
    write_rola_look(lk)
    write_bar(lk)


def save(look):
    """Lo vivo de vuelta al look (para no perder lo editado a mano)."""
    lk = load(look)
    values = fonts(lk)
    d = os.path.join(LOOKS, look)
    for rel in look_files(look):
        src, live = os.path.join(d, rel), os.path.join(CFG, rel)
        if not os.path.isfile(live) or not is_text(src):
            continue
        orig = open(src).read()
        now = open(live).read()
        if render(orig, values) == now:
            continue   # sin cambios: el look se queda como está (con sus {{font}})
        # la fuente vuelve a ser {{font}} (las más largas primero)
        for k, v in sorted(values.items(), key=lambda kv: -len(kv[1])):
            if v and "{{" + k + "}}" in orig:
                now = now.replace(v, "{{" + k + "}}")
        open(src, "w").write(now)


def bar_set(look, module, values):
    """Cambia (o agrega) claves del [bar.modules.<module>] del look.toml, sin
    tocar el resto del archivo; si es el look actual, también la barra viva."""
    import json
    path = os.path.join(LOOKS, look, "look.toml")
    lines = open(path).read().split("\n")
    name = module if re.fullmatch(r"[\w-]+", module) else json.dumps(module)
    head = f"[bar.modules.{name}]"
    new = [f"{json.dumps(k) if not re.fullmatch(r'[\w-]+', k) else k} = {json.dumps(v, ensure_ascii=False)}"
           for k, v in values.items()]
    if head in lines:
        i = lines.index(head) + 1
        j = i
        while j < len(lines) and not lines[j].startswith("["):
            j += 1
        keep = [l for l in lines[i:j]
                if not any(re.match(rf'\s*"?{re.escape(k)}"?\s*=', l) for k in values)]
        lines[i:j] = new + keep
    else:
        while lines and not lines[-1].strip():
            lines.pop()
        lines += ["", head] + new + [""]
    text = "\n".join(lines)
    tomllib.loads(text)   # que siga siendo TOML antes de escribirlo
    open(path, "w").write(text)
    if look == current():
        write_bar(load(look))


def get(look, key):
    v = load(look)
    for part in key.split("."):
        v = v.get(part, "") if isinstance(v, dict) else ""
    return v if isinstance(v, str) else str(v)


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else ""
    look = a[1] if len(a) > 1 else current()
    if cmd == "list":
        print("\n".join(sorted(l for l in os.listdir(LOOKS)
                               if os.path.isfile(os.path.join(LOOKS, l, "look.toml")))))
    elif cmd == "get" and len(a) == 3:
        print(get(a[1], a[2]))
    elif cmd == "bar-set" and len(a) in (3, 4):
        import json
        bar_set(a[3] if len(a) == 4 else current(), a[1], json.loads(a[2]))
    elif cmd in ("apply", "save", "colors") and look:
        {"apply": apply, "save": save, "colors": colors}[cmd](look)
    else:
        print(__doc__.strip())
        sys.exit(2)


if __name__ == "__main__":
    main()
