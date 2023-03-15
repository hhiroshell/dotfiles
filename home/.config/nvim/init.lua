-- ===============
-- setting options
-- ===============

local o = vim.o

--- base of gui colors
o.termguicolors = true
o.background = "light"

--- appearance
o.number = true

--- case insensitive search
o.ignorecase = true

--- use 4 spaces instead of a Tab
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4

-- =======
-- autocmd
-- =======

--- augroup
vim.api.nvim_create_augroup('my-augroup', {})

--- remove all trailing whitespace automatically
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  group = 'my-augroup',
  pattern = {"*"},
  command = ":%s/\\s\\+$//e",
})

--- set shell environment for calling system commands
o.shell = '/usr/bin/zsh --login'

local function is_wsl()
  local uname = io.popen("uname -r"):read("*l")
  return uname:match("microsoft") ~= nil or uname:match("WSL") ~= nil
end

--- disable windows IME when exiting from insert mode.
--- zenhan.exe must be installed on PATH.
if is_wsl() then
  vim.api.nvim_create_autocmd({"InsertLeave", "CmdlineLeave"}, {
    group = 'my-augroup',
    pattern = {"*"},
    command = ":call system('zenhan.exe 0')",
  })
end

--- clipboard integration
f is_wsl() then
  vim.api.nvim_create_autocmd({"TextYankPost"}, {
    group = 'my-augroup',
    pattern = {"*"},
    command = ":call system('clip.exe', @\")",
  })
else
  o.clipboard = 'unnamedplus'
end

-- ==========
-- key remaps
-- ==========

local map = vim.api.nvim_set_keymap

--- map the leader key
map('n', '<Space>', '', {})
vim.g.mapleader = ' '

--- to avoid confilicts between pasting and vertical window splitting
map('n', '<C-w>d', ':vsplit<CR>', { noremap = false })
map('n', '<C-w><C-d>', ':vsplit<CR>', { noremap = false })

-- ===============
-- plugin settings
-- ===============

require('plugins')

-- zenbones (color theme)
require('zenbones')

vim.api.nvim_create_autocmd({"ColorScheme"}, {
  group = 'my-augroup',
  pattern = {"zenbones"},
  command = "lua require \"customize_zenbones\"",
})

vim.cmd.colorscheme "zenbones"

require('lualine').setup {
  options = { theme = 'zenbones' },
  sections = {
    lualine_c = {
      { 'filename', path = 1 },
    },
  }
}

-- telescope (fuzzy finder)
require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ['<esc>'] = require('telescope.actions').close,
        --- to avoid confilicts between pasting and vertical window splitting
        ['<C-d>'] = require('telescope.actions').select_vertical,
        ['<C-s>'] = require('telescope.actions').select_horizontal,
        ['<PageUp>'] = require('telescope.actions').preview_scrolling_up,
        ['<PageDown>'] = require('telescope.actions').preview_scrolling_down,
      },
    },
    layout_config = {
      horizontal = { preview_width = 0.6 },
      vertical = { preview_height = 0.6 },
    },
    layout_strategy = "flex",
  },
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

require('nvim-web-devicons').setup {
  color_icons = false,
}

-- comment
require('Comment').setup()

-- lsp
require("mason").setup()

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function()
    vim.lsp.buf.code_action({
      context = { only = { 'source.organizeImports' } },
      apply = true,
    })
    vim.lsp.buf.format({ async = false })
  end
})

--- keymaps - vim.diagnostics
local opts = { noremap = true, silent = true }
vim.keymap.set('n', 'ge', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- keypams - vim.lsp.buf.*
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', 'gn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)

  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
end

require('lspconfig').gopls.setup{
  on_attach = on_attach,
}

-- hrsh7/th/nvim-cmp (code completion)
local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "emoji" },
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ['<C-l>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm { select = true },
  }),
  experimental = {
    ghost_text = true,
  },
})
