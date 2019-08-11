" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:nbsl = '\v%(\\@<!%(\\\\)*)@<=\m'
let g:matchup#re#not_bslash = s:nbsl

" 1 \1 \\1 \\\1 \\\\1 \\\\\1
let g:matchup#re#backref = s:nbsl . '\\' . '\(\d\)'

" \zs atom
let g:matchup#re#zs = s:nbsl . '\\zs'

" \ze atom
let g:matchup#re#ze = s:nbsl . '\\ze'

" \g{special}, \g{special:arg}
let g:matchup#re#gspec = s:nbsl . '\\g{\(\w\+\);\?\(.\{-}\)\?}'

" vim: fdm=marker sw=2

