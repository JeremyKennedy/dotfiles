# Neovim configuration - Sensible defaults with minimal plugins
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    
    # Sensible settings that improve on vim defaults
    extraConfig = ''
      " Line numbers - shows current line number and relative numbers for easy jumping
      set number relativenumber
      
      " Indentation - use spaces, 2 space width (common in modern code)
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set autoindent
      set smartindent
      
      " Search - case insensitive unless you use capitals
      set ignorecase
      set smartcase
      set incsearch
      set hlsearch
      
      " Quality of life improvements
      set mouse=a                " Enable mouse support
      set clipboard=unnamedplus  " Use system clipboard
      set scrolloff=8            " Keep 8 lines visible when scrolling
      set cursorline             " Highlight current line
      set signcolumn=yes         " Always show sign column (for git markers)
      set undofile               " Persistent undo history
      
      " Set leader key to space (common in modern configs)
      let mapleader = " "
      
      " Clear search highlighting with leader+space
      nnoremap <leader><space> :nohlsearch<CR>
    '';
    
    # Minimal but useful plugins
    plugins = with pkgs.vimPlugins; [
      # Tim Pope's essentials - these are basically vim standards
      vim-sensible    # Sensible defaults everyone agrees on
      vim-surround    # cs"' to change surrounding quotes, ysiw" to surround word
      vim-commentary  # gcc to comment line, gc to comment selection
      
      # Git integration
      vim-fugitive    # :Git commands
      vim-gitgutter   # Shows git changes in the gutter
      
      # Simple color theme
      gruvbox-material
      
      # Nix syntax highlighting (useful for your dotfiles)
      vim-nix
    ];
    
    # Minimal plugin configuration
    extraLuaConfig = ''
      -- Set colorscheme
      vim.cmd('colorscheme gruvbox-material')
      
      -- GitGutter - simple symbols for git changes
      vim.g.gitgutter_sign_added = '+'
      vim.g.gitgutter_sign_modified = '~'
      vim.g.gitgutter_sign_removed = '-'
    '';
  };
}