-- Lo que arranca con la sesión (una vez, al iniciar Hyprland)

local scriptsDir = "$HOME/.config/hypr/scripts"

-- Videos de wallpaper: una línea "exec-once = mpvpaper …" por monitor en
-- livewallpaper.conf, que escriben WallpaperSelect.sh y LookWallpaper.sh
local function live_wallpapers()
    local cmds = {}
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/conf/livewallpaper.conf")
    if f then
        for line in f:lines() do
            local cmd = line:match("^exec%-once%s*=%s*(.+)$")
            if cmd then cmds[#cmds + 1] = cmd end
        end
        f:close()
    end
    return cmds
end

hl.on("hyprland.start", function()
    -- para probar la config en un Hyprland anidado sin arrancar nada dos veces
    if os.getenv("DISCADA_NO_START") then return end

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- Wallpapers independientes por monitor: awww (imágenes/gifs) siempre vivo
    hl.exec_cmd("awww-daemon --format xrgb")
    for _, cmd in ipairs(live_wallpapers()) do
        hl.exec_cmd(cmd)
    end

    -- Barra, notificaciones (arre las arranca D-Bus solo), idle
    hl.exec_cmd(scriptsDir .. "/AppStrip.py daemon")  -- apps abiertas en waybar (antes que la barra)
    hl.exec_cmd(scriptsDir .. "/FitGuard.py")  -- apps que no caben en su tile (Discord) flotan
    hl.exec_cmd(scriptsDir .. "/Waybar.sh")  -- relanza waybar si crashea al inicio (mpris)
    hl.exec_cmd(scriptsDir .. "/FirstRun.sh")  -- solo la primera vez en una máquina nueva
    hl.exec_cmd("hypridle")
    hl.exec_cmd(scriptsDir .. "/Battery.py watch")  -- laptops: avisos, ahorro solo (BATTERY_SAVER_AT)
    hl.exec_cmd(scriptsDir .. "/FontSize.py apply")  -- tamaño de letra de discada (hypr/discada.conf)
    hl.exec_cmd(scriptsDir .. "/Recorder.sh autostart")  -- replay buffer (hypr/recorder.conf)

    -- Terminal dropdown (SUPER+Shift+Enter)
    hl.exec_cmd(scriptsDir .. "/Dropterminal.sh kitty")

    -- Portapapeles
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
