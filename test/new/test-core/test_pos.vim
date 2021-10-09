set nocompatible
source ../common/bootstrap.vim

silent edit test.txt

call matchup#perf#timeout_start(0)

normal! gg_
call assert_equal([0, 1, 1, 0, 1], matchup#pos#get_cursor())

normal! $
call assert_equal([0, 1, 7, 0, 2147483647], matchup#pos#get_cursor())

let [l, c] = matchup#pos#get_cursor()[1:2]
call assert_equal([0, 2, 1, 0], matchup#pos#next(l, c))
call assert_equal([0, 1, 8, 0], matchup#pos#next_eol(l, c))

let pos = matchup#pos#(l, c)
let pos = matchup#pos#next_eol(matchup#pos#next_eol(pos))
call assert_equal([0, 2, 1, 0], pos)
call assert_equal([2, 1], matchup#pos#(pos))

call assert_equal(1, matchup#pos#smaller_or_equal([2, 10], [3, 1]))
call assert_equal(1, matchup#pos#larger([3, 1], [1, 3]))

call matchup#test#finished()
