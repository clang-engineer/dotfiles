 let g:vimwiki_list = [{'path': '~/clang-engineer.github.io/_posts/', 'ext': '.md', 'diary_rel_path': '.'}]
 let g:vimwiki_conceallevel = 0

augroup vimwikiauto
    autocmd BufWritePre *posts/*.md call LastModified()
    autocmd BufRead,BufNewFile *posts/*.md call NewTemplate()
augroup END

function! NewTemplate()
    if line("$") > 1
        return
    endif

    let l:template = []
    call add(l:template, '---')
    call add(l:template, 'title       : ')
    call add(l:template, 'description : ')
    call add(l:template, 'date        : ' . strftime('%Y-%m-%d %H:%M:%S +0900'))
    call add(l:template, 'updated     : ' . strftime('%Y-%m-%d %H:%M:%S +0900'))
    call add(l:template, 'categories  : []')
    call add(l:template, 'tags        : []') 
    call add(l:template, 'pin         : false')
    call add(l:template, 'hidden      : false')
    call add(l:template, '---')
"   call add(l:template, '')
"   call add(l:template, '# ')
    call setline(1, l:template)
    execute 'normal! G'
    execute 'normal! $'

    echom 'new wiki page has created'
endfunction

function! LastModified()
    if &modified
        " echo('markdown updated time modified')
        let save_cursor = getpos(".")
        let n = min([10, line("$")])
        keepjumps exe '1,' . n . 's#^\(.\{,10}updated\s*: \).*#\1' .
            \ strftime('%Y-%m-%d %H:%M:%S +0900') . '#e'
        call histdel('search', -1)
        call setpos('.', save_cursor)
    endif
endfun
