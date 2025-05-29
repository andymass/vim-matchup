(if_statement
  "if" @open.if
  (else_if_clause
    ("else"
      "if") @mid.if.1)?
  (else_clause
    "else" @mid.if.2)?
  "end" @close.if) @scope.if

(switch_statement
  "switch" @open.switch
  (case_clause
    "case" @mid.switch.1)?
  "end" @close.switch) @scope.switch

(for_statement
  "for" @open.loop
  "in" @mid.loop.1
  "end" @close.loop) @scope.loop

((break) @mid.loop.2)?

((continue) @mid.loop.3)?

(while_statement
  "while" @open.loop
  "end" @close.loop) @scope.loop

(begin_statement
  "begin" @open.block
  "end" @close.block) @scope.block

(function_definition
  "function" @open.func
  "end" @close.func) @scope.func

(return
  "return" @mid.func.1)
