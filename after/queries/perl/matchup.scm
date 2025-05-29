; matches any conditional -> else type block -> end of final block
(conditional_statement
  [
    "if"
    "unless"
  ] @open.if
  "elsif"? @mid.if.1
  "else"? @mid.if.2
  (block
    "}" @close.if) .) @scope.if

; matches any loop construct -> loop control (last, next) -> end of final block
(_
  [
    "for"
    "foreach"
    "while"
    "unless"
  ] @open.loop
  (block
    "}" @close.loop) .) @scope.loop

(loopex_expression) @mid.loop.1

; matches sub -> return -> end of block
(_
  "sub" @open.fun
  (block
    "}" @close.fun) .) @scope.fun

(return_expression
  "return" @mid.fun.1)

; handling for all the different quote types; multi part quotes cycle through
[
  (_
    "'" @open.quotelike
    (string_content)
    "'" @close.quotelike)
  (quoted_regexp
    "'" @open.quotelike
    "'" @close.quotelike)
  (_
    "'" @open.quotelike
    (_)
    "'"+ @mid.quotelike.1
    (replacement)
    "'" @close.quotelike)
] @scope.quotelike

(try_statement
  "try" @open.try
  "catch"? @mid.try.1
  "finally"? @close.try) @scope.try
