(preproc_ifdef
  ["#ifdef" "#ifndef"] @open.def
  "#endif" @close.def) @scope.def

(preproc_if
  "#if" @open.def
  "#endif" @close.def) @scope.def

(preproc_elif "#elif" @mid.def.1)
(preproc_else "#else" @mid.def.2)

(switch_statement
  "switch" @open.switch
  body: (compound_statement
    (case_statement "case" @mid.switch.1)?
    (case_statement "default" @mid.switch.2)?)) @scope.switch

; 'else' and 'else if'
(if_statement
  "else" @_start (if_statement "if" @_end)?
  (#make-range! "mid.if.1" @_start @_end))

; if
(compound_statement
  (if_statement
    "if" @open.if) @scope.if)
