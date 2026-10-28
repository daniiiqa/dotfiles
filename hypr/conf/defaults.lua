-- Apps por defecto. QuickSettings.sh, RofiSearch.sh y WaybarScripts.sh leen
-- este archivo con sed: una por línea, `nombre = "valor",`.

hl.env("EDITOR", "nvim")

return {
    edit = "${EDITOR:-nano}",
    term = "kitty",
    files = "kitty --class taco -e taco",  -- taco, el explorador de discada (también abre las carpetas desde apps)
    search_engine = "https://www.google.com/search?q={}",
}
