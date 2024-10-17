return {
  "supermaven-inc/supermaven-nvim",
  commit = "40bde487fe31723cdd180843b182f70c6a991226",
  config = function()
    require("supermaven-nvim").setup({
      disable_keymaps = true,
    })

    local completion_preview = require("supermaven-nvim.completion_preview")
    vim.keymap.set("i", "<c-y>", completion_preview.on_accept_suggestion, { noremap = true, silent = true })
    vim.keymap.set("i", "<c-j>", completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
    vim.keymap.set("i", "<c-]>", completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
  end,
}
