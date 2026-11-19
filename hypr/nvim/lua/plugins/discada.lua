-- discada: LazyVim con el look del rice (colores, bordes, transparencia).
-- El colorscheme vive en colors/discada.lua y lua/discada.lua.
-- Custom (dany): solo dentro de Hyprland; en otro escritorio de la misma compu
-- (KDE…) o por ssh, nvim se queda con el colorscheme de LazyVim.
local en_hyprland = vim.env.HYPRLAND_INSTANCE_SIGNATURE ~= nil
  or (":" .. (vim.env.XDG_CURRENT_DESKTOP or "") .. ":"):find(":Hyprland:", 1, true) ~= nil
if not en_hyprland then
  return {}
end
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "discada" } },
}
