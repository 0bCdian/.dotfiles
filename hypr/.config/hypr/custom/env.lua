-- custom/env.lua  (translated from custom/env.conf)
-- Put your extra environment variables here, e.g.:
--   hl.env("MOZ_ENABLE_WAYLAND", "1")
-- Docs: https://wiki.hypr.land/Configuring/Environment-variables/

-- Tensaku screenshot editor (was envs.conf, set by `tensaku --wire-omarchy`).
hl.env("OMARCHY_SCREENSHOT_EDITOR", "/usr/bin/tensaku-edit")
