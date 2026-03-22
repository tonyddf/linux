" General configuration
set nocompatible                 " Disable old vim compatibility mode
set number                       " Show absolute line number
" set relativenumber             " Show relative line numbers around the cursor
set ruler                        " Show cursor and status feedback
set showcmd                      " Display partial commands when typing
set expandtab                    " Convert tabs into spaces when pressing <tab>
set autoindent                   " New lines inherit indentation from previous line
set smartindent                  " Enable smarter indentation for programming languages
set incsearch                    " Highlight matches while typing search
set hlsearch                     " Highlight matches after search
set ignorecase                   " Make searches case-insensitive
set smartcase                    " Override ignorecase if using uppercase in search
syntax on                        " Enable syntax highlighting
" set list                       " Show all characters
colorscheme industry             " Use the industry color scheme
filetype plugin indent on        " Enable filetype detection, plugins, and indentation rules

" Configuration for different file types
augroup my_filetype_settings
  autocmd!
  " Configuration for yaml files
  autocmd FileType yaml setlocal tabstop=2 softtabstop=2 shiftwidth=2 foldmethod=indent foldlevel=99
  " Configuration for python files
  autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4 textwidth=88 foldmethod=indent foldlevel=99
  " Configuration for bash files
  autocmd FileType sh,bash,zsh setlocal tabstop=2 softtabstop=2 shiftwidth=2 foldmethod=indent foldlevel=99
  " Configuration for c files
  autocmd FileType c setlocal tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab cindent
augroup END
