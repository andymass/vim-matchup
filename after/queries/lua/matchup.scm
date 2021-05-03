(for_in_statement
  "do" @open.loop
  "end" @close.loop) @scope.loop

(while_statement
  "do" @open.loop
  "end" @close.loop) @scope.loop

(break_statement) @mid.loop.1

(if_statement
  "if" @open.if
  "end" @close.if) @scope.if
(else "else" @mid.if.1)
(elseif "elseif" @mid.if.2)

(function
  "function" @open.function
  "end" @close.function) @scope.function
(local_function
  "function" @open.function
  "end" @close.function) @scope.function
(function_definition
  "function" @open.function
  "end" @close.function) @scope.function

(return_statement
  "return" @mid.function.1)
