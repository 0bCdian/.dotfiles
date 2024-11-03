-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
if vim.g.neovide then
  vim.o.guifont = "JetbrainsMono Nerd Font:h16"
  vim.g.neovide_padding_top = 15
  vim.g.neovide_padding_bottom = 15
  vim.g.neovide_padding_right = 15
  vim.g.neovide_padding_left = 15
  -- vim.g.neovide_theme = "auto"
  vim.g.gruvbox_material_transparent_background = 0
  vim.cmd([[colorscheme gruvbox-material]])
end
