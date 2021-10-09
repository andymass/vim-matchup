set nocompatible
source ../common/bootstrap.vim

function! s:isclose(a, b, rtol)
    return abs(a:a - a:b) <= a:rtol * abs(a:b)
endfunction

silent edit test.txt

call matchup#perf#tic('testing')

call matchup#perf#timeout_start(100)
sleep 90m
call assert_equal(0, matchup#perf#timeout_check())
call assert_true(s:isclose(matchup#perf#timeout(), 10, 0.20))
sleep 11m
call assert_equal(1, matchup#perf#timeout_check())

call matchup#perf#toc('testing', 'checkpoint1')

call matchup#perf#tic('testing')
sleep 10m
call matchup#perf#toc('testing', 'checkpoint1')

" [testing]
"   checkpoint1                    101.63ms      101.63ms      101.63ms%
let out = matchup#util#command('MatchupShowTimes')
let out = join(out, '\n')
let p = '\s\+\([0-9.]\+\)ms'
let out = matchlist(out, '\[testing]\_.\{-}checkpoint1' . p . p . p)

call assert_true(s:isclose(out[1], 80, 0.20))
call assert_true(s:isclose(out[2], 10, 0.20))
call assert_true(s:isclose(out[3], 100, 0.20))

call matchup#test#finished()
