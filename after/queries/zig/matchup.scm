; inherits: quote

(function_declaration
  "fn" @open.function) @scope.function
(return_expression
  "return" @mid.function.1)

; 'else' and 'else if'
(else_clause
  "else" @_start (if_statement "if" @_end)?
  (#make-range! "mid.if.1" @_start @_end))

; if
((if_statement
  "if" @open.if) @scope.if
 (#not-has-parent? @scope.if else_clause))

; Loops
(while_statement "while" @open.loop) @scope.loop
(break_expression "break" @mid.loop.1)
(continue_expression "continue" @mid.loop.2)
