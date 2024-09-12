; inherits: quote

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
  (await_start
    (block_start_tag
      "await" @open.await
      (#offset! @open.await 0 -1 0 0)))) @scope.await

(await_end
  (block_end_tag
    "await" @close.await
    (#offset! @close.await 0 -1 0 0)))

("then" @mid.await.1
  (#offset! @mid.await.1 0 -1 0 0))

("catch" @mid.await.2
  (#offset! @mid.await.2 0 -1 0 0))

; each

(each_statement
  (each_start
    (block_start_tag
      "each" @open.each
      (#offset! @open.each 0 -1 0 0)))) @scope.each

(each_end
  (block_end_tag
    "each" @close.each
    (#offset! @close.each 0 -1 0 0)))

; if

(if_statement
  (if_start
    (block_start_tag
      "if" @open.if
      (#offset! @open.if 0 -1 0 0)))) @scope.if

(else_if_start
  (block_tag
    "else if" @mid.if.1
    (#offset! @mid.if.1 0 -1 0 0)))

(else_start
  (block_tag
    "else" @mid.if.2
    (#offset! @mid.if.2 0 -1 0 0)))

(if_end
  (block_end_tag
    "if" @close.if
    (#offset! @close.if 0 -1 0 0)))

; key

(key_statement
  (key_start
    (block_start_tag
      "key" @open.key
      (#offset! @open.key 0 -1 0 0)))) @scope.key

(key_end
  (block_end_tag
    "key" @close.key
    (#offset! @close.key 0 -1 0 0)))

; snippet

(snippet_statement
  (snippet_start
    (block_start_tag
      "snippet" @open.snippet
      (#offset! @open.snippet 0 -1 0 0)))) @scope.snippet

(snippet_end
  (block_end_tag
    "snippet" @close.snippet
    (#offset! @close.snippet 0 -1 0 0)))
