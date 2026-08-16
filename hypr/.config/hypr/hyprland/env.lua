-- ============================================================================
--  hyprland/env.lua  (translated from hyprland/env.conf)
-- ----------------------------------------------------------------------------
--  Original: `env = NAME, VALUE`   ->   hl.env("NAME", "VALUE")
--
--  Important: the old conf auto-expanded $HOME and ~. Lua strings do NOT.
--  So where the conf used $HOME we read it ourselves with os.getenv("HOME")
--  and join with `..` (Lua's string concatenation operator).
-- ============================================================================

local home = os.getenv("HOME")

-- ###### Wayland ######
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ###### Applications ######
hl.env("XDG_DATA_DIRS",
    home .. "/.local/share/flatpak/exports/share:" ..
    "/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")

-- ###### Themes ######
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- gtk3 (not kde/kvantum) so native Qt widgets pull their palette from the
-- GTK theme, which Omarchy's theme switcher actually keeps in sync.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- ###### Virtual environment ######
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home .. "/.local/state/quickshell/.venv")

-- ###### Terminal application ######
hl.env("TERMINAL", "ghostty")
