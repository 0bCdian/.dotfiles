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

-- bindd = Ctrl+Super, T, Toggle wallpaper selector, global, quickshell:wallpaperSelectorToggle
hl.bind("CTRL + SUPER + T",
    hl.dsp.global("quickshell:wallpaperSelectorToggle"),
    { description = "Toggle wallpaper selector" })

-- bind = Ctrl+Super, R, exec, killall ...; qs -c $qsConfig &   # Restart widgets
hl.bind("CTRL + SUPER + R",
    hl.dsp.exec_cmd("killall ags agsv1 gjs ydotool qs quickshell; qs -c " .. qsConfig .. " &"),
    { description = "Restart widgets" })
