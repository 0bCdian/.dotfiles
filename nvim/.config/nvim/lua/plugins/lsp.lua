local util = require("lspconfig.util")
return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = false,
    },
    servers = {
      volar = {
        filetypes = {
          "typescript",
          "javascript",
          "vue",
        },
        root_dir = util.root_pattern("src/App.vue"),
      },
    },
  },
}
