-- Look outsider: lentas y suaves, como cinta que arranca — fades largos,
-- ventanas que aparecen desde 92% sin rebote.
hl.config({ animations = {
    enabled = true,

} })
hl.curve("tape", { type = "bezier", points = { {0.33, 0}, {0.15, 1} } })
hl.curve("drift", { type = "bezier", points = { {0.45, 0}, {0.55, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "tape", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "drift", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "tape" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "drift" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "drift" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "tape", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "drift", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "tape", style = "slidevert" })
