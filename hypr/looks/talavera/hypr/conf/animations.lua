-- Look talavera: suaves y redondas, como esmalte que se asienta — popin
-- desde 90% con un rebote mínimo.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("glaze", { type = "bezier", points = { {0.22, 1.15}, {0.36, 1} } })
hl.curve("settle", { type = "bezier", points = { {0.4, 0}, {0.2, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "glaze", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "settle", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "glaze" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "settle" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "settle" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "glaze", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "settle", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "glaze", style = "slidevert" })
