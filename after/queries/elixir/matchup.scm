(call (identifier) @open.do
      (arguments (binary_operator left: (_) "<-" @mid.do.5 right: (_)))?
      (do_block
          "do" @mid.do.1
          (stab_clause left: (_) "->" @mid.do.2 right: (_))?
          (else_block
              "else" @mid.do.3
              (stab_clause left: (_) "->" @mid.do.4 right: (_))?
          )?
          "end" @close.do . )) @scope.do

(anonymous_function
    "fn" @open.anon-func
    (stab_clause left: (_) "->" @mid.anon-func.1 right: (_))?
    "end" @close.anon-func
  ) @scope.anon-func
