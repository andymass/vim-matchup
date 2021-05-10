[
    (script_element)
    (element)
    (style_element)] @scope.tag
(start_tag (tag_name) @open.tag)
(end_tag
    (tag_name) @close.tag)

(self_closing_tag
  (tag_name) @open.selftag
  "/>" @close.selftag) @scope.selftag
