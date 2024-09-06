set nocompatible
source ../common/bootstrap.vim

if !has('nvim')
  echo 'skipping test-where for vim'
  call matchup#test#finished()
endif

set encoding=utf-8 columns=120
NoMatchParen

edit +161 normal.c

redir! > test1.out
  sil MatchupWhereAmI?
  sleep 50m
redir END

normal! j
redir! > test2.out
  sil MatchupWhereAmI?
  sleep 50m
redir END

normal! k
redir! > test3.out
  sil MatchupWhereAmI??
  sleep 50m
redir END

call assert_equal(readfile('test1.good'), readfile('test1.out'))
call assert_equal(readfile('test2.good'), readfile('test2.out'))
call assert_equal(readfile('test3.good'), readfile('test3.out'))

call matchup#test#finished()
