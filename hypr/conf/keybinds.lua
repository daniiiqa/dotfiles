-- Atajos — https://wiki.hyprland.org/Configuring/Binds/
-- bindd = MODS, tecla, descripción, dispatcher, args
-- La descripción es la que muestra el buscador de atajos (SUPER+Shift+K).

local d = require("conf.defaults")
local scriptsDir = "$HOME/.config/hypr/scripts"

-- flotar (o volver al tile) todas las ventanas del workspace
local function float_all()
    local ws = hl.get_active_workspace()
    if not ws then return end
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
    end
end

-- zoom del cursor (también lo usan los gestos de 4 dedos, en settings.lua)
local function zoom(k)
    return function()
        local f = hl.get_config("cursor.zoom_factor") or 1
        hl.config({ cursor = { zoom_factor = math.max(1, math.max(f, 1) * k) } })
    end
end
zoom_in, zoom_out = zoom(1.5), zoom(1 / 1.5)

-- ─── Apps ────────────────────────────────────────────────────────────────────
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "app launcher" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd(d.term), { description = "terminal" })
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh " .. d.term), { description = "dropdown terminal" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(d.files), { description = "file manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("xdg-open \"https://\""), { description = "browser" })
hl.bind("SUPER + M", hl.dsp.exec_cmd(scriptsDir .. "/FocusOrLaunch.sh rola kitty --class rola -e rola"), { description = "music player" })

-- ─── Menús ───────────────────────────────────────────────────────────────────
hl.bind("SUPER + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "cheat sheet" })
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"), { description = "search keybinds" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/QuickSettings.sh"), { description = "discada settings" })
hl.bind("SUPER + S", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"), { description = "web search" })
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("rofi -show window"), { description = "window switcher" })
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"), { description = "emoji menu" })
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd(scriptsDir .. "/RofiCalc.sh"), { description = "calculator" })
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"), { description = "clipboard manager" })
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(scriptsDir .. "/Vato.sh notifications"), { description = "notification panel" })

-- ─── Wallpaper / look ────────────────────────────────────────────────────────
hl.bind("SUPER + T", hl.dsp.exec_cmd(scriptsDir .. "/LookSwitch.sh"), { description = "switch look" })
hl.bind("SUPER + W", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperSelect.sh"), { description = "select wallpaper" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperEffects.sh"), { description = "wallpaper effects" })
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperRandom.sh"), { description = "random wallpaper" })
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh --full"), { description = "refresh bar and menus" })
hl.bind("SUPER + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 -x empalme"), { description = "toggle bar" })
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "toggle blur" })
hl.bind("SUPER + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "toggle window opacity" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "toggle game mode" })

-- ─── Sesión ──────────────────────────────────────────────────────────────────
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"), { description = "lock screen" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "power menu" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "exit Hyprland" })

-- ─── Ventanas ────────────────────────────────────────────────────────────────
hl.bind("SUPER + C", hl.dsp.window.close(), { description = "close window" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"), { description = "kill active process" })
hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }), { description = "toggle float" })
hl.bind("SUPER + ALT + SPACE", float_all, { description = "float all windows" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen(), { description = "fullscreen" })
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = 1 }), { description = "maximize" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "toggle pseudo (dwindle)" })
hl.bind("SUPER + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"), { description = "toggle master/dwindle layout" })
hl.bind("SUPER + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })

-- J/K ciclan ventanas; ChangeLayout.sh los re-mapea al cambiar a master
hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "next window" })
hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "previous window" })
hl.bind("ALT + tab", hl.dsp.window.cycle_next(), { description = "cycle next window" })
hl.bind("ALT + tab", hl.dsp.window.bring_to_top(), { description = "bring active to top" })

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }), { description = "focus left" })
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }), { description = "focus right" })
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }), { description = "focus up" })
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }), { description = "focus down" })

hl.bind("SUPER + CTRL + left", hl.dsp.window.move({ direction = "left" }), { description = "move window left" })
hl.bind("SUPER + CTRL + right", hl.dsp.window.move({ direction = "right" }), { description = "move window right" })
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ direction = "up" }), { description = "move window up" })
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ direction = "down" }), { description = "move window down" })

hl.bind("SUPER + ALT + left", hl.dsp.window.swap({ direction = "left" }), { description = "swap window left" })
hl.bind("SUPER + ALT + right", hl.dsp.window.swap({ direction = "right" }), { description = "swap window right" })
hl.bind("SUPER + ALT + up", hl.dsp.window.swap({ direction = "up" }), { description = "swap window up" })
hl.bind("SUPER + ALT + down", hl.dsp.window.swap({ direction = "down" }), { description = "swap window down" })

hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { description = "resize left", repeating = true })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { description = "resize right", repeating = true })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { description = "resize up", repeating = true })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { description = "resize down", repeating = true })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "move window", mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "resize window", mouse = true })

-- ─── Grupos ──────────────────────────────────────────────────────────────────
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "toggle group" })
hl.bind("SUPER + CTRL + tab", hl.dsp.group.next(), { description = "next in group" })
hl.bind("SUPER + CTRL + K", hl.dsp.window.move({ into_group = "l" }), { description = "move left into group" })
hl.bind("SUPER + CTRL + L", hl.dsp.window.move({ into_group = "r" }), { description = "move right into group" })
hl.bind("SUPER + CTRL + H", hl.dsp.window.move({ out_of_group = true }), { description = "move out of group" })

-- ─── Workspaces ──────────────────────────────────────────────────────────────
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "previous workspace" })
hl.bind("SUPER + period", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })

hl.bind("SUPER + U", hl.dsp.workspace.toggle_special(), { description = "toggle special workspace" })
hl.bind("SUPER + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "move to special workspace" })

-- code:10..19 = teclas 1..0 (independiente del layout de teclado)
hl.bind("SUPER + code:10", hl.dsp.focus({ workspace = 1 }), { description = "workspace 1" })
hl.bind("SUPER + code:11", hl.dsp.focus({ workspace = 2 }), { description = "workspace 2" })
hl.bind("SUPER + code:12", hl.dsp.focus({ workspace = 3 }), { description = "workspace 3" })
hl.bind("SUPER + code:13", hl.dsp.focus({ workspace = 4 }), { description = "workspace 4" })
hl.bind("SUPER + code:14", hl.dsp.focus({ workspace = 5 }), { description = "workspace 5" })
hl.bind("SUPER + code:15", hl.dsp.focus({ workspace = 6 }), { description = "workspace 6" })
hl.bind("SUPER + code:16", hl.dsp.focus({ workspace = 7 }), { description = "workspace 7" })
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = 8 }), { description = "workspace 8" })
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = 9 }), { description = "workspace 9" })
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = 10 }), { description = "workspace 10" })

hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 }), { description = "move to workspace 1" })
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 }), { description = "move to workspace 2" })
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 }), { description = "move to workspace 3" })
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 }), { description = "move to workspace 4" })
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 }), { description = "move to workspace 5" })
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 }), { description = "move to workspace 6" })
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 }), { description = "move to workspace 7" })
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 }), { description = "move to workspace 8" })
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 }), { description = "move to workspace 9" })
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }), { description = "move to workspace 10" })
hl.bind("SUPER + SHIFT + bracketleft", hl.dsp.window.move({ workspace = -1 }), { description = "move to previous workspace" })
hl.bind("SUPER + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), { description = "move to next workspace" })

hl.bind("SUPER + CTRL + code:10", hl.dsp.window.move({ workspace = 1, follow = false }), { description = "move silently to workspace 1" })
hl.bind("SUPER + CTRL + code:11", hl.dsp.window.move({ workspace = 2, follow = false }), { description = "move silently to workspace 2" })
hl.bind("SUPER + CTRL + code:12", hl.dsp.window.move({ workspace = 3, follow = false }), { description = "move silently to workspace 3" })
hl.bind("SUPER + CTRL + code:13", hl.dsp.window.move({ workspace = 4, follow = false }), { description = "move silently to workspace 4" })
hl.bind("SUPER + CTRL + code:14", hl.dsp.window.move({ workspace = 5, follow = false }), { description = "move silently to workspace 5" })
hl.bind("SUPER + CTRL + code:15", hl.dsp.window.move({ workspace = 6, follow = false }), { description = "move silently to workspace 6" })
hl.bind("SUPER + CTRL + code:16", hl.dsp.window.move({ workspace = 7, follow = false }), { description = "move silently to workspace 7" })
hl.bind("SUPER + CTRL + code:17", hl.dsp.window.move({ workspace = 8, follow = false }), { description = "move silently to workspace 8" })
hl.bind("SUPER + CTRL + code:18", hl.dsp.window.move({ workspace = 9, follow = false }), { description = "move silently to workspace 9" })
hl.bind("SUPER + CTRL + code:19", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "move silently to workspace 10" })
hl.bind("SUPER + CTRL + bracketleft", hl.dsp.window.move({ workspace = -1, follow = false }), { description = "move silently to previous workspace" })
hl.bind("SUPER + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "move silently to next workspace" })

-- ─── Monitores ───────────────────────────────────────────────────────────────
hl.bind("SUPER + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }), { description = "workspace to left monitor" })
hl.bind("SUPER + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }), { description = "workspace to right monitor" })
hl.bind("SUPER + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }), { description = "workspace to upper monitor" })
hl.bind("SUPER + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }), { description = "workspace to lower monitor" })

-- ─── Zoom ────────────────────────────────────────────────────────────────────
hl.bind("SUPER + ALT + mouse_down", zoom_in, { description = "zoom in" })
hl.bind("SUPER + ALT + mouse_up", zoom_out, { description = "zoom out" })

-- ─── Teclado ─────────────────────────────────────────────────────────────────
hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/KeyboardLayout.sh switch"), { description = "switch keyboard layout (global)", locked = true, non_consuming = true })
hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), { description = "switch keyboard layout (per window)", locked = true, non_consuming = true })

-- ─── Capturas ────────────────────────────────────────────────────────────────
hl.bind("SUPER + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "screenshot" })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "screenshot (area)" })
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "screenshot in 5s" })
hl.bind("SUPER + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "screenshot in 10s" })
hl.bind("ALT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "screenshot (active window)" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "screenshot (swappy)" })

-- ─── Grabar (Recorder.sh, gpu-screen-recorder sin gsr-ui) ────────────────────
hl.bind("ALT + Z", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh menu"), { description = "recorder menu" })
hl.bind("ALT + F9", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh screen"), { description = "record screen (start/stop)" })
hl.bind("ALT + CTRL + F9", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh region"), { description = "record region" })
hl.bind("ALT + SHIFT + F9", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh window"), { description = "record active window" })
hl.bind("ALT + F7", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh pause"), { description = "pause recording" })
hl.bind("ALT + F10", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh save"), { description = "save replay" })
hl.bind("ALT + SHIFT + F10", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh replay"), { description = "replay on/off" })

-- ─── Teclas multimedia ───────────────────────────────────────────────────────
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { description = "volume up", locked = true, repeating = true })
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { description = "volume down", locked = true, repeating = true })
hl.bind("ALT + xf86audioraisevolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc-precise"), { description = "volume up (fine)", locked = true, repeating = true })
hl.bind("ALT + xf86audiolowervolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec-precise"), { description = "volume down (fine)", locked = true, repeating = true })
hl.bind("xf86audiomute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { description = "toggle mute", locked = true })
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { description = "toggle mic mute", locked = true })
hl.bind("xf86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { description = "pause", locked = true })
hl.bind("xf86AudioPlay", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { description = "play", locked = true })
hl.bind("xf86AudioNext", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"), { description = "next track", locked = true })
hl.bind("xf86AudioPrev", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"), { description = "previous track", locked = true })
hl.bind("xf86audiostop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { description = "stop", locked = true })
hl.bind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { description = "sleep", locked = true })
hl.bind("xf86Rfkill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { description = "airplane mode", locked = true })

-- ─── Laptop: brillo y batería (en una de escritorio no hacen nada) ──────────
hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"), { description = "brightness up", locked = true, repeating = true })
hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"), { description = "brightness down", locked = true, repeating = true })
hl.bind("ALT + xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc-precise"), { description = "brightness up (fine)", locked = true, repeating = true })
hl.bind("ALT + xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec-precise"), { description = "brightness down (fine)", locked = true, repeating = true })
hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --kbd-inc"), { description = "keyboard light up", locked = true, repeating = true })
hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --kbd-dec"), { description = "keyboard light down", locked = true, repeating = true })
hl.bind("xf86Battery", hl.dsp.exec_cmd(scriptsDir .. "/Battery.py saver"), { description = "battery saver on/off", locked = true })
