set nocompatible
source ../common/bootstrap.vim

let g:tex_flavor = "latex"

silent edit test.tex

call matchup#perf#timeout_start(0)

normal! 7G
let s:current = matchup#delim#get_current('all', 'both')
let s:corresponding = matchup#delim#get_matching(s:current)
call matchup#test#assert_equal(1, s:corresponding[0].lnum)

normal! 9G
let s:current = matchup#delim#get_current('all', 'both')
let s:corresponding = matchup#delim#get_matching(s:current)
call matchup#test#assert_equal(9, s:current.lnum)
call matchup#test#assert_equal(1, len(s:corresponding))

call matchup#test#finished()
