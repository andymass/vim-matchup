# matchup.vim

<img src='https://github.com/andymass/matchup.vim/wiki/images/teaser.jpg' width='300px' alt='and in this corner...'>

match-up is a replacement for the venerable vim plugin matchit.vim.
match-up aims to replicate all of matchit's features, fix a number of its
deficiencies and bugs, and add a few totally new features.

## Overview

## Feature list

| feature                          | __matchup__   | matchit       | matchparen    |
| -------------------------------- | ------------- | ------------- | ------------- |
| jump between matching constructs | :thumbsup:    | :thumbsup:    | :x:           |
| jump to open, close              | :thumbsup:    | :question:    | :x:           |
| jump inside                      | :thumbsup:    | :question:    | :x:           |
| full set of text objects         | :thumbsup:    | :x:           | :x:           |
| auto-insert open, close, and mid | :thumbsup:    | :x:           | :x:           |
| auto-completion                  | :thumbsup:    | :x:           | :x:           |
| parallel transmutations          | :thumbsup:    | :x:           | :x:           |
| highlight ()[]{}                 | :thumbsup:    | :x:           | :thumbsup:    |
| highlight _all_ matches          | :thumbsup:    | :x:           | :x:           |
| modern, modular coding style     | :thumbsup:    | :x:           | :x:           |
| actively developed               | :thumbsup:    | :x:           | :x:           |

Legend: :thumbsup: supported. :construction: TODO, planned, or in progress.
:question: poorly implemented, broken, or uncertain.  :x: not possible.

### Feature Documentation

What do we mean by open, close, mid?  Here is an example:

```vim
if l:x == 1
  call one()
else
  call two()
elseif
  call three()
endif
```

The words `if`, `else`, `elseif`, `endif` are called "constructs." The
open construct is `if`, the close construct is `endif`, and the mid
constructs are `else` and `elseif`.  The `if`/`endif` pair is called an
"open-to-close" block and the `if`/`else`, `else`/`elsif`, and
`elseif`/`endif` are called "any" blocks.

- jump between matching constructs
  - `%` forwards matching construct `[count]` times
  - `{count}%` forwards `{count}` times.  Requires
      `let g:matchup_override_Npercent = 1`
  - `g%` backwards matching construct `[count]` times

- jump to open and close
  - `[%` go to `[count]` previous unmatched open construct
  - `]%` go to `[count]` next unmatched close construct

- jump inside
  - `z%` to inside nearest `[count]`th inner contained block.  

- full set of text objects
  `i%` the inside of an open to close block
  `1i%` the inside of an any block
  `{count}i%` If count is not 1, the inside open-to-close block

  `a%` an open-to-close block.
  `1a%` an any block.  Includes mids but does not include open and close.
  `{count}a%` if `{count}` is greater than 1, the `{count}` surrounding open-to-close block.

  Note: by default objects involving `matchpairs` such as `(){}[]` are
performed character-wise, while `matchwords` such as `if`/`endif` are
performed line-wise.
The -wise can be forced using "v", "V", or `^V`
Let `g:matchup_all_charwise`.
XXX inclusive, exclusive
XXX need () characterwise, others linewise except QUIRKS.

  - end-wise completion

  Typing `CTRL-X <cr>` will insert the corresponding end construct.
  
  - automatic block insertion

  _Planned_. Typing `CTRL-X CTRL-B` to produce block skeletons.

  - auto-completion
  
  _Planned_. Typing `CTRL-X %` to give a menu of possible constructs.

  - parallel transmutations

  In insert mode, after changing a construct, typing `CTRL-G %` will 
change any matching constructs in parallel.  As an example,

```latex
\begin{equation}
  x = 10
\end{equation}
```

Appending a `*` and typing `CTRL-G %` will produce:

```latex
\begin{equation*}
  x = 10
\end{equation*}
```

This must be done before leaving insert mode.  A corresponding normal mode
command is planned.

_Planned_: `g:matchup_auto_transmute` 

### Options

## Installation

If you use vim-plug, then add the following line to your vimrc file:

    Plug 'andymass/matchup'

Or use some other plugin manager:

  - vundle
  - neobundle
  - pathogen

## FAQ

  - matchup doesn't work

The plugin requires a recent version of vim.  Please tell me your vim
version and error messages.  Try updating vim and see if the problem
persists.

  - why does jumping not work for construct X in language Y?

Please open a new issue 

  - highlighting is not correct for construct X

matchup uses matchit's filetype data, which may not give enough
information to create proper highlights.  To fix this, you may add a
highlight quirk.

For help, please open a new issue and be a specific as possible.

  - how can I contribute?
  - I'm having performance problems

matchup aims to be as fast as possible.  If you see any performance
issues, please open a new issue and report `g:matchup_times`.

## Interoperability

  - Conflicts with end-wise
  - matchit.vim should not be loaded.  If it is loaded, it must be loaded
    before matchup.

## acknowledgments 

### origin

matchup was originally based on [@lervag](https://github.com/lervag/)'s
[vimtex](github.com/lervag/vimtex).

### inspiration

  * [matchit]().
  * [matchparen]().
  * [vim-endwise](https://github.com/tpope/vim-endwise).

## license

Totally new features

  - parallel transformations (transmutation)
     (need to cache matches and see if they change)
    - polymorphic / smart -> if:end,while:end
  - native split/join
  - quirks
  - auto insert

Definitions

  Matchword
    A matchword is an regular expression which defines interesting items
    to matchup matchup treats specially.  For instance, by default ( and ) are 
    paired matchwords.
    is on the matched to buffer text,
    becomes a matched word, 

  Matched word
    A matched word is an instance of buffer text which matches

Variables

  matchup understands the following variables
    b:match_words        a set of 
    b:match_ignorecase
    b:match_skip
    loaded_matchit

Existing matchit features, made better:

% v_%       between matches
g% v_g%     backwards between matches
[% ]%       to nearest unmatched
o_a% o_i%   delimited text object

Features in matchparen:

  matchup emulates matchparen's highlighting for matchpairs
  Echo invisible pairs 

Features not in matchit:

  Auto-completion
    ctrl-x <CR> shift <CR>
    completes the nearest unmatched matchword.  When n-tuple matchwords are used
    the last one is inserted.

  Highlighting general
    matchup highlights matches for b:match_words

  Jump into
    z[]% go to the center of the next group of matchwords

Development

## TODO

  - Screenshots



