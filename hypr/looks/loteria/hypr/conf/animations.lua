-- Look loteria: como repartir cartas — las ventanas entran deslizándose de
-- lado con un rebote corto y se van rápido.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("deal", { type = "bezier", points = { {0.34, 1.4}, {0.64, 1} } })
hl.curve("snap", { type = "bezier", points = { {0.6, 0}, {0.9, 0.4} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "deal", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "snap", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "deal" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "deal" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "snap" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "deal", style = "slide top" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "deal", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "deal", style = "slidevert" })
