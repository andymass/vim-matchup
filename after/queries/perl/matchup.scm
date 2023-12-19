(conditional_statement
    "if" @open.if
) @scope.if

(elsif "elsif"? @mid.if.1)
(else "else"? @mid.if.2)

(subroutine_declaration_statement
    "sub" @open.fun
) @scope.fun
(return_expression "return" @mid.fun.1)
