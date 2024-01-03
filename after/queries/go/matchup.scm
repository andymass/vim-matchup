(function_declaration "func" @open.func) @scope.func
(method_declaration "func" @open.func) @scope.func
(func_literal "func" @open.func) @scope.func

(return_statement "return" @mid.func.1)

; 'else' and 'else if'
(if_statement
  "else" @_start (if_statement "if" @_end)?
  (#make-range! "mid.if.1" @_start @_end))

; if
(block (if_statement "if" @open.if) @scope.if)

; switch
(expression_switch_statement "switch" @open.switch
  (expression_case "case" @mid.switch.1)
  (default_case "default" @mid.switch.2)) @scope.switch

(_
  "\"" @open.quote_double
  "\"" @close.quote_double) @scope.quote_double
