
call matchup#util#patch_match_words(
   \ '<\@<=\([^/][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>',
   \ '<\@<=\([^/][^ \t>]*\)\%(>\|$\|[ \t][^>]*\%(>\|$\)\):<\@<=/\1>'
   \)

if get(g:, 'matchup_matchpref_html_nolists', 0)
    call matchup#util#patch_match_words(
        \ '<\@<=[ou]l\>[^>]*\%(>\|$\):<\@<=li\>:<\@<=/[ou]l>',
        \ '')
    call matchup#util#patch_match_words(
        \ '<\@<=dl\>[^>]*\%(>\|$\):<\@<=d[td]\>:<\@<=/dl>',
        \ '')
endif

