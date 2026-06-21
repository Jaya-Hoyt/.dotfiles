" Minimal vimrc sharing basic defaults from Neovim configuration

" Set leader keys
let mapleader = " "
let maplocalleader = " "

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

" ==========================================
" MAPPINGS (No plugins required)
" ==========================================

" Clear search highlights on pressing <Esc> in Normal mode
nnoremap <Esc> :nohlsearch<CR>

" Window navigation shortcuts (CTRL + hjkl)
nnoremap <C-h> <C-w><C-h>
nnoremap <C-l> <C-w><C-l>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>

" Quick saving and quitting
nnoremap <silent> <leader>j :w<CR>
nnoremap <silent> <leader>k :q<CR>

" Delete without copy to clipboard (black-hole register)
nnoremap d "_d
vnoremap d "_d
nnoremap dd "_dd
nnoremap D "_D
nnoremap (d V%"_d

" Change without copy to clipboard (black-hole register)
nnoremap c "_c
vnoremap c "_c
nnoremap cc "_cc
nnoremap C "_C
nnoremap (c V%"_c

" Cut motion mappings (using 'x' to copy/cut to default register)
nnoremap x d
vnoremap x d
nnoremap xx dd
nnoremap X D
nnoremap xp "zdl"zp
nnoremap (x V%d

" Yank linewise over %
nnoremap (y V%y

" Paste in visual mode without overwriting default register with deleted text
vnoremap p "_dP

" Replace character to end of line
nnoremap R r$

" Move up/down visual lines (wrapped text) by default, logical lines with count
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
vnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
vnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
