(function_definition
  "function" @open.function
  "end" @close.function) @scope.function
(return_statement
  "return" @mid.function.1)

(if_statement
  "if" @open.if
  "end" @close.if) @scope.if
(else_clause "else" @mid.if.1)
(elseif_clause "elseif" @mid.if.2)

(for_statement
  "for" @open.loop
  "end" @close.loop) @scope.loop
(while_statement
  "while" @open.loop
  "end" @close.loop) @scope.loop
(break_statement) @mid.loop.1
(continue_statement) @mid.loop.2

(try_statement
  "try" @open.try
  "end" @close.try) @scope.try
(catch_clause
  "catch" @mid.try.2)
(finally_clause
  "finally" @mid.try.1)

(compound_statement
  "begin" @open.block
  "end" @close.block) @scope.block
(do_clause
  "do" @open.block
  "end" @close.block) @scope.block
