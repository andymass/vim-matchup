" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let g:matchup#re#not_bslash =  '\v%(\\@<!%(\\\\)*)@<=\m'

" 1 \1 \\1 \\\1 \\\\1 \\\\\1
let g:matchup#re#backref = g:matchup#re#not_bslash.'\\'.'\(\d\)'

" vim: fdm=marker sw=2

