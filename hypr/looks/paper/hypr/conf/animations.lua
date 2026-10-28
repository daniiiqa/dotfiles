-- Look paper: como pasar una página — fundidos cortos, nada rebota
hl.config({ animations = {
    enabled = true,

} })
hl.curve("page", { type = "bezier", points = { {0.4, 0}, {0.2, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "page", style = "popin 98%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "page", style = "popin 98%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "page" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "page" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "page" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "page", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "page", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "page", style = "fade" })
