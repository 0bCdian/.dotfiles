-- ============================================================================
--  workspaces.lua  (translated from workspaces.conf)
-- ----------------------------------------------------------------------------
--  Original: `workspace = N, monitor:NAME, default:true`
--  In Lua these are workspace RULES -> hl.workspace_rule{}.
--  Workspaces 1-6 are bound to DP-1, 7-10 to HDMI-A-1.
--  This is also overwritten by nwg-displays if you use it.
-- ============================================================================

-- A small Lua loop instead of writing 10 nearly identical lines.
-- `ipairs` walks an array in order, giving us index + value.
local layout = {
    { ws = 1,  monitor = "DP-1" },
    { ws = 2,  monitor = "DP-1" },
    { ws = 3,  monitor = "DP-1" },
    { ws = 4,  monitor = "DP-1" },
    { ws = 5,  monitor = "DP-1" },
    { ws = 6,  monitor = "DP-1" },
    { ws = 7,  monitor = "HDMI-A-1" },
    { ws = 8,  monitor = "HDMI-A-1" },
    { ws = 9,  monitor = "HDMI-A-1" },
    { ws = 10, monitor = "HDMI-A-1" },
}

for _, w in ipairs(layout) do
    hl.workspace_rule({
        workspace = tostring(w.ws), -- workspace selector is a string
        monitor   = w.monitor,
        default   = true,
    })
end
