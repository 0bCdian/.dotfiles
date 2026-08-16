-- ============================================================================
--  hyprland/keybinds.lua  (translated from hyprland/keybinds.conf)
-- ----------------------------------------------------------------------------
--  Your hyprland/keybinds.conf was ~95% commented out (the default
--  illogical-impulse cheatsheet binds, which you disabled). Only the two
--  ACTIVE binds are translated here. Your real binds live in custom/keybinds.lua.
--
--  Bind mapping cheatsheet (old -> new):
--     bind  = MODS, KEY, dispatcher, args   -> hl.bind("MODS + KEY", hl.dsp.<...>())
--     bindd = MODS, KEY, "Desc", ...        -> add { description = "Desc" }
--     exec, CMD                             -> hl.dsp.exec_cmd("CMD")
--     global, NAME                          -> hl.dsp.global("NAME")
-- ============================================================================

-- Wallpaper selector: the waypaper-engine GUI owns wallpapers.
hl.bind("CTRL + SUPER + T",
    hl.dsp.exec_cmd("waypaper-engine"),
    { description = "Open wallpaper selector (waypaper-engine)" })

-- Restart the omarchy shell.
hl.bind("CTRL + SUPER + R",
    hl.dsp.exec_cmd("omarchy-restart-shell"),
    { description = "Restart omarchy shell" })
