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
if is_wsl() then
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
        --- to avoid conflicts between pasting and vertical window splitting
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

-- comment in/out
require('Comment').setup()

-- quickscope
vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}
vim.api.nvim_set_hl(0, 'QuickScopePrimary', {fg='#A8334C', bold=true, underline=true})
vim.api.nvim_set_hl(0, 'QuickScopeSecondary', {fg='#A8334C', bold=false, underline=true})
