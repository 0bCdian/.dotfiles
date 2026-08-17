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

-- ---- Idle ----
-- Anything fullscreen holds the idle inhibitor: a fullscreen window is
-- video, a game, or a presentation, and none of those want the screensaver.
-- hypridle honours the compositor's inhibitor, so this reaches it without
-- hypridle needing a rule of its own.
--
-- Deliberately no title-based YouTube rule. Titles are a moving target
-- ("<video> - YouTube — Zen Browser", and nothing at all once the tab is
-- backgrounded), and `focus` would stop inhibiting the moment you alt-tab
-- away from a video that is still playing. The MPRIS watcher
-- (custom/scripts/mpris-idle-inhibit.sh) covers playback properly, whatever
-- the window is called and whether or not it is focused.
hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

-------------------- Workspace rules --------------------
-- workspace = special:special, gapsout:30
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-------------------- Layer rules --------------------
-- Old: layerrule = match:namespace NS, effect [arg]
-- New: hl.layer_rule{ match = { namespace = NS }, <effect> = <value> }
-- Layer effect fields are well-defined:
--   no_anim, animation, dim_around, order, above_lock, no_screen_share
--   (blur/ignore_alpha/xray omitted: blur is disabled globally)

-- (no_anim for all was commented out in your conf)

hl.layer_rule({ match = { namespace = "walker" },      no_anim = true })
hl.layer_rule({ match = { namespace = "selection" },   no_anim = true })
hl.layer_rule({ match = { namespace = "overview" },    no_anim = true })
hl.layer_rule({ match = { namespace = "anyrun" },      no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" },         no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" },  no_anim = true })

hl.layer_rule({ match = { namespace = "noanim" },          no_anim = true })

-- Omarchy shell overlays. Only animation behaviour is set here now; blur is
-- off globally, so nothing needs to opt out of it.

-- Shared popup base (KeyboardPanel.qml) for every bar-widget dropdown: the
-- network/bluetooth/audio/power panels, DNS pills, tray menu, etc. all map
-- to this one namespace. KeyboardPanel already fades its own opacity in QML
-- (see the `Behavior on opacity` on its `card`), so no_anim avoids
-- Hyprland's layer animation fighting with that.
hl.layer_rule({ match = { namespace = "omarchy-keyboard-panel" }, no_anim = true })

-- Invisible full-screen click-catcher the keyboard panel maps on every *other*
-- output so a click there dismisses the panel.
hl.layer_rule({ match = { namespace = "omarchy-keyboard-panel-dismiss" }, no_anim = true })

-- Bar and background self-animate in QML already; no_anim keeps Hyprland
-- from adding a second, conflicting transition on top.
hl.layer_rule({ match = { namespace = "omarchy-bar" },        no_anim = true })

-- Transparent ghosts quattro maps while dragging/reordering bar widgets. They
-- follow the pointer, so a Hyprland layer animation lags them behind the cursor.
hl.layer_rule({ match = { namespace = "omarchy-bar-drag-ghost" }, no_anim = true })
hl.layer_rule({ match = { namespace = "omarchy-bar-move-ghost" }, no_anim = true })
hl.layer_rule({ match = { namespace = "omarchy-background" }, no_anim = true })

-- PolkitAgent also self-animates; matches ii's own "quickshell:polkit" choice.
hl.layer_rule({ match = { namespace = "omarchy-polkit" }, no_anim = true })

-- Pre-lock wallpaper preview: closest analog to ii's "quickshell:session".
hl.layer_rule({ match = { namespace = "omarchy-lock-preview" }, no_anim = true })

-- OSD is a small toast with no scrim behind it (see its empty click-through
-- `mask` in Osd.qml); it self-animates, so no_anim keeps Hyprland out of it.
hl.layer_rule({ match = { namespace = "omarchy-osd" }, no_anim = true })

-- ags-era layers
hl.layer_rule({ match = { namespace = "sideleft.*" },  animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })

-- NOTE: this used to carry two blocks of `quickshell:*` / `quickshell:w*`
-- rules ported from end-4/dots-hyprland (ii) and its "waffle" variant.
-- omarchy-shell's layer-shell surfaces are all namespaced "omarchy-*" (see
-- the block above) — none of those old rules ever matched anything here, so
-- they were dead weight. Removed rather than left stale.

-- Launchers need to be FAST
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, no_anim = true })
