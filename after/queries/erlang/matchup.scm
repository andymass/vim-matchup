(fun_decl
  (function_clause
    name: (atom) @open.function
    body: (clause_body "->" @mid.function.1))
  .
  ([";" "."] @close.function)) @scope.function

(case_expr
  "case" @open.case "of" @mid.case.1
  clauses: (cr_clause
             body: (clause_body "->" @mid.case.2))
  "end" @close.case) @scope.case

(if_expr
  "if" @open.if
  (if_clause body: (clause_body "->" @mid.if.1))
  "end" @close.if) @scope.if

(receive_expr
  "receive" @open.receive
  clauses: (cr_clause
             body: (clause_body "->" @mid.receive.1))
  after: (receive_after "after" @mid.receive.3
                        body: (clause_body "->" @mid.receive.2))
  "end" @close.receive) @scope.receive

(block_expr
  "begin" @open.block
  "end" @close.block) @scope.block

(maybe_expr
  "maybe" @open.maybe (cond_match_expr "?=" @mid.maybe.0)
  ("else" @mid.maybe.1
     clauses: (cr_clause
                body: (clause_body "->" @mid.maybe.2)))*
  "end" @close.maybe) @scope.maybe

(anonymous_fun
  "fun" @open.anonymous
  (fun_clause (clause_body "->" @mid.anonymous.1))
  "end" @close.anonymous) @scope.anonymous

(try_expr
  "try" @open.try
  ("of" @mid.try.1 (cr_clause
                     body: (clause_body "->" @mid.try.2)))?
  ("catch" @mid.try.3 (catch_clause
                        body: (clause_body "->" @mid.try.4)))?
  ("after" @mid.try.5)?
  "end" @close.try) @scope.try

(binary
  "<<" @open.binary
  ">>" @close.binary) @scope.binary

(list_comprehension
  "[" @open.lc
  (lc_exprs "||" @mid.lc.1
            exprs: (_ (generator "<-" @mid.lc.2)))
  "]" @close.lc
  ) @scope.lc

(map_comprehension .
  "#". "{" @open.mc
  (lc_exprs "||" @mid.mc.1
            (_ (generator "<-" @mid.mc.2)))
  "}" @close.mc .) @scope.mc

(binary_comprehension
  "<<" @open.bc
  (lc_exprs "||" @mid.bc.1
            (_ (generator "<-" @mid.bc.2)))
  ">>" @close.bc) @scope.bc
