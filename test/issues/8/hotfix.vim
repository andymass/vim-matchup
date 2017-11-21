
function! HTMLHotFix()
  call matchup#util#patch_match_words(
     \ '<\@<=\([^/][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>',
     \ '<\@<=\([^/][^ \t>]*\)\%(>\|$\|[ \t][^>]*\%(>\|$\)\):<\@<=/\1>'
     \)
endfunction

let g:matchup_hotfix_html = 'HTMLHotFix'

