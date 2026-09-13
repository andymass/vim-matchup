; vim-matchup tree-sitter queries for Go templates (gotmpl)
; Format: @open / @mid.<group>.<n> / @close + @scope.<group>
; {{ if }} … {{ else if }} … {{ else }} … {{ end }}
; The grammar inlines else / else-if clauses, so their `else` and `if` tokens
; are direct children of if_action. The anchor (`.`) pins @open to the FIRST
; `if` only; every later `else` or `if` belongs to an else / else-if clause
; and is a mid. `*` (not `?`) because chains can hold any number of them.
; Both `{{` and the whitespace-trim marker `{{-` are distinct grammar tokens —
; chezmoi templates use `{{-`, so the alternation must list both.
(if_action
  [
    "{{"
    "{{-"
  ]
  .
  "if" @open.if
  [
    "else"
    "if"
  ]* @mid.if.1
  "end" @close.if) @scope.if

; {{ range }} … {{ else }} … {{ end }}  (+ continue/break as inner mids)
; range takes at most one `else` (no else-if form), so `?` is enough; an
; un-quantified token would make the whole pattern require one and fail to
; match a plain {{ range }}…{{ end }}.
(range_action
  "range" @open.range
  "else"? @mid.range.1
  "end" @close.range) @scope.range

(continue_action
  "continue" @mid.range.2)

(break_action
  "break" @mid.range.3)

; {{ with }} … {{ else with }} … {{ else }} … {{ end }}
; Same shape as if: anchored opener (an else-with clause's `with` is a direct
; child too and must not open), `*` mids for else / else-with chains.
(with_action
  [
    "{{"
    "{{-"
  ]
  .
  "with" @open.with
  [
    "else"
    "with"
  ]* @mid.with.1
  "end" @close.with) @scope.with

; {{ block }} … {{ end }}
(block_action
  "block" @open.block
  "end" @close.block) @scope.block

; {{ define }} … {{ end }}
(define_action
  "define" @open.define
  "end" @close.define) @scope.define
