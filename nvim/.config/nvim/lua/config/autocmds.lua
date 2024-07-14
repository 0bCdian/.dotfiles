-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("custom_highlights_gruvboxmaterial", {}),
  pattern = "gruvbox-material",
  command = "hi NeoTreeNormal                     guibg=#282828 |"
    .. "hi NeoTreeEndOfBuffer                guibg=#282828 |"
    .. "hi NoiceCmdlinePopupBorderCmdline     guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePromptBorder              guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePromptNormal              guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePromptTitle               guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePromptPrefix              guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePromptCounter             guifg=#ea6962 guibg=#282828 |"
    .. "hi TelescopePreviewTitle              guifg=#89b482 guibg=#282828 |"
    .. "hi TelescopePreviewBorder             guifg=#89b482 guibg=#282828 |"
    .. "hi TelescopeResultsTitle              guifg=#89b482 guibg=#282828 |"
    .. "hi TelescopeResultsBorder             guifg=#89b482 guibg=#282828 |"
    .. "hi TelescopeMatching                  guifg=#d8a657 guibg=#282828 |"
    .. "hi TelescopeSelection                 guifg=#ffffff guibg=#32302f |"
    .. "hi FloatBorder                        guifg=#ea6962 guibg=#282828 |"
    .. "hi BqfPreviewBorder                   guifg=#ea6962 guibg=#282828 |"
    .. "hi NormalFloat                        guibg=#282828 |"
    .. "hi IndentBlanklineContextChar         guifg=#d3869b |"
    .. "hi markid1                            guifg=#ff8f88 |"
    .. "hi markid2                            guifg=#ffb074 |"
    .. "hi markid3                            guifg=#cfdc8b |"
    .. "hi markid4                            guifg=#a3d4c9 |"
    .. "hi markid5                            guifg=#f9acc1 |"
    .. "hi markid6                            guifg=#afdaa8 |"
    .. "hi markid7                            guifg=#fecc7d |"
    .. "hi markid8                            guifg=#eed8b2 |"
    .. "hi markid9                            guifg=#ffedc7 |"
    .. "hi markid10                           guifg=#cebfaa |"
    .. "hi StatusColumnBorder                 guifg=#282828 |"
    .. "hi StatusColumnBuffer                 guibg=#282828 |"
    .. "hi CursorLineNr                       guifg=#d8a657 |"
    .. "hi CodewindowBorder                   guifg=#ea6962 |",
})

local lsp_conficts, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspAttach_conflicts" })
if not lsp_conficts then
  vim.api.nvim_create_augroup("LspAttach_conflicts", {})
end
vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttach_conflicts",
  desc = "prevent tsserver and volar competing",
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end
    local active_clients = vim.lsp.get_clients()
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- prevent tsserver and volar competing
    -- if client.name == "volar" or require("lspconfig").util.root_pattern("nuxt.config.ts")(vim.fn.getcwd()) then
    -- OR
    if client == nil then
      return
    end
    if client.name == "volar" then
      for _, client_ in pairs(active_clients) do
        -- stop tsserver if volar is already active
        if client_.name == "tsserver" then
          client_.stop()
        end
      end
    elseif client.name == "tsserver" then
      for _, client_ in pairs(active_clients) do
        -- prevent tsserver from starting if volar is already active
        if client_.name == "volar" then
          client.stop()
        end
      end
    end
  end,
})
