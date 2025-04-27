return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = {
      enabled = true,
      only_scope = false,
      animate = {
        enabled = false,
      },
      indent = {
        hl = "SnacksIndent",
        -- hl = {
        --   "SnacksIndent1",
        --   "SnacksIndent2",
        --   "SnacksIndent3",
        --   "SnacksIndent4",
        --   "SnacksIndent5",
        --   "SnacksIndent6",
        --   "SnacksIndent7",
        --   "SnacksIndent8",
        -- },
      },
      chunk = {
        enabled = true,
      },
      scope = { enabled = true },
    },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          layout = {
            layout = {
              position = "left",
            },
          },
        },
      },
      layouts = {
        sidebar = { position = "right" },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = {
      enabled = true,
      animate = {
        duration = {
          steps = 100,
          total = 500,
        },
        easing = "linear",
      },
    },
    statuscolumn = {
      enabled = true,
    },
    words = { enabled = true },
  },
}
