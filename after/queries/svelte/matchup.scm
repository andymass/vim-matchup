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
   "await" @open.await
   (#offset! @open.await 0 -1 0 0))) @scope.await

(await_end
  "await" @close.await
  (#offset! @close.await 0 -1 0 0))

("then" @mid.await.1
  (#offset! @mid.await.1 0 -1 0 0))

("catch" @mid.await.2
  (#offset! @mid.await.2 0 -1 0 0))

; each

(each_statement
  (each_start
   "each" @open.each
   (#offset! @open.each 0 -1 0 0))) @scope.each

(each_end
  "each" @close.each
  (#offset! @close.each 0 -1 0 0))

; if

(if_statement
  (if_start
   "if" @open.if
   (#offset! @open.if 0 -1 0 0))) @scope.if

(if_end
  "if" @close.if
  (#offset! @close.if 0 -1 0 0))

(else_block
  "else" @mid.if.1
  (#offset! @mid.if.1 0 -1 0 0))

(else_if_block
  "else" @mid.if.2
  (#offset! @mid.if.2 0 -1 0 0))

; key

(key_statement
  (key_start
   "key" @open.key
   (#offset! @open.key 0 -1 0 0))) @scope.key

(key_end
  "key" @close.key
  (#offset! @close.key 0 -1 0 0))

; snippet

(snippet_statement
  (snippet_start
   "snippet" @open.snippet
   (#offset! @open.snippet 0 -1 0 0))) @scope.snippet

(snippet_end
  "snippet" @close.snippet
  (#offset! @close.snippet 0 -1 0 0))
