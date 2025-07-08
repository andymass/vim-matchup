; inherits: quote

; functions
[
  (arrow_function
    "=>" @open.function)
  (function_expression
    "function" @open.function)
  (function_declaration
    "function" @open.function)
  (method_definition
    body: (statement_block
      "{" @open.function
      "}" @close.function))
] @scope.function

(statement_block
  "{" @open.block
  "}" @close.block) @scope.block

(return_statement
  "return" @mid.function.1)

; switch case
(switch_statement
  "switch" @open.switch) @scope.switch

(switch_case
  "case" @mid.switch.1)

(switch_default
  "default" @mid.switch.2)

; 'else' and 'else if'
(else_clause
  "else" @mid.if.1
  (if_statement
    "if" @mid.if.1)?)

; if
((if_statement
  "if" @open.if) @scope.if
  (#not-has-parent? @scope.if else_clause))

; try
(try_statement
  "try" @open.try) @scope.try

(catch_clause
  "catch" @mid.try.1)

(finally_clause
  "finally" @mid.try.2)

; template strings
(template_string
  "`" @open.tmpl_str
  "`" @close.tmpl_str) @scope.tmpl_str
