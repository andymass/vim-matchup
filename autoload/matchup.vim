
function! matchup#init()
  call s:init_options()
  call s:init_modules()
  call s:init_default_mappings()
endfunction

function! s:init_options()
  call s:init_option('matchup_matchparen_enabled', 1)

  call s:init_option('matchup_motion_enabled', 1)
  call s:init_option('matchup_motion_close_end', 1)  " xxx to implement

  call s:init_option('matchup_text_obj_enabled', 1)
  call s:init_option('matchup_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('matchup_imap_enabled', 1)
endfunction

function! s:init_option(option, default)
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  endif
endfunction

function! s:init_modules()
  for l:mod in s:modules
    if index(get(g:, 'matchup_disabled_modules', []), l:mod) >= 0
      continue
    endif

    try
      call matchup#{l:mod}#init_module()
    catch /E117.*#init_/
    endtry
  endfor
endfunction

function! s:init_default_mappings()
  if !get(g:,'matchup_mappings_enabled', 1) | return | endif

  function! s:map(mode, lhs, rhs, ...)
    if !hasmapto(a:rhs, a:mode)
          \ && ((a:0 > 0) || (maparg(a:lhs, a:mode) ==# ''))
      silent execute a:mode . 'map ' a:lhs a:rhs      
                            " <silent> XXX
    endif
  endfunction

  " these are forced in order to overwrite matchit mappings
  if get(g:, 'matchup_motion_enabled', 0)
    call s:map('n', '%', '<plug>(matchup-%)', 1)
    call s:map('n', 'g%', '<plug>(matchup-g%)', 1)
    call s:map('n', ']%', '<plug>(matchup-]%)', 1)
    call s:map('n', '[%', '<plug>(matchup-[%)', 1)

    call s:map('x', '%', '<plug>(matchup-%)', 1)
    call s:map('o', '%', '<plug>(matchup-%)', 1)
  endif

  if get(g:, 'matchup_text_obj_enabled', 0)
    call s:map('x', 'i%', '<plug>(matchup-i%)')
    call s:map('x', 'a%', '<plug>(matchup-a%)')
    call s:map('o', 'i%', '<plug>(matchup-i%)')
    call s:map('o', 'a%', '<plug>(matchup-a%)')
  endif

  if get(g:, 'matchup_imap_enabled', 0)
    call s:map('i', '<c-x><cr>',  '<plug>(matchup-delim-close)')
  endif
endfunction

let s:modules = map(
      \ glob(fnamemodify(expand('<sfile>'), ':r') . '/*.vim', 0, 1),
      \ 'fnamemodify(v:val, '':t:r'')')

" vim: fdm=marker sw=2
