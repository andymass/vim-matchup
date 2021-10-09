set nocompatible
source ../common/bootstrap.vim

edit +161 normal.c

redir! > test1.out
  sil MatchupWhereAmI?
redir END

redir! > test2.out
  normal! j
  sil MatchupWhereAmI?
redir END

redir! > test3.out
  normal! k
  sil MatchupWhereAmI??
redir END

call assert_equal(readfile('test1.out'), readfile('test1.good'))
call assert_equal(readfile('test2.out'), readfile('test2.good'))
call assert_equal(readfile('test3.out'), readfile('test3.good'))

call matchup#test#finished()
