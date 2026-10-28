-- Look retro: nada se desliza — las ventanas solo aparecen/desaparecen rápido
hl.config({ animations = {
    enabled = true,

} })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 1.5, bezier = "liner", style = "popin 100%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "liner", style = "popin 100%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "liner" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "liner" })
hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "liner", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "liner", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1, bezier = "liner", style = "fade" })
