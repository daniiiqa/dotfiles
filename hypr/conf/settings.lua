-- Ajustes generales — https://wiki.hyprland.org/Configuring/Variables/
-- (look: decorations.conf / animations.conf)

hl.config({ general = {
    layout = "dwindle",
    resize_on_border = true,
} })

hl.config({ dwindle = {
    preserve_split = true,
    special_scale_factor = 0.8,
} })

hl.config({ master = {
    new_status = "master",
    new_on_top = 1,
    mfact = 0.5,
} })

hl.config({ input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    repeat_rate = 50,
    repeat_delay = 300,

    sensitivity = 0,
    numlock_by_default = true,
    left_handed = false,
    follow_mouse = 1,
    float_switch_override_focus = false,

    -- el trackpad: abajo, con lo de discada.conf

    touchdevice = {
        enabled = true,
    },

    tablet = {
        transform = 0,
        left_handed = 0,
    },
} })

-- Custom (dany): el trackpad sale de hypr/discada.conf (TRACKPAD_*), que el
-- updater no pisa; lo cambia el menú (SUPER+Shift+E → trackpad). Sin la
-- clave, lo de siempre de discada.
local tp = {}
do
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/discada.conf")
    if f then
        for line in f:lines() do
            local k, v = line:match('^(TRACKPAD_[%w_]+)="?([^"#%s]*)')
            if k then tp[k:sub(10)] = v end
        end
        f:close()
    end
end
local function si(k, def) local v = tp[k]; if v == nil or v == "" then return def end return v == "yes" end
local function num(k, def) return tonumber(tp[k]) or def end
local function txt(k, def) local v = tp[k]; return (v ~= nil and v ~= "") and v or def end

local pad = {
    enabled = si("ENABLED", true),
    natural_scroll = si("NATURAL", true),
    tap_to_click = si("TAP", true),
    tap_and_drag = si("TAP_DRAG", true),
    drag_lock = ({ no = 0, timeout = 1, sticky = 2 })[txt("DRAG_LOCK", "no")] or 0,
    tap_button_map = txt("TAP_MAP", "lrm"),
    clickfinger_behavior = txt("CLICK", "areas") == "fingers",
    middle_button_emulation = si("MIDDLE", false),
    disable_while_typing = si("DWT", true),
    scroll_factor = num("SCROLL_SPEED", 1.0),
    drag_3fg = ({ no = 0, ["3"] = 1, ["4"] = 2 })[txt("DRAG_3FG", "no")] or 0,
}

hl.config({ input = { touchpad = {
    natural_scroll = pad.natural_scroll,
    tap_to_click = pad.tap_to_click,
    tap_and_drag = pad.tap_and_drag,
    drag_lock = pad.drag_lock,
    tap_button_map = pad.tap_button_map,
    clickfinger_behavior = pad.clickfinger_behavior,
    middle_button_emulation = pad.middle_button_emulation,
    disable_while_typing = pad.disable_while_typing,
    scroll_factor = pad.scroll_factor,
    drag_3fg = pad.drag_3fg,
} } })

-- velocidad, aceleración, cómo se hace scroll y prendido/apagado son de cada
-- aparato (si no, también le tocarían al mouse): a cada trackpad por su
-- nombre, como lo ve Hyprland ("FTCS1000:00 2808:0105 Touchpad" →
-- "ftcs1000:00-2808:0105-touchpad")
do
    local f = io.open("/proc/bus/input/devices")
    if f then
        local seen = {}
        for line in f:lines() do
            local name = line:match('^N: Name="(.*)"$')
            if name and name:lower():find("touchpad", 1, true) then
                name = name:lower():gsub(" ", "-")
                if not seen[name] then
                    seen[name] = true
                    local spec = {
                        name = name,
                        sensitivity = num("SPEED", 0),
                        accel_profile = txt("ACCEL", "adaptive"),
                        scroll_method = txt("SCROLL_METHOD", "2fg"),
                    }
                    for k, v in pairs(pad) do spec[k] = v end
                    hl.device(spec)
                end
            end
        end
        f:close()
    end
end

hl.config({ gestures = {
    workspace_swipe_distance = 500,
    workspace_swipe_invert = si("SWIPE_INVERT", true),
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = true,
} })
local swipe = tonumber(txt("SWIPE", "3"))
if swipe then hl.gesture({ fingers = swipe, direction = "horizontal", action = "workspace" }) end
if si("ZOOM", true) then  -- zoom con 4 dedos
    hl.gesture({ fingers = 4, direction = "up", action = function() zoom_in() end })
    hl.gesture({ fingers = 4, direction = "down", action = function() zoom_out() end })
end

hl.config({ misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 2,
    mouse_move_enables_dpms = true,
    -- Custom (dany): una tecla también prende la pantalla (si se apaga sola,
    -- que no haga falta el touchpad)
    key_press_enables_dpms = true,
    enable_swallow = false,
    swallow_regex = "^(kitty)$",
    focus_on_activate = false,
    initial_workspace_tracking = 0,
    middle_click_paste = false,
    enable_anr_dialog = true,
    anr_missed_pings = 15,
    allow_session_lock_restore = true,
    on_focus_under_fullscreen = 1,
} })

hl.config({ binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = true,
    pass_mouse_when_bound = false,
} })

hl.config({ xwayland = {
    enabled = true,
    force_zero_scaling = true,
} })

hl.config({ render = {
    direct_scanout = 0,
} })

hl.config({ cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = 2,
    enable_hyprcursor = true,
    warp_on_change_workspace = 2,
    no_warps = true,
} })
