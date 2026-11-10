-- Look frutiger-aero: animaciones de burbuja — las ventanas brotan con rebote
-- (como burbuja que se infla) y el brillo del borde gira despacio
hl.config({ animations = {
    enabled = true,

} })
hl.curve("burbuja", { type = "bezier", points = { {0.34, 1.56}, {0.64, 1} } })
hl.curve("out", { type = "bezier", points = { {0.3, 0}, {0.2, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "burbuja", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "burbuja", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "out", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "burbuja" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "out" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "liner", style = "loop" })  -- el brillo gira despacio
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "out" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "burbuja", style = "popin 90%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "out", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "burbuja", style = "slidevert" })
