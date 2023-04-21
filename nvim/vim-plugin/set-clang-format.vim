let g:clang_format#style_options = {
\ 'BasedOnStyle': 'Google',
\ 'IndentWidth': 2,
\ 'UseTab': 'Never',
\ 'TabWidth': 2,
\ }
autocmd FileType c,cpp nnoremap <buffer> <leader>cf :ClangFormat<CR>
