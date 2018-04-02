
function! s:c_comments()
  if matchup#util#check_match_words('bb2bcbee')
    let b:match_words .= ',/\*:\*/'
  endif
endfunction

let b:matchup_hotfix = function('s:c_comments')

