; --------------- fn/return ---------------

(function_item
  "fn" @open.function) @scope.function
(return_expression
  "return" @mid.function.1)

; --------------- async/await ---------------

; give async_block the same scope name, because .await always
; suspends to the innermost async scope
(function_item (function_modifiers "async" @open.async)) @scope.async
(async_block "async" @open.async) @scope.async
(await_expression "await" @mid.async.1)

; --------------- if/else ---------------

; the rust grammar is like (else_clause "else" (if_expression "if"))
; so the else and the if can't be given a single name covering both of them
; hence just highlighting the else. close enough
(else_clause "else" @mid.if_.1 (if_expression) @else_if)
(else_clause "else" @mid.if_.1 (if_let_expression) @else_if)
(else_clause "else" @mid.if_.2 (block))

; ideally neovim would support more predicates like is-not?, which would mean
; that you could recognise an if-expression being the if in an "else if" and
; use that capture @else_if to indicate that it shouldn't form its own
; @scope.if_. I actually don't know if this would work, because predicates
; are not documented anywhere that I can find.
;
; ((if_expression "if" @open.if_) @scope.if_ (is-not? @else_if))
; ((if_let_expression "if" @open.if_) @scope.if_ (is-not? @else_if))
;
; for now, this will suffice to prevent such "else if" if_expressions from
; introducing an inner scope, but won't match "let x = if {} else {}" at all.
(block (if_expression "if" @open.if_) @scope.if_)
(block (if_let_expression "if" @open.if_) @scope.if_)

; --------------- while/loop/for + break/continue ---------------

; the . matches an end, so we can explicitly refuse to handle break 'label; and
; 'label loop {}
(for_expression . "for" @open.loop) @scope.loop
(while_let_expression . "while" @open.loop) @scope.loop
(loop_expression . "loop" @open.loop) @scope.loop

; unfortunately we can't exclude only `break 'label;` but not `break {expression};`
; as _expression is a supernode/meta node or whatever TS calls it, so you can't
; match on (expression)
(break_expression "break" @mid.loop.1 .)
(break_expression "break" @mid.loop.1 .)
(continue_expression "continue" @mid.loop.1 .)

; this strategy would maybe work if matchup were modified to support string
; matches on scopes
; (break_expression (loop_label (identifier) @mid.looplabel_.1))
; (loop_expression (loop_label (identifier) @open.looplabel_)) @scope.looplabel_

; --------------- match/arms ---------------

; this is fun, but lots of match expressions are complex enough that this would
; be too annoying because of firstly the lost syntax highlighting of the arms
; and secondly the fact that many match arms have braces in them, and those
; braces take priority.

; (match_expression
;   "match" @open.match_
;   body: (match_block
;     (match_arm
;       pattern: (match_pattern)? @mid.match_.1
;       pattern: (macro_invocation)? @mid.match_.1
;       )*
;     (match_arm pattern: (match_pattern) @mid.match_.2)
;     .
;   )
; ) @scope.match_

