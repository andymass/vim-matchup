(if_statement
  "if" @open.if
  alternative: (elif_clause
    "elif" @mid.if.1)?
  alternative: (else_clause
    "else" @mid.if.2)?) @scope.if

(function_definition
  "def" @open.function) @scope.function

(return_statement
  "return" @mid.function.1)

(yield
  "yield" @mid.function.2)

(for_statement
  "for" @open.loop
  alternative: (else_clause
    "else" @mid.loop.1)?) @scope.loop

(while_statement
  "while" @open.loop
  alternative: (else_clause
    "else" @mid.loop.1)?) @scope.loop

(break_statement
  "break" @mid.loop.2)

(continue_statement
  "continue" @mid.loop.3)

(try_statement
  "try" @open.try
  (finally_clause
    "finally" @mid.try.1)?
  (except_clause
    "except" @mid.try.2)?
  (else_clause
    "else" @mid.try.3)?) @scope.try

(string
  (string_start) @open.quote_all
  (string_end) @close.quote_all) @scope.quote_all
