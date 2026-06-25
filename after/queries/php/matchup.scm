; PHP tags
(php_tag) @open.php
(php_end_tag) @close.php
(program) @scope.php

; if
(if_statement
  "if" @open.if
  alternative: (else_if_clause "elseif" @mid.if.1)?
  alternative: (else_clause "else" @mid.if.2)?) @scope.if

; alternative if
(if_statement
  "if" @open.if
  alternative: (else_if_clause "elseif" @mid.if.1)?
  alternative: (else_clause "else" @mid.if.2)?
  "endif" @close.if) @scope.if

; alternative while loops
(while_statement
  "while" @open.while
  "endwhile" @close.while) @scope.while

; alternative for loops
(for_statement
  "for" @open.for
  "endfor" @close.for) @scope.for

; alternative foreach
(foreach_statement
  "foreach" @open.foreach
  "endforeach" @close.foreach) @scope.foreach

; switch
(switch_statement
  "switch" @open.switch
  body: (switch_block
    (case_statement "case" @mid.switch.1)*
    (default_statement "default" @mid.switch.2)?)) @scope.switch

; alternative switch
(switch_statement
  "switch" @open.switch
  body: (switch_block
    (case_statement "case" @mid.switch.1)*
    (default_statement "default" @mid.switch.2)?
    "endswitch" @close.switch)) @scope.switch

; match
(match_expression
  "match" @open.match
  body: (match_block
    "}" @close.match)) @scope.match
(match_conditional_expression
  conditional_expressions: (match_condition_list) @mid.match.1)
(match_default_expression "default" @mid.match.1)

; try
(try_statement
  "try" @open.try
  (catch_clause "catch" @mid.try.1)*
  (finally_clause "finally" @mid.try.2)?) @scope.try

(method_declaration
  "function" @open.function) @scope.function

(return_statement
  "return" @mid.function.1)
