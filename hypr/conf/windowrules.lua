-- Reglas de ventanas — https://wiki.hyprland.org/Configuring/Window-Rules/
-- Sintaxis Hyprland >= 0.53: match:..., y las booleanas llevan valor ("float on").
--
-- Aquí NO va opacidad ni blur por app: eso es de cada look
-- (looks/<nombre>/hypr/conf/decorations.conf). Si se pusiera aquí, paper,
-- brutalist y retro dejarían de ser opacos y kitty quedaría doble-transparente.
-- La excepción es el video, que siempre va sólido.
-- Las layerrules (waybar, swaync, rofi, wlogout) también viven en cada look.

-- waybar aparece sin animación: al recargar (SUPER+Alt+R, cambio de look) la
-- barra vuelve al instante en vez de deslizarse
hl.layer_rule({ match = { namespace = "waybar" }, no_anim = true })

-- rofi con blur detrás: los looks con menú translúcido (glass) lo necesitan,
-- en los opacos no se nota
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0.1 })

-- ─── Tags ────────────────────────────────────────────────────────────────────
hl.window_rule({ match = { class = "^(zen|zen-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(kitty|kitty-dropterm)$" }, tag = "+terminal" })
hl.window_rule({ match = { class = "^(taco)$" }, tag = "+files" })
hl.window_rule({ match = { class = "^(discord|vesktop)$" }, tag = "+chat" })
hl.window_rule({ match = { class = "^([Ss]team|net.lutris.Lutris|org.prismlauncher.PrismLauncher|net.davidotek.pupgui2)$" }, tag = "+launcher" })
hl.window_rule({ match = { class = "^(steam_app_[0-9]+|gamescope)$" }, tag = "+game" })
hl.window_rule({ match = { class = "^(mpv|vlc)$" }, tag = "+video" })

-- Herramientas chicas: flotan centradas a 70%
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" }, tag = "+tool" })
hl.window_rule({ match = { class = "^(\\.?blueman-manager(-wrapped)?|nm-connection-editor)$" }, tag = "+tool" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look|qt5ct|qt6ct|kvantummanager)$" }, tag = "+tool" })
hl.window_rule({ match = { class = "^(org.gnome.baobab|org.gnome.SystemMonitor|gnome-system-monitor)$" }, tag = "+tool" })
hl.window_rule({ match = { class = "^(xarchiver|org.gnome.Loupe)$" }, tag = "+tool" })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, tag = "+tool" })

-- ─── Herramientas y diálogos ─────────────────────────────────────────────────
-- vato (Vato.sh): audio, bluetooth, red y sistema en la terminal
hl.window_rule({ match = { class = "^(vato|discada-update)$" }, float = true, center = true, size = "(monitor_w*0.55) (monitor_h*0.6)" })
hl.window_rule({ match = { tag = "tool" }, float = true, center = true, size = "(monitor_w*0.7) (monitor_h*0.7)" })
hl.window_rule({ match = { class = "^(qalculate-gtk)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(org.xfce.mousepad)$" }, float = true, center = true, size = "(monitor_w*0.5) (monitor_h*0.6)" })

-- Cheat sheet (SUPER+H, yad "Atajos") y demás ventanitas de yad
hl.window_rule({ match = { title = "^(Atajos)$" }, float = true, center = true, size = "(monitor_w*0.65) (monitor_h*0.9)" })
hl.window_rule({ match = { class = "^(yad)$", title = "negative:^(Atajos)$" }, float = true, center = true, size = "(monitor_w*0.2) (monitor_h*0.2)" })

-- Polkit / llaveros: siempre al frente y al centro
hl.window_rule({ match = { class = "^(hyprpolkitagent|org.kde.polkit-kde-authentication-agent-1|gcr-prompter)$" }, float = true, center = true, pin = true })

-- Abrir/guardar archivos
hl.window_rule({ match = { title = "^(Save As|Save File|Open File|Open Files|Open Folder)$" }, float = true, center = true, size = "(monitor_w*0.6) (monitor_h*0.6)" })

-- SDDM Background (SDDMWallpaperSync)
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true, center = true, size = "(monitor_w*0.16) (monitor_h*0.12)" })

-- Steam: la principal azulejada; amigos, ajustes, etc. flotan
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })

hl.window_rule({ match = { class = "^(hyprland-donate-screen)$" }, float = true, center = true })

-- ─── Video y juegos ──────────────────────────────────────────────────────────
hl.window_rule({ match = { tag = "video" }, opacity = "1.0 override 1.0 override", no_blur = true })
hl.window_rule({ match = { class = "^(mpv)$" }, float = true, center = true, size = "(monitor_w*0.6) (monitor_h*0.6)" })
hl.window_rule({ match = { tag = "game" }, opacity = "1.0 override 1.0 override", no_blur = true, no_shadow = true })

-- Picture-in-Picture de Zen: esquina superior derecha, siempre visible
hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, keep_aspect_ratio = true, size = "(monitor_w*0.3) (monitor_h*0.3)", move = "69% 7%", opacity = "1.0 override 1.0 override" })

-- Nada de bloquear/suspender mientras algo esté en pantalla completa
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- ─── Godot ───────────────────────────────────────────────────────────────────
-- La ventana del juego que lanza el editor (F5) NO toma la class "Godot": toma
-- el nombre del proyecto. El editor es class Godot, el juego es class Catalyst.
-- Sin esto Hyprland la azuleja y la parte contra el editor.
hl.window_rule({ match = { class = "^(Catalyst)$" }, float = true, center = true, size = "1600 900" })
-- Otro proyecto de Godot: copia la línea con su nombre de proyecto.
