set shell=/bin/bash
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

" === Plugin from tasty development ===
Plugin 'gmarik/Vundle.vim'

" === Language ===
Plugin 'tpope/vim-surround' " surround code
Plugin 'mattn/emmet-vim' " emmet for vim
Plugin 'w0rp/ale' " syntax checking
Plugin 'pangloss/vim-javascript'
Plugin 'leafgarland/typescript-vim'
Plugin 'tpope/vim-markdown'
Plugin 'elzr/vim-json'
Plugin 'othree/html5.vim'
Plugin 'instant-markdown/vim-instant-markdown'
Plugin 'burnettk/vim-angular'
Plugin 'peitalin/vim-jsx-typescript'
Plugin 'udalov/kotlin-vim'

" === Completion ===
Plugin 'tpope/vim-fugitive' " vim with git command(e.g., Gdiff)
Plugin 'scrooloose/syntastic' " syntax checking
Plugin 'honza/vim-snippets' " vim-snip layout
Plugin 'ervandew/supertab' " insert mode completion with tab
Plugin 'tpope/vim-endwise' " add end of endfunction/endif/more
Plugin 'raimondi/delimitmate' " automatic close quote, bracket ... ;
Plugin 'taglist.vim' " source code browser (support c/c++, java, ...)
Plugin 'jiangmiao/auto-pairs' " Insert or delete brackets, parens, quotes in pair.
Plugin 'alvan/vim-closetag' " auto insert (x)html closetag
Plugin 'ludovicchabant/vim-gutentags' " tag custom

" === Code display ===
Plugin 'vim-airline/vim-airline' " vim status bar
Plugin 'nathanaelkane/vim-indent-guides' " show indent guide line
Plugin 'sjl/gundo.vim'
Plugin 'kien/rainbow_parentheses.vim'
Plugin 'nanotech/jellybeans.vim'
Plugin 'ap/vim-css-color'
Plugin 'junegunn/seoul256.vim'
Plugin 'valloric/matchtagalways' " show html/xml tag matching

" === Integrations ===
Plugin 'scrooloose/nerdtree'
Plugin 'airblade/vim-gitgutter' " vim with git status(added, modified, and removed lines)
Plugin 'mileszs/ack.vim' " file search
Plugin 'christoomey/vim-tmux-navigator' " seamless navigarion between tmux panes and vim splits
Plugin 'junegunn/gv.vim' " A git commit browser in Vim
Plugin 'octref/rootignore' " set wildignore from git repo root

" === Interface ===
Plugin 'vim-airline/vim-airline-themes' "a collection of themes for vim-airline
Plugin 'ctrlpvim/ctrlp.vim' " Fuzzy file, buffer, mru, tag, etc finder
Plugin 'godlygeek/tabular' " text align tool
" Plugin 'sirver/ultisnips' " code skeleton
Plugin 'xuyuanp/nerdtree-git-plugin' " git status on nerdtree
Plugin 'mhinz/vim-startify' " cached page dashboard
Plugin 'sickill/vim-monokai'

" Commands
Plugin 'majutsushi/tagbar'
Plugin 'valloric/youcompleteme',
Plugin 'tpope/vim-repeat'
Plugin 'junegunn/fzf' " unit file finder
Plugin 'easymotion/vim-easymotion'
Plugin 'terryma/vim-multiple-cursors' " multiple word selecting
Plugin 'flazz/vim-colorschemes'

" Other
Plugin 'scrooloose/nerdcommenter'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'tpope/vim-sensible'
Plugin 'vimwiki/vimwiki'

call vundle#end()

" vim awesome config
for include_file in uniq(sort(globpath(&rtp, 'plugin/*.vim', 0, 1)))
    execute "source " . include_file
endfor

colorscheme seoul256
