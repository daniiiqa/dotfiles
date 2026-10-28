-- Look fundidora: mecánicas, como una grúa de la acería — arrancan con fuerza,
-- frenan en seco; las ventanas caen desde arriba.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("crane", { type = "bezier", points = { {0.2, 0.9}, {0.25, 1} } })
hl.curve("press", { type = "bezier", points = { {0.7, 0}, {0.84, 0} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "crane", style = "slide top" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "press", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "crane" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "crane" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "crane" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "crane", style = "slide top" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "crane", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "crane", style = "slidevert" })
