
if !exists('g:loaded_matchup')
      \ || !exists('g:loaded_matchit')
      \ || !exists(":MatchDebug")
  finish
endif

unlet g:loaded_matchit

delcommand MatchDebug

silent! unmap %
silent! unmap [%
silent! unmap ]%
silent! unmap a%
silent! unmap g%

