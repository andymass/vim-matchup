(method
  "def" @open.def
  "end" @close.def) @scope.def
(singleton_method
  "def" @open.def
  "end" @close.def) @scope.def
(return
  "return" @mid.def.1)
(yield
  "yield" @mid.def.2)

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
    "when" @mid.case.1)?
  (else
    "else" @mid.case.2)?
  "end" @close.case) @scope.case

(begin
  "begin" @open.begin
  (rescue
    "rescue" @mid.begin.1)?
  (ensure
    "ensure" @mid.begin.2)?
  "end" @close.begin) @scope.begin

(module
  "module" @open.module
  "end" @close.module) @scope.module

(do_block
  "do" @open.do
  "end" @close.do) @scope.do
