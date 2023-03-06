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

