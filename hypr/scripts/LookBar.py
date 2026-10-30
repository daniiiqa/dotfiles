#!/usr/bin/env python3
"""El [bar] de empalme de un look, traducido de su waybar (config, style.css,
recorder.json y visualizer.json). Mientras waybar siga siendo la barra, su
config es la fuente; esto la pasa a look.toml para empalme.

  LookBar.py LOOK            imprimir el [bar] traducido
  LookBar.py LOOK --write    ponerlo en hypr/looks/LOOK/look.toml (reemplaza
                             el [bar] que haya: va al final del archivo)
  LookBar.py all --write     en todos los looks

Del style.css sale cómo se ve: la barra ([bar.box], de window#waybar), cada
módulo (todas las reglas que lo nombran, en orden, como en CSS), el hover, los
workspaces y el tooltip; los @define-color se resuelven a los nombres de
colors.json (color12, bg0…) o a alpha(<color>, a).
"""
import json
import os
import re
import sys

LOOKS = os.path.expanduser("~/.config/hypr/looks")


def q(v):
    """Un valor en TOML."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, list):
        return "[" + ", ".join(q(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{json.dumps(k)} = {q(x)}" for k, x in v.items()) + " }"
    raise TypeError(v)


def key(k):
    return k if re.fullmatch(r"[A-Za-z_][\w]*", k) else json.dumps(k)


def table(name, d):
    return ["", f"[{name}]"] + [f"{key(k)} = {q(v)}" for k, v in d.items()]


def num(s):
    f = float(s)
    return int(f) if f == int(f) else f


# ── el CSS ───────────────────────────────────────────────────────────────────
class Css:
    def __init__(self, text):
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        text = re.sub(r"\{\{\s*\w+\s*\}\}", "FONT", text)   # {{font}} desbalancea las llaves
        self.defs = dict(re.findall(r"@define-color\s+([\w-]+)\s+([^;]+);", text))
        self.rules = []
        for sel, body in re.findall(r"([^{}]*)\{([^}]*)\}", text):
            sels = [" ".join(x.split()) for x in sel.split(",") if x.strip()]
            props = {k.strip(): v.strip() for k, v in re.findall(r"([\w-]+)\s*:\s*([^;]+);", body)}
            self.rules.append((sels, props))

    def props(self, *selectors):
        """Lo que dicen todas las reglas que nombran alguno de `selectors`, en orden."""
        out = {}
        for sels, props in self.rules:
            if any(s in sels for s in selectors):
                out.update(props)
        return out

    def color(self, v, depth=0):
        """Un color del CSS como lo entiende empalme, o None (transparent…)."""
        v = v.strip()
        if depth > 8 or v in ("transparent", "inherit", "none", "initial"):
            return None
        m = re.fullmatch(r"alpha\(\s*(.+?)\s*,\s*([\d.]+)\s*\)", v)
        if m:
            inner = self.color(m.group(1), depth + 1)
            if not inner:
                return None
            a = float(m.group(2))
            # alpha de alpha: multiplicar
            m2 = re.fullmatch(r"alpha\((.+), ([\d.]+)\)", inner)
            if m2:
                return f"alpha({m2.group(1)}, {round(a * float(m2.group(2)), 3)})"
            return f"alpha({inner}, {m.group(2)})"
        if v.startswith("@"):
            n = v[1:]
            return self.color(self.defs[n], depth + 1) if n in self.defs else n
        if re.fullmatch(r"#[0-9a-fA-F]{6}", v):
            return v
        if v in ("white", "black"):
            return v
        return None

    def border(self, v):
        """`1px solid @acc` → (ancho, color, ¿punteado?)."""
        if not v or v.strip() in ("none", "0"):
            return None
        w = re.search(r"([\d.]+)px", v)
        c = re.search(r"(alpha\([^)]*\)|@[\w-]+|#[0-9a-fA-F]{6}|\bwhite\b|\bblack\b)", v)
        col = self.color(c.group(1)) if c else None
        if not col:
            return None
        return (num(w.group(1)) if w else 1, col, "dashed" in v or "dotted" in v)


def px_list(v):
    """`3px 2px` (como margin/padding de CSS) → [arriba, derecha, abajo, izquierda]."""
    vals = [num(x) for x in re.findall(r"(-?[\d.]+)(?:px)?", v or "")]
    if not vals:
        return None
    if len(vals) == 1:
        vals *= 4
    elif len(vals) == 2:
        vals = [vals[0], vals[1], vals[0], vals[1]]
    elif len(vals) == 3:
        vals = [vals[0], vals[1], vals[2], vals[1]]
    return vals[:4]


def style(css, props, bar_font):
    """Lo que empalme entiende de un módulo: colores, caja, márgenes, letra."""
    out = {}
    fg = css.color(props.get("color", "transparent"))
    if fg:
        out["fg"] = fg
    bg = css.color(props.get("background", props.get("background-color", "transparent")))
    if bg:
        out["bg"] = bg
    b = css.border(props.get("border"))
    if b and props.get("border-color"):
        b = (b[0], css.color(props["border-color"]) or b[1], b[2])
    if b:
        out["border"], out["border-width"] = b[1], b[0]
    else:
        # solo a la izquierda: los separadores entre módulos (brutalist)
        bl = css.border(props.get("border-left"))
        if bl:
            out["border"], out["border-width"], out["border-sides"] = bl[1], bl[0], "left"
    r = re.match(r"([\d.]+)px", props.get("border-radius", ""))
    if r:
        out["radius"] = num(r.group(1))
    # margin y padding, con lo que digan sus lados sueltos (margin-left…) encima
    def sides(prop):
        v = px_list(props.get(prop)) or [0, 0, 0, 0]
        found = prop in props
        for i, side in enumerate(("top", "right", "bottom", "left")):
            one = re.match(r"(-?[\d.]+)px", props.get(f"{prop}-{side}", ""))
            if one:
                v[i], found = num(one.group(1)), True
        return v if found else None
    m = sides("margin")
    if m and any(m):
        out["margin"] = m
    p = sides("padding")
    if p:
        out["padding"] = p[1]
    sh = re.match(r"\s*(-?[\d.]+)px\s+(-?[\d.]+)px\s+[\d.]+(?:px)?\s+(.+)", props.get("box-shadow", ""))
    if sh and css.color(sh.group(3)):
        out["shadow"] = [num(sh.group(1)), num(sh.group(2)), css.color(sh.group(3))]
    w = props.get("font-weight", "")
    if w == "bold" or (w.isdigit() and int(w) >= 700):
        out["bold"] = True
    fs = re.match(r"([\d.]+)px", props.get("font-size", ""))
    if fs and num(fs.group(1)) != bar_font:
        out["font-size"] = num(fs.group(1))
    return out


# ── de qué módulo de waybar es cada uno de empalme ───────────────────────────
NAMES = {"custom/recorder": "recorder", "custom/battery": "battery", "idle_inhibitor": "idle",
         "custom/swaync": "notifications", "custom/power": "power", "pulseaudio": "audio",
         "pulseaudio#microphone": "mic", "custom/visualizer": "visualizer"}
KNOWN = {"visualizer", "workspaces", "clock", "temperature", "cpu", "memory", "disk", "audio", "mic",
         "network", "bluetooth", "battery", "idle", "notifications", "power", "recorder"}
# sus selectores en el CSS (del más general al más propio)
CSS_OF = {"clock": ["#clock"], "temperature": ["#temperature"], "cpu": ["#cpu"], "memory": ["#memory"],
          "disk": ["#disk"], "audio": ["#pulseaudio"], "mic": ["#pulseaudio", "#pulseaudio.microphone"],
          "network": ["#network"], "bluetooth": ["#bluetooth"], "battery": ["#custom-battery"],
          "idle": ["#idle_inhibitor"], "notifications": ["#custom-swaync"], "power": ["#custom-power"],
          "recorder": ["#custom-recorder"], "visualizer": ["#custom-visualizer"], "app": [".app"],
          "app#more": [".app-more"], "workspaces": ["#workspaces"]}


def translate(look):
    d = os.path.join(LOOKS, look)
    t = open(os.path.join(d, "waybar/config")).read()
    t = re.sub(r"(?m)^\s*//.*$", "", t)
    t = re.sub(r",(\s*[}\]])", r"\1", t)
    c = json.loads(t)
    c = c[0] if isinstance(c, list) else c
    css = Css(open(os.path.join(d, "waybar/style.css")).read())

    def mod(prefix):
        for k, v in c.items():
            if k == prefix or k.startswith(prefix + "#"):
                return v
        return {}

    def name(n):
        m = re.fullmatch(r"custom/app-([id]\d+)|custom/apps-(more)", n)
        if m:
            return "app#" + (m.group(1) or m.group(2))
        n = NAMES.get(n, n)
        base = n.split("#")[0].split("/")[-1]
        return base if base in KNOWN else None

    groups = {}

    def side(k):
        out = []
        for n in c.get(k, []):
            if n.startswith("group/"):
                g = c.get(n, {})
                ms = [x for x in map(name, g.get("modules", [])) if x]
                if not ms:
                    continue
                groups[n[6:]] = {"modules": ms}
                if "drawer" in g:
                    groups[n[6:]]["drawer"] = {k2: v for k2, v in g["drawer"].items()
                                              if k2 in ("transition-duration", "transition-left-to-right")}
                out.append(n)
            elif name(n):
                out.append(name(n))
        return out

    left, center, right = side("modules-left"), side("modules-center"), side("modules-right")
    used = set(left + center + right) | {x for g in groups.values() for x in g["modules"]}

    # los formatos (los mismos nombres que en waybar)
    fmt = lambda v: {k: x for k, x in v.items() if (k.startswith("format") or k.startswith("tooltip")) and k != "format-alt-click"}
    mods = {}
    ws = mod("hyprland/workspaces")
    mods["workspaces"] = {k: ws[k] for k in ("format", "format-icons") if k in ws}
    if isinstance(ws.get("persistent-workspaces"), dict) and "*" in ws["persistent-workspaces"]:
        mods["workspaces"]["persistent"] = ws["persistent-workspaces"]["*"]
    clock = mod("clock")
    mods["clock"] = {k: v for k, v in fmt(clock).items() if k in ("format", "format-alt", "tooltip", "tooltip-format")}
    if "calendar" in clock:
        mods["clock"]["calendar"] = {k: v for k, v in clock["calendar"].items() if k == "format"}
    for n in ("temperature", "cpu", "memory", "disk"):
        m = mod(n)
        mods[n] = fmt(m)
        for k in ("interval", "critical-threshold", "path"):
            if k in m:
                mods[n][k] = m[k]
    pa = c.get("pulseaudio", {})
    mods["audio"] = {k: pa[k] for k in ("format", "format-muted", "format-bluetooth", "tooltip", "tooltip-format") if k in pa}
    icons = {k: v for k, v in pa.get("format-icons", {}).items() if k != "ignored-sinks"}
    if icons:
        mods["audio"]["format-icons"] = icons
    mic = c.get("pulseaudio#microphone", {})
    mods["mic"] = {}
    if "format-source" in mic:
        mods["mic"]["format"] = mic["format-source"]
    if "format-source-muted" in mic:
        mods["mic"]["format-muted"] = mic["format-source-muted"]
    for k in ("tooltip", "tooltip-format"):
        if k in mic:
            mods["mic"][k] = mic[k]
    mods["network"] = fmt(mod("network"))
    mods["bluetooth"] = fmt(mod("bluetooth"))
    idle = mod("idle_inhibitor")
    mods["idle"] = {k: v for k, v in idle.items() if k in ("format", "format-icons") or k.startswith("tooltip")}
    sw = c.get("custom/swaync", {})
    mods["notifications"] = {"format": sw.get("format", "{icon}")}
    if "format-icons" in sw:
        mods["notifications"]["format-icons"] = {k: v for k, v in sw["format-icons"].items()
                                                 if k in ("notification", "none", "dnd-notification", "dnd-none")}
    rj = os.path.join(d, "waybar/recorder.json")
    mods["recorder"] = json.load(open(rj)) if os.path.exists(rj) else {}
    pw = mod("custom/power")
    mods["power"] = {"format": pw.get("format", "")}
    for k in ("tooltip", "tooltip-format"):
        if k in pw:
            mods["power"][k] = pw[k]
    if "visualizer" in used:
        vj = os.path.join(d, "waybar/visualizer.json")
        mods["visualizer"] = json.load(open(vj)) if os.path.exists(vj) else {}

    # cómo se ve cada uno
    root = css.props("*")
    fs = re.match(r"([\d.]+)px", root.get("font-size", ""))
    bar_font = num(fs.group(1)) if fs else 13
    for n, sels in CSS_OF.items():
        if n not in used and not (n == "app" and any(u.startswith("app#") for u in used)):
            continue
        st = style(css, css.props(*sels), bar_font)
        # las apps y el visualizador pintan con `color` (y la tenue de cerradas)
        if n in ("app", "visualizer") and "fg" in st:
            st["color"] = st.pop("fg")
        mods.setdefault(n, {}).update(st)

    # los workspaces: sus colores
    wsst = {}
    for k, sel in (("fg", "#workspaces button"), ("empty-fg", "#workspaces button.empty"),
                   ("active-fg", "#workspaces button.active")):
        col = css.color(css.props(sel).get("color", "transparent"))
        if col:
            wsst[k] = col
    abg = css.color(css.props("#workspaces button.active").get("background", "transparent"))
    if abg:
        wsst["active-bg"] = abg
    btn = css.props("#workspaces button")
    # el relleno de cada botón, en celdas (una celda mide ~0.6 de la letra)
    # el relleno de cada botón y el del activo, en pixeles
    def hpad(p):
        v = px_list(p.get("padding"))
        r = re.match(r"(-?[\d.]+)px", p.get("padding-right", ""))
        return num(r.group(1)) if r else (v[1] if v else None)
    # GTK le pone ~4px más a cada lado de un botón, además del CSS (medido)
    GTK = 4
    bp = hpad(btn)
    wsst["button-padding"] = (bp or 0) + GTK
    ap = hpad(css.props("#workspaces button.active"))
    if ap is not None and ap != bp:
        wsst["active-padding"] = ap + GTK
    br = re.match(r"([\d.]+)px", btn.get("border-radius", ""))
    if br and num(br.group(1)) > 0:
        wsst["button-radius"] = num(br.group(1))
    bfs = re.match(r"([\d.]+)px", btn.get("font-size", ""))
    if bfs and num(bfs.group(1)) != bar_font:
        wsst["font-size"] = num(bfs.group(1))
    if wsst:
        mods.setdefault("workspaces", {}).update(wsst)

    # cómo se marca lo activo: la app enfocada y el workspace activo
    def mark(sel):
        p = css.props(sel)
        # un fondo propio (loteria): ese, con su color de letras
        out = {}
        bg = css.color(p.get("background", p.get("background-color", "transparent")))
        if bg and sel.startswith(".app"):
            out["active-bg"] = bg
            if css.color(p.get("color", "transparent")):
                out["active-fg"] = css.color(p["color"])
        if css.color(p.get("border-color", "transparent")):
            out["active-border"] = css.color(p["border-color"])
        if out:
            return out
        for side in ("bottom", "top"):
            b = css.border(p.get(f"border-{side}"))
            c = css.color(p.get(f"border-{side}-color", "transparent")) or (b[1] if b else None)
            if c:
                return {"active-line": side, "active-color": c}
        if css.color(p.get("border-color", "transparent")):
            return {"active-border": css.color(p["border-color"])}
        return {}
    if any(u.startswith("app#") for u in used):
        mods.setdefault("app", {}).update(mark(".app.active"))
    mods.setdefault("workspaces", {}).update(mark("#workspaces button.active"))

    # las secciones (.modules-left…): su caja, rellenos, puntitos y línea
    sections = {}
    for k in ("left", "center", "right"):
        p = css.props(f".modules-{k}")
        if not p:
            continue
        st = {x: v for x, v in style(css, p, bar_font).items() if x in ("bg", "border", "border-width", "radius", "margin")}
        pad = px_list(p.get("padding"))
        if pad and (pad[1] or pad[3]):
            st["padding"] = pad[1] if pad[1] == pad[3] else [pad[3], pad[1]]
        img = p.get("background-image", "")
        stops = re.findall(r"(alpha\([^)]*\)|@[\w-]+|#[0-9a-fA-F]{6})", img)
        if "radial-gradient" in img and stops and css.color(stops[0]):
            st["dots"] = css.color(stops[0])
        line = re.search(r"linear-gradient\(to top,\s*(alpha\([^)]*\)|@[\w-]+|#[0-9a-fA-F]{6})\s+\d+px,\s*transparent", img)
        if line and css.color(line.group(1)):
            st["underline"] = css.color(line.group(1))
        # la losa de neon: el último color del degradado como fondo
        last = img.split("linear-gradient(")[-1] if "linear-gradient(" in img else ""
        ls = re.findall(r"(alpha\([^)]*\)|@[\w-]+|#[0-9a-fA-F]{6})", last)
        if "bg" not in st and ls and not last.startswith("to top") and css.color(ls[-1]):
            st["bg"] = css.color(ls[-1])
        if st:
            sections[k] = st

    # la barra entera
    win = css.props("window#waybar")
    box = {}
    # sin fondo: transparente (no la barra sólida de siempre)
    box["bg"] = css.color(win.get("background", win.get("background-color", "transparent"))) or "transparent"
    for prop, sides in (("border", "all"), ("border-bottom", "bottom"), ("border-top", "top")):
        b = css.border(win.get(prop))
        if b:
            box.update({"border": b[1], "border-width": b[0], "border-sides": sides})
            if b[2]:
                box["dashed"] = True
    r = re.match(r"([\d.]+)px", win.get("border-radius", ""))
    if r:
        box["radius"] = num(r.group(1))

    margin = [c.get(f"margin-{s}", 0) for s in ("top", "right", "bottom", "left")]
    out = ["", "[bar]", "# empalme, la barra de discada (LookBar.py: traducido de waybar/)",
           f"position = {q(c.get('position', 'top'))}", f"height = {c.get('height', 30)}",
           f"margin = {q(margin)}     # arriba, derecha, abajo, izquierda (pixeles)",
           'style = "solid"', "radius = 0",
           f"font-size = {bar_font}     # pixeles, como en el style.css de waybar",
           "pad = 0                # el relleno de cada módulo va en su padding (pixeles)",
           "gap = 0                # celdas entre módulos",
           f"spacing = {c.get('spacing', 0)}            # pixeles entre módulos (el spacing de waybar)",
           f"left = {q(left)}", f"center = {q(center)}", f"right = {q(right)}"]
    out += table("bar.box", box)
    for k, st in sections.items():
        out += table(f"bar.sections.{k}", st)
    for n, v in mods.items():
        if v:
            out += table(f'bar.modules.{key(n)}', v)

    # el hover
    hover, hover_ws, hmods = {}, {}, []
    cssname = {"custom-power": ["power"], "pulseaudio": ["audio", "mic"], "network": ["network"],
               "bluetooth": ["bluetooth"], "custom-battery": ["battery"], "custom-swaync": ["notifications"],
               "clock": ["clock"], "custom-recorder": ["recorder"], "idle_inhibitor": ["idle"],
               "temperature": ["temperature"], "cpu": ["cpu"], "memory": ["memory"], "disk": ["disk"]}
    for sels, props in css.rules:
        if not any(":hover" in s for s in sels):
            continue
        fg = css.color(props.get("color", "transparent"))
        bg = css.color(props.get("background", props.get("background-color", "transparent")))
        if any(s.startswith("#workspaces button.active:hover") for s in sels):
            hover_ws.update({k: v for k, v in (("active-fg", fg), ("active-bg", bg)) if v})
        elif any(s.startswith("#workspaces button:hover") for s in sels):
            hover_ws.update({k: v for k, v in (("fg", fg), ("bg", bg)) if v})
        else:
            names = [n for s in sels for m in [re.fullmatch(r"#([\w-]+):hover", s)] if m and m.group(1) in cssname
                     for n in cssname[m.group(1)]]
            # la regla de varios módulos es la general
            if len(names) > 1 and (fg or bg) and not hover:
                hover = {k: v for k, v in (("fg", fg), ("bg", bg)) if v}
                hmods = names
    if hover:
        hover["modules"] = hmods
        out += table("bar.hover", hover)
    if hover_ws:
        out += table("bar.hover-workspaces", hover_ws)

    # el tooltip
    tip = {}
    tp = css.props("tooltip")
    if css.color(tp.get("background", "transparent")):
        tip["bg"] = css.color(tp["background"])
    b = css.border(tp.get("border"))
    if b:
        tip["border"] = b[1]
    r = re.match(r"([\d.]+)px", tp.get("border-radius", ""))
    if r:
        tip["radius"] = num(r.group(1))
    lc = css.color(css.props("tooltip label").get("color", "transparent"))
    if lc:
        tip["fg"] = lc
    if tip:
        out += table("bar.tooltip", tip)

    for g, v in groups.items():
        out += table(f"bar.groups.{key(g)}", v)
    return "\n".join(out) + "\n"


def write(look):
    path = os.path.join(LOOKS, look, "look.toml")
    text = open(path).read()
    i = text.find("\n[bar]")
    if i >= 0:
        text = text[:i]
    open(path, "w").write(text.rstrip() + "\n" + translate(look))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    looks = sorted(l for l in os.listdir(LOOKS) if os.path.isfile(os.path.join(LOOKS, l, "waybar/config"))) \
        if sys.argv[1] == "all" else [sys.argv[1]]
    for look in looks:
        if "--write" in sys.argv:
            write(look)
            print(f"{look}: [bar] escrito")
        else:
            print(translate(look), end="")


if __name__ == "__main__":
    main()
