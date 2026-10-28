-- Animaciones — https://wiki.hyprland.org/Configuring/Animations/

-- Custom (dany): animaciones minimal — cortas, sin rebote ni overshoot
hl.config({ animations = {
    enabled = true,

} })
hl.curve("snap", { type = "bezier", points = { {0.2, 0.9}, {0.1, 1} } })
hl.curve("ease", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "snap", style = "popin 96%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "snap", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "ease", style = "popin 96%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "snap" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "ease" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "ease" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2, bezier = "ease" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "snap", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "snap", style = "slidefade 8%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "snap", style = "slidevert" })
