" set indent tab size to 2, use spaces instead of tabs
let g:clang_format#style_options = {
\ 'BasedOnStyle': 'Google',
\ 'IndentWidth': 2,
\ 'UseTab': 'Never',
\ 'TabWidth': 2,
\ }


" detect code style from .clang-format file
let g:clang_format#detect_style_file = 1

" auto format on save
let g:clang_format#auto_format = 1


autocmd FileType c,cpp nnoremap <buffer> <leader>cf :ClangFormat<CR>
autocmd FileType c,cpp nnoremap <buffer> gg=G :ClangFormat<CR>

