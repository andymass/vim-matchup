; functions
(function_declaration "function" @open.function) @scope.function
(return_statement "return" @mid.function.1)

; switch case
(switch_statement "switch" @open.switch) @scope.switch
(switch_case "case" @mid.switch.1)
(switch_default "default" @mid.switch.2)

; 'else' and 'else if'
(else_clause
  "else" @_start (if_statement "if" @_end)?
  (#make-range! "mid.if.1" @_start @_end))

; if
((if_statement
  "if" @open.if) @scope.if
 (#not-has-parent? @scope.if else_clause))

; template strings
(template_string
 "`" @open.tmpl_str
 "`" @close.tmpl_str) @scope.tmpl_str
