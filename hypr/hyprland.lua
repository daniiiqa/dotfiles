-- discada — Hyprland en Lua · https://wiki.hypr.land/Configuring/Start/
--
-- La config activa desde Hyprland 0.57, que ya no lee .conf. No borrar este
-- archivo: sin él Hyprland genera uno de ejemplo y discada no carga.
-- Revisarla sin aplicar:
--   Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
--
--   conf/defaults.lua      apps por defecto (term, files, edit…)
--   conf/env.lua           variables de entorno
--   conf/startup.lua       lo que arranca con la sesión
--   conf/settings.lua      input, layouts, gestos, misc
--   conf/decorations.lua   look: bordes, gaps, sombras, blur (lo pone LookSwitch)
--   conf/animations.lua    look: animaciones (lo pone LookSwitch)
--   conf/windowrules.lua   reglas de ventanas y capas
--   conf/keybinds.lua      atajos
--   monitors.lua / workspaces.lua   los escribe nwg-displays

require("conf.defaults")
require("conf.env")
require("conf.startup")
require("conf.settings")
require("conf.decorations")
require("conf.animations")
require("conf.windowrules")
require("conf.keybinds")

-- los de nwg-displays, si ya los escribió
for _, name in ipairs({ "monitors", "workspaces" }) do
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/" .. name .. ".lua")
    if f then
        f:close()
        require(name)
    end
end
