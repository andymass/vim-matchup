(method
  "def" @open.def
  "end" @close.def) @scope.def
(return
  "return" @mid.def.1)

(class
  "class" @open.class
  "end" @close.class) @scope.class

(if
  "if" @open.if
  "end" @close.if) @scope.if
(else "else" @mid.if.2)
(elsif "elsif" @mid.if.1)

(while
    "while" @open.loop
  body: (do
    "end" @close.loop)) @scope.loop

(for
    "for" @open.loop
  body: (do
    "end" @close.loop)) @scope.loop

(next
  "next" @mid.loop.1)?
(break
  "break" @mid.loop.2)?

(case
  "case" @open.case
  (when
    "when" @mid.case)?
  (else
    "else" @mid.case)?
  "end" @close.case) @scope.case
