  -- Look cromo: animaciones Y2K con rebote exagerado (overshoot)
  hl.config({ animations = {
      enabled = true,

  } })
  hl.curve("bounce", { type = "bezier", points = { {0.15, 0.9}, {0.25, 1.15} } })
  hl.curve("spring", { type = "bezier", points = { {0.1, 0.9}, {0.1, 1.2} } })
  hl.curve("out", { type = "bezier", points = { {0.3, 0}, {0.2, 1} } })
  hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })
  hl.animation({ leaf = "windows", enabled = true, speed = 8, bezier = "bounce", style = "popin 90%" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "spring", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "out", style = "fade 70%" })
  hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "spring" })
  hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "bounce" })
  hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })  -- el canto de luz gira más rápido
  hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "out" })
  hl.animation({ leaf = "layers", enabled = true, speed = 6, bezier = "spring", style = "popin 85%" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "spring", style = "slide" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "spring", style = "slidevert" })
