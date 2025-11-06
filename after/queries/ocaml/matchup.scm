((if_expression
   "if" @open.if
   (then_clause
     "then" @mid.if.2)) @scope.if
 (#not-has-parent? @scope.if else_clause))

(else_clause
  "else" @mid.if.1
  (if_expression
    "if" @mid.if.2
    (then_clause
      "then" @mid.if.2))?)

(parenthesized_expression
  "begin" @open.begin
  "end" @close.begin) @scope.begin

(module_definition
  (module_binding
    (structure
      "struct" @open.class
      "end" @close.class))) @scope.class

(for_expression
  "for" @open.loop
  ("to")? @mid.loop.1
  ("downto")? @mid.loop.1
  (do_clause
    "do" @mid.loop.2
    "done" @close.loop)) @scope.loop

(while_expression
  "while" @open.loop
  (do_clause
    "do" @mid.loop.1
    "done" @close.loop)) @scope.loop

(match_expression
  "match" @open.case
  "with" @mid.case.1
  "|" @mid.case.2) @scope.case

(try_expression
  "try" @open.try
  "with" @mid.try.1) @scope.try
