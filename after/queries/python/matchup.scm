(if_statement
  "if" @open.if_
  alternative: (elif_clause "elif" @mid.if_.1)?
  alternative: (else_clause "else" @mid.if_.2)?) @scope.if_

(function_definition
  "def" @open.function) @scope.function
(return_statement
  "return" @mid.function.1)

(for_statement
	("for" @open.loop)
	alternative: (else_clause "else" @mid.loop.1)?) @scope.loop
(while_statement
	("while" @open.loop)
	alternative: (else_clause "else" @mid.loop.1)?) @scope.loop
(break_statement
  "break" @mid.loop.2)
(continue_statement
  "continue" @mid.loop.3)

(try_statement
  ("try" @open.try_)
  (finally_clause "finally" @mid.try_.1)?
  (except_clause "except" @mid.try_.2)?) @scope.try_
