" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let g:matchup#re#not_bslash = '\v%(\\@<!%(\\\\)*)@<=\m'

" 1 \1 \\1 \\\1 \\\\1 \\\\\1
let g:matchup#re#backref = g:matchup#re#not_bslash.'\\'.'\(\d\)'

" \zs atom
let g:matchup#re#zs = g:matchup#re#not_bslash . '\\zs'

" \ze atom
let g:matchup#re#ze = g:matchup#re#not_bslash . '\\ze'

" \g{special}
let g:matchup#re#gspec = g:matchup#re#not_bslash . '\\g{\(.\{-}\)}'

function! matchup#re#gspec_pat(key)
  return g:matchup#re#not_bslash . '\V\\g{'.escape(a:key, '\').'}\m'
endfunction

" vim: fdm=marker sw=2

