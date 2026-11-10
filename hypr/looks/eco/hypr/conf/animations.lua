-- Look glass: animaciones con resorte — overshoot ligero al entrar
hl.config({ animations = {
    enabled = true,

} })
hl.curve("spring", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.08} } })
hl.curve("out", { type = "bezier", points = { {0.3, 0}, {0.2, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "spring", style = "popin 85%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "spring", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "out", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "spring" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "out" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 40, bezier = "liner", style = "loop" })  -- el canto de luz gira
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "out" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "spring", style = "popin 90%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "spring", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "spring", style = "slidevert" })
