(function_statement
  "function" @open.function) @scope.function

(function_statement
  (script_block
    (script_block_body
      (statement_list
        (flow_control_statement
          "return" @mid.function.1)))))

(statement_block
  "{" @open.block
  "}" @close.block) @scope.block

(try_statement
  "try" @open.try) @scope.try

(try_statement
  (catch_clauses
    (catch_clause) @mid.try.1))

(if_statement
  "if" @open.if) @scope.if

(if_statement
  else_clause: (else_clause
    "else" @mid.if.1))

(if_statement
  elseif_clauses: (elseif_clauses
    (elseif_clause
      "elseif" @mid.if.2)))

(for_statement
  "for" @open.loop) @scope.loop

(flow_control_statement
  "break" @mid.loop.1)

(foreach_statement
  "foreach" @open.loop) @scope.loop

(while_statement
  "while" @open.loop) @scope.loop

(do_statement
  "do" @open.loop
  "while" @close.loop) @scope.loop

(switch_statement
  "switch" @open.switch) @scope.switch

(switch_clause
  (switch_clause_condition) @mid.switch.1)
