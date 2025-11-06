(jsx_element) @scope.tag

(jsx_opening_element
  name: (_) @open.tag)

(jsx_closing_element
  name: (_) @close.tag)

(jsx_self_closing_element
  name: (_) @open.selftag
  "/>" @close.selftag) @scope.selftag
