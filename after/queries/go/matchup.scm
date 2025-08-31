(function_declaration
  "func" @open.func) @scope.func

(method_declaration
  "func" @open.func) @scope.func

(func_literal
  "func" @open.func) @scope.func

(return_statement
  "return" @mid.func.1)

; 'if', 'else' and 'else if'
(if_statement
  "if" @open.if
  "else" @mid.if.1
  (if_statement
    "if" @mid.if.1)?) @scope.if

; switch
(expression_switch_statement
  "switch" @open.switch
  (expression_case
    "case" @mid.switch.1)
  (default_case
    "default" @mid.switch.2)?) @scope.switch

(_
  "\"" @open.quote_double
  "\"" @close.quote_double) @scope.quote_double

(block
  "{" @open.block
  "}" @close.block) @scope.block

(argument_list
  "(" @open.call
  ")" @close.call) @scope.call
