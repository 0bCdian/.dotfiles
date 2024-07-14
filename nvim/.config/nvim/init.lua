-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
if vim.g.neovide then
  vim.o.guifont = "JetbrainsMono Nerd Font:h16"
  vim.g.neovide_padding_top = 15
  vim.g.neovide_padding_bottom = 15
  vim.g.neovide_padding_right = 15
  vim.g.neovide_padding_left = 15
end

vim.g.gruvbox_material_background = "medium" -- hard, soft, medium
vim.g.gruvbox_material_palette = "material" -- original, mix, material
vim.g.gruvbox_material_enable_italic = 1
vim.g.gruvbox_material_sign_column_background = "none"
vim.lsp.inlay_hint.enable(false)
