vim.cmd [[packadd packer.nvim]]

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- You add plugins here  
  use 'h-hg/fcitx.nvim'
  use {
	'windwp/nvim-autopairs',
    config = function() require("nvim-autopairs").setup {} end
  }
  use 'sainnhe/everforest'
  use 'sainnhe/gruvbox-material'
  use 'vim-airline/vim-airline'
end)

