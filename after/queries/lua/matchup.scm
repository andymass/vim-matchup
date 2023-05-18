; inherits: quote

(for_statement
  "do" @open.loop
  "end" @close.loop) @scope.loop

(while_statement
  "do" @open.loop
  "end" @close.loop) @scope.loop

(break_statement) @mid.loop.1

(if_statement
  "if" @open.if
  "end" @close.if) @scope.if
(else_statement "else" @mid.if.1)
(elseif_statement "elseif" @mid.if.2)

(function_declaration
  "function" @open.function
  "end" @close.function) @scope.function
(function_definition
  "function" @open.function
  "end" @close.function) @scope.function

(return_statement
  "return" @mid.function.1)

(do_statement
  "do" @open.block
  "end" @close.block) @scope.block
