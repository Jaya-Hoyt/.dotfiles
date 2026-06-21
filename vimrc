" Minimal vimrc sharing basic defaults from Neovim configuration

" Make line numbers default
set number
set relativenumber

" Enable mouse mode
set mouse=a

" Indentation settings (use 2 spaces for tabs)
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2

" Case-insensitive searching unless search contains capital letters
set ignorecase
set smartcase

" Highlight cursor line
set cursorline

" Keep 10 lines of context above/below cursor
set scrolloff=10

" Split behaviors
set splitright
set splitbelow

" Save undo history
set undofile

" Syntax highlighting & file type detection
syntax on
filetype plugin indent on
