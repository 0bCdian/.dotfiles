-- ============================================================================
--  Hyprland Lua config — ENTRY POINT
-- ----------------------------------------------------------------------------
--  This is the Lua translation of the .conf files in the repo root.
--  It lives in `lua/` so Hyprland does NOT load it automatically.
--  See README.md (repo root) for what Lua is and how to activate this.
--
--  Hyprland loads ~/.config/hypr/hyprland.lua. When you activate this config
--  (README explains how), this file becomes that entry point and pulls in the
--  rest with `require(...)`. In Lua, `require("a.b")` loads the file `a/b.lua`
--  relative to the config directory, runs it once, and caches the result.
-- ============================================================================

-- NOTE on the old `submap = global` catch-all:
-- The original hyprland.conf opened a "global" submap so illogical-impulse's
-- catch-all search binds could work. You have all of those binds commented
-- out, so this Lua version defines every bind at the top level (the default
-- submap) instead — simpler and equivalent for your active binds. If you ever
-- re-enable ii's Super-search binds, recreate the submap with
-- `hl.define_submap("global", function() ... end)`.

-- Defaults (mirrors the `hyprland/` folder)
require("hyprland.env")
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.keybinds")

-- Custom (mirrors the `custom/` folder — put your own tweaks here)
require("custom.env")
require("custom.execs")
require("custom.general")
require("custom.rules")
require("custom.keybinds")

-- nwg-displays support (generated files)
require("workspaces")
require("monitors")
