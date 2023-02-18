(function_definition
  "function" @open.function
  "endfunction" @close.function) @scope.function

(if_statement
  "if" @open.if
  "endif" @close.if) @scope.if
(elseif_statement
  "elseif" @mid.if.1)
(else_statement
  "else" @mid.if.2)

(for_loop
  "for" @open.for
  "endfor" @close.for) @scope.for
