" vim match-up - even better matching
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! s:ftcheck(fts) abort " {{{1
  let l:ft = get(split(&filetype, '\.'), 0, '')
  return index(a:fts, l:ft) > -1
endfunction

" }}}1
function! matchup#quirks#isclike() abort " {{{1
  return s:ftcheck(s:clikeft)
endfunction

let s:clikeft = [
      \ 'arduino', 'c', 'cpp', 'cuda', 'ld', 'php', 'go',
      \ 'javascript', 'typescript',
      \ 'javascriptreact', 'typescriptreact',
      \]

" }}}1
function! matchup#quirks#ishtmllike() abort " {{{1
  return s:ftcheck(s:htmllikeft)
endfunction

let s:htmllikeft = [
    \ 'tidy', 'php', 'liquid', 'haml', 'tt2html',
    \ 'html', 'xhtml', 'xml', 'jsp', 'htmldjango',
    \ 'aspvbs', 'rmd', 'markdown', 'eruby', 'vue',
    \ 'javascriptreact', 'typescriptreact', 'svelte',
    \ 'templ'
    \]

" }}}1

function! matchup#quirks#status_adjust(offscreen) abort " {{{1
  if a:offscreen.match ==# '{' && matchup#quirks#isclike()
    let [l:a, l:b] = [indent(a:offscreen.lnum),
          \ indent(a:offscreen.links.close.lnum)]
    if strpart(getline(a:offscreen.lnum),
          \            0, a:offscreen.cnum-1) =~# '^\s*$'
      let l:target = l:a
    elseif l:a != l:b
      let l:target = l:b
    else
      return 0
    endif
    " go up to next line with same indent (up to s:adjust_max)
    for l:adjust in range(-1, -s:adjust_max, -1)
      let l:lnum = a:offscreen.lnum + l:adjust
      if getline(l:lnum) =~? '^\s*$'
        break
      endif
      if indent(l:lnum) == l:target
            \ && getline(l:lnum) !~? '^\s*\%(#\|/\*\|//\)'
        return l:adjust
      endif
    endfor
  endif

  return 0
endfunction

let s:adjust_max = 9

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2
