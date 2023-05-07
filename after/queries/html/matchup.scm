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
