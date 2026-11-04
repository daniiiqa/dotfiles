-- Look obsidiana: pesadas y calmadas, como piedra — las ventanas se abren
-- como lámina (gnomed), los workspaces suben y bajan (la barra está abajo),
-- los menús salen desde abajo.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("piedra", { type = "bezier", points = { {0.2, 0.9}, {0.1, 1} } })
hl.curve("pulido", { type = "bezier", points = { {0.5, 0}, {0.5, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "piedra", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "pulido", style = "gnomed" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "piedra" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "pulido" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "pulido" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "piedra", style = "slide bottom" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "piedra", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "piedra", style = "slidefadevert 20%" })
