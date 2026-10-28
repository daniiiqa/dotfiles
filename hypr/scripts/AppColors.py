#!/usr/bin/env python3
"""Las apps GTK y Qt con los colores del look.

Sale del mismo lugar que rola: el theme de kitty que incluye el look
(01-Wallust.conf: los colores de wallust o la paleta del look.toml, lo
escribe LookBuild.py). color12 es el acento.

  GTK 3 (tema adw-gtk3) y GTK 4/libadwaita: ~/.config/gtk-{3,4}.0/discada.css
      con los colores con nombre de libadwaita; gtk.css lo importa. Además
      claro/oscuro según el fondo (color-scheme y adw-gtk3 / adw-gtk3-dark).
  Qt 5/6 (estilo Fusion): qt5ct/qt6ct/colors/discada.conf, la paleta.

Lo llaman WallustSwww.sh (cambió el wallpaper) y LookSwitch.sh (cambió el
look). Las apps nuevas salen con los colores; las GTK abiertas se recargan.
"""
import os
import re
import shutil
import subprocess

CFG = os.path.expanduser("~/.config")
HOME = os.path.expanduser("~")


def kitty_theme():
    conf = os.path.join(CFG, "kitty/kitty.conf")
    found = None
    try:
        for line in open(conf):
            m = re.match(r"\s*include\s+(.+?)\s*$", line)
            if not m:
                continue
            p = m.group(1)
            p = os.path.join(HOME, p[2:]) if p.startswith("~/") else os.path.join(os.path.dirname(conf), p)
            try:
                if any(l.startswith("background") for l in open(p)):
                    found = p
            except OSError:
                pass
    except OSError:
        pass
    return found


def read_colors(path):
    c = {}
    for line in open(path):
        parts = line.split()
        if len(parts) >= 2 and re.fullmatch(r"#[0-9a-fA-F]{6}", parts[1]):
            c[parts[0]] = parts[1].lower()
    return c


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def hx(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


def mix(a, b, t):
    """t de a sobre b."""
    a, b = rgb(a), rgb(b)
    return hx(tuple(a[i] * t + b[i] * (1 - t) for i in range(3)))


def lum(h):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = map(ch, rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def on(color, light, dark):
    """El texto que mejor se lee sobre color."""
    return light if contrast(color, light) >= contrast(color, dark) else dark


def palette():
    theme = kitty_theme()
    if not theme:
        return None
    c = read_colors(theme)
    bg, fg = c.get("background"), c.get("foreground")
    if not bg or not fg:
        return None
    acc = c.get("color12", c.get("color4", fg))
    dark = lum(bg) < 0.35
    return dict(bg=bg, fg=fg, acc=acc, red=c.get("color1", "#c01c28"), green=c.get("color2", "#2ec27e"),
                yellow=c.get("color3", "#e5a50a"), purple=c.get("color5", acc), dark=dark)


def gtk_css(p):
    bg, fg, acc = p["bg"], p["fg"], p["acc"]
    k = 1 if p["dark"] else -1  # en claro las superficies van un poco más oscuras
    surf = lambda t: mix(fg, bg, t) if k > 0 else mix("#000000", bg, t * 0.6)
    acc_fg = on(acc, "#ffffff" if p["dark"] else bg, "#000000" if p["dark"] else fg)
    names = {
        "window_bg_color": bg, "window_fg_color": fg,
        "view_bg_color": surf(0.03), "view_fg_color": fg,
        "headerbar_bg_color": surf(0.06), "headerbar_fg_color": fg,
        "headerbar_border_color": surf(0.14), "headerbar_backdrop_color": bg,
        "headerbar_shade_color": "rgba(0, 0, 0, 0.25)",
        "sidebar_bg_color": surf(0.05), "sidebar_fg_color": fg, "sidebar_backdrop_color": surf(0.03),
        "secondary_sidebar_bg_color": surf(0.04), "secondary_sidebar_fg_color": fg,
        "card_bg_color": surf(0.06), "card_fg_color": fg,
        "dialog_bg_color": surf(0.06), "dialog_fg_color": fg,
        "popover_bg_color": surf(0.08), "popover_fg_color": fg,
        "thumbnail_bg_color": surf(0.06), "thumbnail_fg_color": fg,
        "accent_bg_color": acc, "accent_fg_color": acc_fg, "accent_color": acc,
        "destructive_bg_color": p["red"], "destructive_fg_color": on(p["red"], "#ffffff", "#000000"), "destructive_color": p["red"],
        "success_bg_color": p["green"], "success_fg_color": on(p["green"], "#ffffff", "#000000"), "success_color": p["green"],
        "warning_bg_color": p["yellow"], "warning_fg_color": on(p["yellow"], "#ffffff", "#000000"), "warning_color": p["yellow"],
        "error_bg_color": p["red"], "error_fg_color": on(p["red"], "#ffffff", "#000000"), "error_color": p["red"],
        # nombres viejos de GTK 3 (temas que no son adw-gtk3)
        "theme_bg_color": bg, "theme_fg_color": fg, "theme_base_color": surf(0.03), "theme_text_color": fg,
        "theme_selected_bg_color": acc, "theme_selected_fg_color": acc_fg,
        "insensitive_bg_color": bg, "insensitive_fg_color": mix(fg, bg, 0.5), "borders": surf(0.14),
    }
    head = "/* discada (AppColors.py): colores del look para GTK 3/4. Se regenera solo. */\n"
    css = head + "".join(f"@define-color {k} {v};\n" for k, v in names.items())
    # GTK 4.16+ y libadwaita 1.6+ leen variables CSS (--accent-bg-color…);
    # GTK 3 no entiende :root, por eso solo va en gtk-4.0
    root = "".join(f"  --{k.replace('_', '-')}: {v};\n" for k, v in names.items()
                   if not k.startswith(("theme_", "insensitive_")) and k != "borders")
    return css, css + ":root {\n" + root + "}\n"


def ensure_import(gtkdir):
    os.makedirs(gtkdir, exist_ok=True)
    css = os.path.join(gtkdir, "gtk.css")
    line = "@import 'discada.css';"
    try:
        text = open(css).read()
    except OSError:
        text = ""
    if line not in text:
        # al final: gana sobre lo que importe antes (p. ej. colors.css de KDE)
        open(css, "w").write(text.rstrip("\n") + ("\n" if text.strip() else "") + line + "\n")


def qt_conf(p):
    bg, fg, acc = p["bg"], p["fg"], p["acc"]
    k = 1 if p["dark"] else -1
    surf = lambda t: mix(fg, bg, t) if k > 0 else mix("#000000", bg, t * 0.6)
    acc_fg = on(acc, "#ffffff" if p["dark"] else bg, "#000000" if p["dark"] else fg)
    dim = mix(fg, bg, 0.5)

    def row(text, btn_text, hi_text):
        roles = [text, surf(0.08), surf(0.2), surf(0.14), surf(0.02) if k > 0 else surf(0.3), surf(0.3),
                 text, fg, btn_text, surf(0.03), bg, "#000000", acc, hi_text, acc, p["purple"],
                 surf(0.06), bg, surf(0.1), fg]
        return ", ".join("#ff" + c[1:] for c in roles) + ", #80" + dim[1:]

    return ("[ColorScheme]\n"
            f"active_colors={row(fg, fg, acc_fg)}\n"
            f"disabled_colors={row(dim, dim, dim)}\n"
            f"inactive_colors={row(fg, fg, acc_fg)}\n")


def set_qtct(name):
    conf = os.path.join(CFG, name, f"{name}.conf")
    path = f"$HOME/.config/{name}/colors/discada.conf"
    try:
        text = open(conf).read()
    except OSError:
        text = "[Appearance]\n"
    new = re.sub(r"^color_scheme_path=.*$", f"color_scheme_path={path}", text, flags=re.M)
    new = re.sub(r"^custom_palette=.*$", "custom_palette=true", new, flags=re.M)
    new = re.sub(r"^style=.*$", "style=Fusion", new, flags=re.M)
    if new != text:
        open(conf, "w").write(new)


def gsettings(key, value):
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, value], capture_output=True)


def main():
    p = palette()
    if not p:
        return
    css3, css4 = gtk_css(p)
    for v, css in (("gtk-3.0", css3), ("gtk-4.0", css4)):
        d = os.path.join(CFG, v)
        ensure_import(d)
        open(os.path.join(d, "discada.css"), "w").write(css)
    for name in ("qt5ct", "qt6ct"):
        os.makedirs(os.path.join(CFG, name, "colors"), exist_ok=True)
        open(os.path.join(CFG, name, "colors/discada.conf"), "w").write(qt_conf(p))
        set_qtct(name)
    # claro/oscuro; cambiar el tema hace que las apps GTK abiertas relean gtk.css
    scheme = "prefer-dark" if p["dark"] else "prefer-light"
    have_adw = any(os.path.isdir(os.path.join(d, "adw-gtk3")) for d in
                   ("/usr/share/themes", os.path.join(HOME, ".local/share/themes"), os.path.join(HOME, ".themes")))
    gsettings("color-scheme", scheme)
    if have_adw:
        theme = "adw-gtk3-dark" if p["dark"] else "adw-gtk3"
        gsettings("gtk-theme", "Adwaita")
        gsettings("gtk-theme", theme)


if __name__ == "__main__":
    main()
