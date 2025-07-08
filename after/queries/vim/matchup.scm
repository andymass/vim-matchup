(function_definition
  "function" @open.function
  "endfunction" @close.function) @scope.function

(return_statement
  "return" @mid.function.1)

(if_statement
  "if" @open.if
  "endif" @close.if) @scope.if

(elseif_statement
  "elseif" @mid.if.1)

(else_statement
  "else" @mid.if.2)

(for_loop
  "for" @open.loop
  "endfor" @close.loop) @scope.loop

(while_loop
  "while" @open.loop
  "endwhile" @close.loop) @scope.loop

(continue_statement
  "continue" @mid.loop.1)

(break_statement
  "break" @mid.loop.2)
