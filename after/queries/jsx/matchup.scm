(jsx_element) @scope.tag

(jsx_opening_element
  (identifier) @open.tag)

(jsx_closing_element
  (identifier) @close.tag
  (#offset! @close.tag 0 -1 0 0))

(jsx_self_closing_element
  name: (identifier) @open.selftag
  "/>" @close.selftag) @scope.selftag
