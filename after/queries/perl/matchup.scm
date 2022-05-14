(if_statement
    "if" @open.if
    "elsif"? @mid.if.1
    "else"? @mid.if.2
) @scope.if

(function_definition
    "sub" @open.fun
) @scope.fun
(return_expression "return" @mid.fun.1)
