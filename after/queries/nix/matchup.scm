; --------------- let/in ---------------
(let_expression
  "let" @open.let (binding_set)
  "in" @mid.let.1 (_)) @scope.let
; --------------- binding --------------
; (binding (_)+ (function_exppression) ";") tend to be many lines long
(binding
  (attrpath) @open.binding (function_expression)
  ";" @close.binding) @scope.binding
