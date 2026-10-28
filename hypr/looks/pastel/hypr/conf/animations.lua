-- Look pastel: animaciones suaves — fades y deslizamientos lentos, sin rebote
hl.config({ animations = {
    enabled = true,

} })
hl.curve("soft", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.curve("gentle", { type = "bezier", points = { {0.4, 0}, {0.2, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "soft", style = "popin 90%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "soft", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "gentle", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "soft" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "gentle" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "gentle" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "soft", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "soft", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "soft", style = "slidefadevert 15%" })
