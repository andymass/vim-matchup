[
    (element)
    (script_element)
    (style_element)
] @scope.tag

(start_tag (tag_name) @open.tag)
(end_tag
  (tag_name) @close.tag
  (#offset! @close.tag 0 -1 0 0))

(self_closing_tag
  (tag_name) @open.selftag
  "/>" @close.selftag) @scope.selftag

; await
(await_statement
  (await_start_expr
   (special_block_keyword) @open.await
   (#offset! @open.await 0 -1 0 0))) @scope.await
(await_end_expr
  (special_block_keyword) @close.await
  (#offset! @close.await 0 -1 0 0))
(then_expr
  (special_block_keyword) @mid.await.1
  (#offset! @mid.await.1 0 -1 0 0))
(catch_expr
  (special_block_keyword) @mid.await.2
  (#offset! @mid.await.2 0 -1 0 0))

; each
(each_statement
  (each_start_expr
   (special_block_keyword) @open.each
   (#offset! @open.each 0 -1 0 0))) @scope.each
(each_end_expr
  (special_block_keyword) @close.each
  (#offset! @close.each 0 -1 0 0))

; if
(if_statement
  (if_start_expr
   (special_block_keyword) @open.if
   (#offset! @open.if 0 -1 0 0))) @scope.if
(if_end_expr
  (special_block_keyword) @close.if
  (#offset! @close.if 0 -1 0 0))
(else_expr
  (special_block_keyword) @mid.if.1
  (#offset! @mid.if.1 0 -1 0 0))
(else_if_expr
  . (special_block_keyword) @mid.if.2
  (#offset! @mid.if.2 0 -1 0 0))
