-- Look ofrenda: lentas y tibias, como la llama de una vela — las ventanas se
-- encienden desde 85% con un fade largo; el borde gira despacio.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("flame", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("smoke", { type = "bezier", points = { {0.4, 0}, {0.6, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "flame", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "smoke", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "flame" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "smoke" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "smoke", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "smoke" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "flame", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "flame", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "flame", style = "slidevert" })
