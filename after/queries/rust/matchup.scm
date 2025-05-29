; inherits: quote

; --------------- types ---------------
(type_arguments
  "<" @open.typeargs
  ">" @close.typeargs) @scope.typeargs

(type_parameters
  "<" @open.typeparams
  ">" @open.typeparams) @scope.typeparams

; --------------- if/else ---------------
(block
  (if_expression
    "if" @open.if_) @scope.if_)

(expression_statement
  (if_expression
    "if" @open.if_) @scope.if_)

(let_declaration
  (if_expression
    "if" @open.if_) @scope.if_)

(else_clause
  "else" @mid.if_.1
  (block))

(else_clause
  "else" @mid.if_.2
  (if_expression
    "if" @mid.if_.2))

; --------------- async/await ---------------
(function_item
  (function_modifiers
    "async" @open.async)) @scope.async

(async_block
  "async" @open.async) @scope.async

(await_expression
  "await" @mid.async.1)

; --------------- fn/return ---------------
(function_item
  "fn" @open.function) @scope.function

(closure_expression) @scope.function

(return_expression
  "return" @mid.function.1)

; --------------- closures ---------------
(closure_parameters
  "|" @open.closureparams
  "|" @close.closureparams) @scope.closureparams

; --------------- while/loop/for + break/continue ---------------
(for_expression
  .
  "for" @open.loop) @scope.loop

(while_expression
  .
  "while" @open.loop) @scope.loop

(loop_expression
  .
  "loop" @open.loop) @scope.loop

(break_expression
  "break" @mid.loop.1 .)

(break_expression
  "break" @mid.loop.1 .)

(continue_expression
  "continue" @mid.loop.1 .)
