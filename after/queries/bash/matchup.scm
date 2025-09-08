(if_statement
  "if" @open.if
  "fi" @close.if) @scope.if

(else_clause
  "else" @mid.if.1)

(elif_clause
  "elif" @mid.if.2)

(while_statement
  ("while")? @open.loop
  ("until")? @open.loop
  (do_group
    "done" @close.loop)) @scope.loop

(for_statement
  ("for")? @open.loop
  ("select")? @open.loop
  (do_group
    "done" @close.loop)) @scope.loop

((word) @mid.loop.1
  (#eq? @mid.loop.1 "break"))

((word) @mid.loop.2
  (#eq? @mid.loop.2 "continue"))

(case_statement
  "case" @open.case
  (case_item) @mid.case.1
  "esac" @close.case) @scope.case

(heredoc_redirect
  (heredoc_start) @open.rhrd
  (heredoc_end) @close.rhrd) @scope.rhrd

(compound_statement
  "{" @open.block
  "}" @close.block) @scope.block
