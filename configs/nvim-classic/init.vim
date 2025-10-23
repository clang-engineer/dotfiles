call plug#begin('~/.vim/plugged') " 플러그인 시작

" === Language === "
Plug 'tpope/vim-surround'  " surrouding parentheses, brackets, quotes, XML tags, and more. ys, ds, cs
Plug 'instant-markdown/vim-instant-markdown' " preview markdown instantly
Plug 'sheerun/vim-polyglot'

" === Completion === "
Plug 'ervandew/supertab' " tab으로 삽입 마치는 기능
Plug 'tpope/vim-endwise' " if while do 등 문법적 레이아웃 마치게
Plug 'raimondi/delimitmate' " quotes, parenthesis, brackets의 짝을 자동 삽입
Plug 'alvan/vim-closetag' " xml html 자동 종료 태그

" === Code display === "
Plug 'vim-airline/vim-airline' " 하단에 문서 git + 문서 상태 표시

" === Integrations === "
Plug 'scrooloose/nerdtree' " tree 탐색기
Plug 'christoomey/vim-tmux-navigator' " tmux <-> vim 창 이동 자연스럽게
Plug 'rhysd/vim-clang-format' " vim을 위한 clang formatter


" === Interface === "
Plug 'vim-airline/vim-airline-themes' " airline theme template
Plug 'ctrlpvim/ctrlp.vim' " 파일 경로, 이름 기반의 탐색기
Plug 'mhinz/vim-startify' " 시작 화면
Plug 'xuyuanp/nerdtree-git-plugin' " nerdtree에 git 상태 표시


" === Commands === "
Plug 'preservim/tagbar' " tagbar 사용시
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " 키워드 기반의 텍스트 검색
Plug 'terryma/vim-multiple-cursors' " multiple word selecting

" === Other === "
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vimwiki/vimwiki' " vim wiki plug
Plug 'scrooloose/nerdcommenter'
Plug 'rafi/awesome-vim-colorschemes' " 각종 색상 팔레트 
Plug 'xolox/vim-misc' " 랜덤 컬러 선택기 의존 모듈
Plug 'xolox/vim-colorscheme-switcher' " 랜덤 컬러 선택기

Plug 'rking/ag.vim'

" nvim-treesitter 구문 파싱 하이라이팅
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Tagbar 코드 뷰어 창
" Plug 'majutsushi/tagbar'
" CScope 플러그인
" Plug 'ronakg/quickr-cscope.vim'
" VIM GAS(GNU ASsembler) Highlighting
" Plug 'Shirk/vim-gas'
"
Plug 'dhruvasagar/vim-table-mode'


call plug#end()

for include_file in uniq(sort(globpath(&rtp, 'vim-*/*.vim', 0, 1)))
    execute "source " . include_file
endfor

" Theme
syntax enable " syntax highlighting. enable vs on
" colorscheme industry
filetype plugin indent on " enable 
