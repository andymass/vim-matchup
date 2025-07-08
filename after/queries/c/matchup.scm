; inherits: quote

(preproc_ifdef
  [
    "#ifdef"
    "#ifndef"
  ] @open.def
  "#endif" @close.def) @scope.def

(preproc_if
  "#if" @open.def
  "#endif" @close.def) @scope.def

(preproc_elif
  "#elif" @mid.def.1)

(preproc_else
  "#else" @mid.def.2)

(switch_statement
  "switch" @open.switch
  body: (compound_statement
    (case_statement
      "case" @mid.switch.1)?
    (case_statement
      "default" @mid.switch.2)?)) @scope.switch

; 'else' and 'else if'
(else_clause
  "else" @mid.if.1
  (if_statement
    "if" @mid.if.1)?)

; if
((if_statement
  "if" @open.if) @scope.if
  (#not-has-parent? @scope.if else_clause))

; if
(compound_statement
  (if_statement
    "if" @open.if) @scope.if)

; Functions
(function_definition) @scope.function

(function_declarator
  declarator: (identifier) @open.function)

(return_statement
  "return" @mid.function.1)

; Loops
(for_statement
  "for" @open.loop) @scope.loop

(while_statement
  "while" @open.loop) @scope.loop

(do_statement
  "do" @open.loop
  "while" @close.loop) @scope.loop

(break_statement
  "break" @mid.loop.1)

(compound_statement
  "{" @open.block
  "}" @close.block) @scope.block

(argument_list
  "(" @open.call
  ")" @close.call) @scope.call
