(if_else_expr
   . "if" @open.if) @scope.if

(if_else_expr
   "else" @_else
   "if"? @_if
   (#make-range! "mid.if.1" @_else @_if))

(let_in_expr
  "let" @open.let
  "in" @mid.let.1) @scope.let

(case_of_expr
  (case) @open.case
  (case_of_branch
     (arrow) @mid.case.1)) @scope.case
