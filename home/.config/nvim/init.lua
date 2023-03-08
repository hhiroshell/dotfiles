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

--- disable windows IME when exiting from insert mode.
--- zenhan.exe must be installed on PATH.
if os.execute('uname -a | grep microsoft') ~= '' then
  vim.api.nvim_create_autocmd({"InsertLeave", "CmdlineLeave"}, {
    group = 'my-augroup',
    pattern = {"*"},
    command = ":call system('zenhan.exe 0')",
  })
end

--- send yanked text to the windows clipboard.
if os.execute('uname -a | grep microsoft') ~= '' then
  vim.api.nvim_create_autocmd({"TextYankPost"}, {
    group = 'my-augroup',
    pattern = {"*"},
    command = ":call system('clip.exe', @\")",
  })
end

-- ==========
-- key remaps
-- ==========

local map = vim.api.nvim_set_keymap

--- map the leader key
map('n', '<Space>', '', {})
vim.g.mapleader = ' '

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
      },
    },
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
require('lspconfig').gopls.setup{}

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function()
    vim.lsp.buf.code_action({
      context = { only = { 'source.organizeImports' } },
      apply = true,
    })
  end
})

local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

-- hrsh7/th/nvim-cmp (code completion)
local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
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
