-- ============================================================================
--  custom/keybinds.lua  (translated from custom/keybinds.conf)
-- ----------------------------------------------------------------------------
--  This holds your actual, active keybinds.
--
--  Old conf variables ($main_mod, ...) become Lua locals. The old prefix flags
--  on the `bind` keyword become an options table on hl.bind():
--     bind   -> hl.bind(...)                       (normal)
--     bindm  -> { mouse = true }                   (mouse bind, e.g. drag/resize)
--     binde  -> { repeating = true }               (repeats while held)
--     bindl  -> { locked = true }                  (works on lock screen)
--     bindr  -> { release = true }                 (fires on key release)
--     bindd  -> { description = "..." }             (shown on cheatsheets)
--
--  Dispatcher map (old -> new):
--     exec               -> hl.dsp.exec_cmd("...")
--     killactive         -> hl.dsp.window.close()
--     movewindow (mouse) -> hl.dsp.window.drag()
--     resizewindow(mouse)-> hl.dsp.window.resize()
--     movewindow, DIR    -> hl.dsp.window.move({ direction = "left/right/up/down" })
--     resizeactive, X Y  -> hl.dsp.window.resize({ x=X, y=Y, relative=true })
--     fullscreen         -> hl.dsp.window.fullscreen()
--     togglefloating     -> hl.dsp.window.float({ action = "toggle" })
--     pin                -> hl.dsp.window.pin()
--     movefocus, DIR     -> hl.dsp.focus({ direction = "..." })
--     workspace, SEL     -> hl.dsp.focus({ workspace = SEL })
--     movetoworkspace    -> hl.dsp.window.move({ workspace = SEL })            (follows)
--     movetoworkspacesilent -> hl.dsp.window.move({ workspace = SEL, follow=false })
--     togglespecialworkspace, N -> hl.dsp.workspace.toggle_special("N")
--     togglegroup        -> hl.dsp.group.toggle()
--     cyclenext          -> hl.dsp.window.cycle_next()
--     centerwindow       -> hl.dsp.window.center()
--     bringactivetotop   -> hl.dsp.window.bring_to_top()
--     changegroupactive  -> hl.dsp.group.next()
-- ============================================================================

local home = os.getenv("HOME")

local mod       = "SUPER"
local mod_shift = "SUPER + SHIFT"
local mod_alt   = "SUPER + ALT"
local mod_ctl   = "SUPER + CTRL"

------------------------------ User ------------------------------
hl.bind("CTRL + SUPER + Slash",
    hl.dsp.exec_cmd("xdg-open " .. home .. "/.config/illogical-impulse/config.json"),
    { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash",
    hl.dsp.exec_cmd("xdg-open " .. home .. "/.config/hypr/custom/keybinds.conf"),
    { description = "Edit extra keybinds" })

------------------------------ System ------------------------------
-- Mouse move/resize (bindm)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Move window in a direction (Super+Ctrl + jlik)
hl.bind(mod_ctl .. " + J", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod_ctl .. " + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod_ctl .. " + I", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod_ctl .. " + K", hl.dsp.window.move({ direction = "down" }))

-- Misc system keys
hl.bind("Print",               hl.dsp.exec_cmd(home .. "/.config/rofi/applets/bin/screenshot.sh"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 30+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 30-"))
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("amixer set Master 5%+"))
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("amixer set Master 5%-"))
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("amixer set Master toggle"))

hl.bind(mod_shift .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + Q",       hl.dsp.window.close())
hl.bind(mod .. " + P",       hl.dsp.window.pin())
hl.bind(mod_shift .. " + K", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mod .. " + M",       hl.dsp.exec_cmd(home .. "/.config/rofi/applets/bin/powermenu.sh"))
hl.bind(mod .. " + F",       hl.dsp.window.float({ action = "toggle" }))

hl.bind("Insert", hl.dsp.workspace.toggle_special("clipboard"))

-- Workspace nav by relative index
hl.bind(mod .. " + left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + right", hl.dsp.focus({ workspace = "r+1" }))

-- Move focus (Super + jlik)
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + I", hl.dsp.focus({ direction = "up" }))

-- Resize active window (binde -> repeating). resizeactive deltas are relative.
hl.bind(mod_alt .. " + L", hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
hl.bind(mod_alt .. " + J", hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
hl.bind(mod_alt .. " + I", hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
hl.bind(mod_alt .. " + K", hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })

-- Special "hidden" scratchpad
hl.bind(mod .. " + S",  hl.dsp.workspace.toggle_special("hidden"), { release = true }) -- bindr
hl.bind(mod .. " + up", hl.dsp.window.move({ workspace = "special:hidden", follow = false }))
hl.bind(mod .. " + down", hl.dsp.exec_cmd(home .. "/.config/hypr/custom/scripts/move_to_active_workspace.sh"))

-- Move window to relative workspace
hl.bind(mod_shift .. " + left",  hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mod_shift .. " + right", hl.dsp.window.move({ workspace = "r+1" }))

-- Scroll through workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + G",   hl.dsp.group.toggle())
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- ALT+TAB ran FOUR dispatchers on one key. In Lua we run them all from a
-- single callback function so order is guaranteed.
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.center())
    hl.dispatch(hl.dsp.window.bring_to_top())
    hl.dispatch(hl.dsp.group.next()) -- changegroupactive (cycle forward in group)
end)

hl.bind(mod_shift .. " + T", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
hl.bind(mod .. " + R",       hl.dsp.exec_cmd("ags -r 'recorder.start()'"))

-- Laptop lid switch (bindl -> locked)
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dpms on"),   { locked = true })

------------------------ Workspace switch / move ------------------------
-- Old: 20 nearly identical lines. A Lua loop does both directions at once.
--   Super + N         -> focus workspace N
--   Super + Shift + N -> move active window to workspace N
-- The number key for workspace 10 is "0".
for i = 1, 10 do
    local key = (i % 10) -- 10 -> "0"
    hl.bind(mod .. " + " .. key,       hl.dsp.focus({ workspace = i }))
    hl.bind(mod_shift .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

------------------------------ Programs ------------------------------
-- The old `[float]` exec prefix (a window rule for the spawned window) is kept
-- inline in the command string.
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("[float] nautilus"))
-- Launcher: vicinae retired -> omarchy.launcher (summoned over shell IPC).
-- ROLLBACK: swap the next line back to: hl.dsp.exec_cmd("vicinae toggle")
hl.bind(mod .. " + space",  hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.launcher"))
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod_shift .. " + E", hl.dsp.exec_cmd("bemoji -n"))

------------------------------ Omarchy shell ------------------------------
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("omarchy-menu"),                               { description = "Omarchy command menu" })
hl.bind(mod .. " + V",      hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.clipboard"), { description = "Clipboard history" })
hl.bind(mod .. " + Period", hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.emojis"),    { description = "Emoji picker" })
