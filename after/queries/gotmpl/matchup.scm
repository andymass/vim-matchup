; vim-matchup tree-sitter queries for Go templates (gotmpl)
; Format: @open / @mid.<group>.<n> / @close + @scope.<group>
; {{ if }} … {{ else if }} … {{ else }} … {{ end }}
; Anchor (`.`) pins @open to the FIRST `if` only; the `if` inside `{{ else if }}`
; follows `else` (not a delimiter), so it is correctly skipped.
; Both `{{` and the whitespace-trim marker `{{-` are distinct grammar tokens —
; chezmoi templates use `{{-`, so the alternation must list both.
; `else` is `?` (optional): a plain `{{ if }}…{{ end }}` has no `else`, and an
; un-quantified token would make the whole pattern require one, so it would fail
; to match (and matchup would fall back to brace matching).
(if_action
  [
    "{{"
    "{{-"
  ]
  .
  "if" @open.if
  "else"? @mid.if.1
  "end" @close.if) @scope.if

; {{ range }} … {{ else }} … {{ end }}  (+ continue/break as inner mids)
(range_action
  "range" @open.range
  "else"? @mid.range.1
  "end" @close.range) @scope.range

(continue_action
  "continue" @mid.range.2)

(break_action
  "break" @mid.range.3)

; {{ with }} … {{ else }} … {{ end }}
(with_action
  "with" @open.with
  "else"? @mid.with.1
  "end" @close.with) @scope.with

; {{ block }} … {{ end }}
(block_action
  "block" @open.block
  "end" @close.block) @scope.block

; {{ define }} … {{ end }}
(define_action
  "define" @open.define
  "end" @close.define) @scope.define
