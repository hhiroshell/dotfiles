local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use {
    'wbthomason/packer.nvim',
  }

  use {
    'mcchrish/zenbones.nvim',
    requires = {
      { 'rktjmp/lush.nvim' },
    },
  }

  use {
    'nvim-tree/nvim-web-devicons',
  }

  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      { 'nvim-tree/nvim-web-devicons', opt = true },
    }
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-tree/nvim-web-devicons', opt = true },
    },
  }

  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }

  use {
    'unblevable/quick-scope',
  }

  -- Automatically set up this configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)
