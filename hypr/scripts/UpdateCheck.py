#!/usr/bin/env python3
"""Qué archivos tuyos toca una actualización de discada (install.sh --update).

Compara lo que hay en ~/.config con lo que instaló la versión anterior (BASE,
un commit del repo) y con lo que va a instalar la nueva (el HEAD del repo):

  replace  RUTA   lo cambiaste y la versión nueva también: se reemplaza
                  (lo tuyo queda en el respaldo)
  keep     RUTA   lo cambiaste y la versión nueva no: se queda lo tuyo

Cuenta los archivos del repo que van a ~/.config (CONFIG_DIRS de install.sh,
sin los ajustes de KEEP_ON_UPDATE, que nunca se pisan) y los vivos del look
actual (los que LookBuild.py escribe desde hypr/looks/<look>/, con su fuente
y el tamaño de letra de FontSize.py).

  UpdateCheck.py REPO BASE
"""
import importlib.util
import os
import re
import subprocess
import sys
import tomllib

CFG = os.path.expanduser("~/.config")


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def show(repo, rev, path):
    return git(repo, "show", f"{rev}:{path}")


def tracked(repo, rev, dirs):
    out = git(repo, "ls-tree", "-r", "--name-only", "-z", rev, "--", *dirs) or b""
    return {p.decode() for p in out.split(b"\0") if p}


def bash_list(text, name):
    m = re.search(rf"^{name}=\((.*?)\)", text, re.S | re.M)
    if not m:
        return []
    body = re.sub(r"#[^\n]*", "", m.group(1))
    return body.split()


def font_shift(rel, text, d):
    """Lo mismo que FontSize.py le hace a lo vivo."""
    if not d:
        return text
    num = lambda x, like: f"{x:.1f}" if "." in like or x != int(x) else str(int(x))
    if rel in ("waybar/style.css", "swaync/style.css"):
        rx = r"(font-size:\s*)(\d+(?:\.\d+)?)(px)"
    elif rel == "kitty/kitty.conf":
        rx = r"(^font_size\s+)(\d+(?:\.\d+)?)()"
    else:
        return text
    return re.sub(rx, lambda m: m.group(1) + num(max(6, float(m.group(2)) + d), m.group(2)) + m.group(3), text, flags=re.M)


def main():
    repo, base = sys.argv[1], sys.argv[2]
    install = (show(repo, "HEAD", "install.sh") or b"").decode()
    dirs = bash_list(install, "CONFIG_DIRS")
    keep = set(bash_list(install, "KEEP_ON_UPDATE"))

    spec = importlib.util.spec_from_file_location("LookBuild", os.path.join(repo, "hypr/scripts/LookBuild.py"))
    lb = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(lb)
    try:
        look = open(os.path.join(CFG, "hypr/looks/.current")).read().strip()
    except OSError:
        look = ""
    try:
        applied = int(open(os.path.join(CFG, "hypr/looks/.fontsize")).read().strip() or 0)
    except (OSError, ValueError):
        applied = 0

    def live_files(rev):
        pre = f"hypr/looks/{look}/"
        return {p[len(pre):] for p in tracked(repo, rev, [pre]) if p[len(pre):] not in lb.GENERATED} if look else set()

    def expected(rev, rel, live):
        """Lo que la versión `rev` deja en ~/.config/rel (None si nada)."""
        if not live:
            return show(repo, rev, rel)
        raw = show(repo, rev, f"hypr/looks/{look}/{rel}")
        toml = show(repo, rev, f"hypr/looks/{look}/look.toml")
        if raw is None or toml is None:
            return raw
        try:
            text = raw.decode()
        except UnicodeDecodeError:
            return raw
        text = lb.render(text, lb.fonts(tomllib.loads(toml.decode())))
        return font_shift(rel, text, applied).encode()

    live = live_files(base) | live_files("HEAD")
    files = (tracked(repo, base, dirs) | tracked(repo, "HEAD", dirs)) - keep
    for rel in sorted(files | live):
        if rel in keep:
            continue
        try:
            ours = open(os.path.join(CFG, rel), "rb").read()
        except OSError:
            continue
        is_live = rel in live
        old = expected(base, rel, is_live)
        if old is None or ours == old:
            continue
        new = expected("HEAD", rel, is_live)
        if ours == new:
            continue
        # sin cambios en discada (o ya no viene en ella): no se toca
        print(f"{'keep' if new in (old, None) else 'replace'}\t{rel}")


if __name__ == "__main__":
    main()
