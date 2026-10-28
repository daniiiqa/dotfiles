-- Look neon: rápidas con un pequeño rebote; el degradado del borde gira solo
hl.config({ animations = {
    enabled = true,

} })
hl.curve("zap", { type = "bezier", points = { {0.1, 1}, {0.2, 1.05} } })
hl.curve("out", { type = "bezier", points = { {0.3, 0}, {0.2, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "zap", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "zap", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "out", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "zap" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "out" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "out" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "zap", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "zap", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "zap", style = "slidevert" })
