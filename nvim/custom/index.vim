source ~/.vim/custom/abbr.vim
source ~/.vim/custom/autocmd.vim

set t_Co=256
set hlsearch
set number
set laststatus=2 " turn on bottom bar

set smartindent
set tabstop=4
set expandtab
set shiftwidth=4

set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux
set wildignore+=*\\tmp\\*,*.swp,*.zip,*.exe  " Windows

set shell=/bin/zsh

nnoremap <S-Up> <Up>ddp<Up>
nnoremap <S-Down> ddp

filetype plugin on

syntax enable
filetype indent on
highlight Comment term=bold cterm=bold ctermfg=4

"autocmd BufWritePre * :normal gg=G``zz " auto indent before save
