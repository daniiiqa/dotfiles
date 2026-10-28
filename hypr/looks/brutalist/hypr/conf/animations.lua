-- Look brutalist: movimiento seco — curvas lineales y muy cortas, sin easing
hl.config({ animations = {
    enabled = true,

} })
hl.curve("cut", { type = "bezier", points = { {0.9, 0}, {0.1, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 1.5, bezier = "cut", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.5, bezier = "cut", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "liner", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.5, bezier = "cut" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.5, bezier = "cut", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "cut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "cut", style = "slidevert" })
