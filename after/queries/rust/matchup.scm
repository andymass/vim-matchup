(block (if_expression "if" @open.if_) @scope.if_)
(let_declaration (if_expression "if" @open.if_) @scope.if_)

(else_clause "else" @mid.if_.1 (block))
(else_clause
  "else" @_start (if_expression "if" @_end)
  (#make-range! "mid.if_.2" @_start @_end))
