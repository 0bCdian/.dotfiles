-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local cmd = vim.cmd
local opt = vim.opt
vim.g.deprecation_warnings = false

cmd("let g:netrw_liststyle = 3")
cmd("filetype plugin indent on")
cmd([[highlight WinSeparator guibg = None]])

-- Appearance
opt.termguicolors = true
opt.pumheight = 10
opt.cmdheight = 0
opt.conceallevel = 0
opt.laststatus = 3
opt.showtabline = 0
opt.columns = 80
opt.textwidth = 80
-- Files and others
opt.smartindent = true
opt.autoindent = true
opt.expandtab = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Keep cursor unchanged after quiting
vim.api.nvim_create_autocmd("ExitPre", {
  group = vim.api.nvim_create_augroup("Exit", { clear = true }),
  command = "set guicursor=a:ver90",
  desc = "Set cursor back to beam when leaving Neovim.",
})

-- Options based on filetypes
-- markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt.wrap = true
    vim.opt.linebreak = true
  end,
})

-- disalbe commenting next line
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})
