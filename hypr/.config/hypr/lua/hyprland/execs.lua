-- ============================================================================
--  hyprland/execs.lua  (translated from hyprland/execs.conf)
-- ----------------------------------------------------------------------------
--  Old conf:
--     exec-once = CMD   ->  run ONCE when Hyprland starts
--     exec      = CMD   ->  run on every config reload
--
--  In Lua:
--     exec-once  ->  hl.on("hyprland.start", function() hl.exec_cmd(CMD) end)
--     exec       ->  hl.exec_cmd(CMD)  called at the top level of a module
--                    (the file is re-run on every reload, so it re-fires)
--
--  We register one "hyprland.start" handler and fire all autostarts from it.
-- ============================================================================

hl.on("hyprland.start", function()
    -- Bar, wallpaper
    hl.exec_cmd("~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c " .. qsConfig .. " &")
    hl.exec_cmd("~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    -- Some fix idk
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard history (text + images)
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- Wallpaper daemon + launcher server
    hl.exec_cmd("waypaper-engine daemon &")
    hl.exec_cmd("vicinae server &")
end)
