call plug#begin('~/.vim/plugged') " 플러그인 시작

" === Language === "
Plug 'tpope/vim-surround'
Plug 'instant-markdown/vim-instant-markdown'

" === Completion === "
Plug 'ervandew/supertab'
Plug 'tpope/vim-endwise'
Plug 'raimondi/delimitmate'
Plug 'alvan/vim-closetag'

" === Code display === "
Plug 'vim-airline/vim-airline'
Plug 'nanotech/jellybeans.vim'
Plug 'morhetz/gruvbox'

" === Integrations === "
Plug 'scrooloose/nerdtree'
Plug 'christoomey/vim-tmux-navigator'

" === Interface === "
Plug 'vim-airline/vim-airline-themes'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'mhinz/vim-startify'

" === Commands === "
Plug 'preservim/tagbar'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf'
Plug 'terryma/vim-multiple-cursors' " multiple word selecting

" === Other === "
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vimwiki/vimwiki' " vim wiki plug
Plug 'scrooloose/nerdcommenter'

" nvim-treesitter 구문 파싱 하이라이팅
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Tagbar 코드 뷰어 창
" Plug 'majutsushi/tagbar'
" CScope 플러그인
" Plug 'ronakg/quickr-cscope.vim'
" VIM GAS(GNU ASsembler) Highlighting
" Plug 'Shirk/vim-gas'

call plug#end()

for include_file in uniq(sort(globpath(&rtp, 'vim-*/*.vim', 0, 1)))
    execute "source " . include_file
endfor

" Theme
syntax enable " syntax highlighting. enable vs on
colorscheme gruvbox
filetype plugin indent on " enable 
