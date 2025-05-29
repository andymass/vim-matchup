; inherits: quote

(element_node) @scope.tag

(element_node_start
  (tag_name) @open.tag)

(element_node_end
  (tag_name) @close.tag
  (#offset! @close.tag 0 -1 0 0))

(block_statement
  (block_statement_start) @open.block
  (block_statement_end) @close.block) @scope.block

; {{else if ...}}
(mustache_statement
  (helper_invocation
    helper: (identifier) @mid.block.1
    (#lua-match? @mid.block.1 "else")))

; {{else}}
(mustache_statement
  ((identifier) @mid.block.2
    (#lua-match? @mid.block.2 "else")))

(element_node_void
  (tag_name) @open.selftag
  "/>" @close.selftag) @scope.selftag

(mustache_statement
  [
    (helper_invocation)
    "{{"
  ] @open.mustache
  "}}" @close.mustache) @scope.mustache

(sub_expression
  [
    (helper_invocation)
    "("
  ] @open.subexpr
  ")" @close.subexpr) @scope.subexpr
