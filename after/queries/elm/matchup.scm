(if_else_expr
  .
  "if" @open.if) @scope.if

(if_else_expr
  "else" @mid.if.1
  "if"? @mid.if.1)

(let_in_expr
  "let" @open.let
  "in" @mid.let.1) @scope.let

(case_of_expr
  (case) @open.case
  (case_of_branch
    (arrow) @mid.case.1)) @scope.case
