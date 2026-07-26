-- ============================================================================
--  hyprland/rules.lua  (translated from hyprland/rules.conf)
-- ----------------------------------------------------------------------------
--  Old conf (Hyprland's newer `windowrule = match:... , effect on` form):
--     windowrule = match:class ^(foo)$, float on
--     windowrule = match:class ^(foo)$, size (monitor_w*.45) (monitor_h*.45)
--
--  In Lua each rule is hl.window_rule{ match = {...}, <effect> = <value> }.
--  Where the conf had several lines with the SAME matcher, we combine the
--  effects into ONE Lua call (cleaner, identical result).
--
--  Effect names follow the wiki's window-rule names in snake_case:
--     float on            -> float = true
--     no_blur on          -> no_blur = true
--     size A B            -> size = "A B"  (string; math exprs kept as-is)
--     move X Y            -> move = "X Y"
--  If Hyprland ever rejects a name, check
--  https://wiki.hypr.land/Configuring/Window-Rules/ for the exact token.
-- ============================================================================

-------------------- Window rules --------------------

-- Disable blur for xwayland context menus (empty class + empty title)
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })

-- Disable blur for every window
hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- ---- Floating dialogs (center + float) ----
hl.window_rule({ match = { title = "^(Open File)(.*)$" },       center = true, float = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" },   center = true, float = true })
hl.window_rule({
    match = { title = "^(Choose wallpaper)(.*)$" },
    center = true, float = true,
    size = "(monitor_w*.60) (monitor_h*.65)",
})
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" },     center = true, float = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" },         center = true, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" },         center = true, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" },     center = true, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" },   center = true, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" },   center = true, float = true })

hl.window_rule({ match = { class = "^(blueberry\\.py)$" },  float = true })
hl.window_rule({ match = { class = "^(guifetch)$" },        float = true }) -- FlafyDev/guifetch

hl.window_rule({
    match = { class = "^(pavucontrol)$" },
    float = true, center = true, size = "(monitor_w*.45) (monitor_h*.45)",
})
hl.window_rule({
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true, center = true, size = "(monitor_w*.45) (monitor_h*.45)",
})
hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true, center = true, size = "(monitor_w*.45) (monitor_h*.45)",
})

hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" },             float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = ".*Welcome" },         float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })
hl.window_rule({
    match = { class = "org.freedesktop.impl.portal.desktop.kde" },
    float = true, size = "(monitor_w*.60) (monitor_h*.65)",
})
hl.window_rule({
    match = { class = "^(Zotero)$" },
    float = true, size = "(monitor_w*.45) (monitor_h*.45)",
})

-- ---- Move / hide ----
-- kde-material-you-colors spawns a window on theme change; shove it offscreen.
hl.window_rule({
    match = { class = "^(plasma-changeicons)$" },
    float = true, no_initial_focus = true, move = "999999 999999",
})
-- stupid dolphin copy
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = "40 80" })

-- ---- Tiling ----
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- ---- Picture-in-Picture ----
hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    move = "(monitor_w*.73) (monitor_h*.72)",
    size = "(monitor_w*.25) (monitor_h*.25)",
    pin  = true,
})

-- ---- Tearing (games) ----
hl.window_rule({ match = { title = ".*\\.exe" },        immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" },   immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" },  immediate = true })

-- Fix Jetbrains IDEs focus/rerendering problem
hl.window_rule({
    match = { class = "^jetbrains-.*$", float = true, title = "^$|^\\s$|^win\\d+$" },
    no_initial_focus = true,
})

-- No shadow for tiled windows (windows that are not floating)
hl.window_rule({ match = { float = false }, no_shadow = true })

-------------------- Workspace rules --------------------
-- workspace = special:special, gapsout:30
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-------------------- Layer rules --------------------
-- Old: layerrule = match:namespace NS, effect [arg]
-- New: hl.layer_rule{ match = { namespace = NS }, <effect> = <value> }
-- Layer effect fields are well-defined:
--   no_anim, blur, blur_popups, ignore_alpha, xray, dim_around, animation,
--   order, above_lock, no_screen_share

hl.layer_rule({ match = { namespace = ".*" }, xray = true })
-- (no_anim for all was commented out in your conf)

hl.layer_rule({ match = { namespace = "walker" },      no_anim = true })
hl.layer_rule({ match = { namespace = "selection" },   no_anim = true })
hl.layer_rule({ match = { namespace = "overview" },    no_anim = true })
hl.layer_rule({ match = { namespace = "anyrun" },      no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" },         no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" },  no_anim = true })

hl.layer_rule({ match = { namespace = "noanim" },          no_anim = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" },        blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" },   blur = true, ignore_alpha = 0.69 })
-- NOTE: the original line `logout_dialog # wlogout, blur on` had its effect
-- inside a comment, so it did nothing. Restoring the intended blur here:
hl.layer_rule({ match = { namespace = "logout_dialog" },   blur = true })

-- Omarchy shell overlays: blur behind the summoned panels (frosted-glass look
-- like ii). Paired with lowered scrim/background alpha in the theme shell.toml.
hl.layer_rule({ match = { namespace = "omarchy-launcher" },     blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "omarchy-menu" },         blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "omarchy-clipboard" },    blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "omarchy-emojis" },       blur = true, ignore_alpha = 0.1 })
-- No scrim behind toasts (unlike the other omarchy-* overlays), so blurring
-- the live desktop here just looks soft/blurry instead of frosted-glass.
hl.layer_rule({ match = { namespace = "omarchy-notifications" }, blur = false })

-- ags-era layers
hl.layer_rule({ match = { namespace = "sideleft.*" },  animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "session[0-9]*" },   blur = true })
hl.layer_rule({ match = { namespace = "bar[0-9]*" },       blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "barcorner.*" },     blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "dock[0-9]*" },      blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "indicator.*" },     blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "overview[0-9]*" },  blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" },blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideright[0-9]*" }, blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" },  blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "osk[0-9]*" },       blur = true, ignore_alpha = 0.6 })

-- Quickshell: illogical-impulse
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79 })
hl.layer_rule({ match = { namespace = "quickshell:bar" },               animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" },      no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" },        animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:dock" },              animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" },     animation = "popin 120%" })
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" },  no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell:overlay" },           no_anim = true, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:overview" },          no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:osk" },               animation = "slide bottom", order = -1 })
hl.layer_rule({ match = { namespace = "quickshell:polkit" },            no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:popup" },             xray = false, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" },     ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" },       animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" },    no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:screenshot" },        no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true, no_anim = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" },      animation = "slide right" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" },       animation = "slide left" })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" },       animation = "slide" })

-- Quickshell: waffles
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" },    animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" },  no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" },     no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" },           no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" },            no_anim = true, ignore_alpha = 0 })

-- Launchers need to be FAST
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, no_anim = true })
