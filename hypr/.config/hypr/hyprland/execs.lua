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
    -- ROLLBACK: to return to end4 ii, uncomment the next line and comment the omarchy one.
    -- hl.exec_cmd("qs -c " .. qsConfig .. " &")
    -- Omarchy shell (Quickshell). Requires the uwsm session so OMARCHY_PATH/PATH
    -- are set from ~/.config/uwsm/env.d. Launched as a uwsm scope like omarchy does.
    hl.exec_cmd("uwsm app -- quickshell -n -p " .. os.getenv("HOME") .. "/.local/share/omarchy-shell/shell")
    hl.exec_cmd("~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    -- hypridle drives lock/screensaver timeouts (it respects Firefox/Zen's
    -- D-Bus org.freedesktop.ScreenSaver.Inhibit, which omarchy.idle's
    -- Wayland-only IdleMonitor never sees). omarchy.idle's own timeouts are
    -- inflated in shell.json so they're structurally inert; the bar's
    -- Stay Awake toggle now pauses hypridle via a systemd-inhibit hold
    -- (see omarchy-toggle-idle) instead of touching omarchy.idle.
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sleep 2 && omarchy-toggle-idle reconcile")
    hl.exec_cmd("dbus-update-activation-environment --all")
    -- Some fix idk
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard history: omarchy.clipboard runs its own capture inside the shell.
    -- ROLLBACK (ii): uncomment the two lines below.
    -- hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")
    -- hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- Wallpaper daemon + launcher server
    hl.exec_cmd("waypaper-engine daemon &")
    -- vicinae retired; omarchy.launcher (Super+Space) replaces it.
    -- ROLLBACK: uncomment to restore the vicinae server.
    -- hl.exec_cmd("vicinae server &")
end)
