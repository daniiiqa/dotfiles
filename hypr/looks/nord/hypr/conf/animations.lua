-- Look nord: calmas — deslizamientos suaves de duración media
hl.config({ animations = {
    enabled = true,

} })
hl.curve("calm", { type = "bezier", points = { {0.25, 0.8}, {0.25, 1} } })
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "calm", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "calm", style = "popin 94%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "calm" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "calm" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "calm" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "calm", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "calm", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "calm", style = "slidevert" })
