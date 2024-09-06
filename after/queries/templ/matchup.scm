; inherits: quote

[
    (component_if_statement) 
    (conditional_attribute_if_statement)
] @scope.if

; 'else'
("else" @mid.if.1)

; if
("if" @open.if)

; switch
(component_switch_statement "switch" @open.switch
  (component_switch_expression_case "case" @mid.switch.1)
  (component_switch_default_case "default" @mid.switch.2)) @scope.switch

[
    (element)
    (script_element)
] @scope.tag

(tag_start (element_identifier) @open.tag)
(tag_end
  (element_identifier) @close.tag
  (#offset! @close.tag 0 -1 0 0))

(style_element
  (style_tag_start) @open.style
  (#offset! @open.style 0 1 0 -1)
  (style_tag_end) @close.style
  (#offset! @close.style 0 1 0 -1)
  ) @scope.style

(self_closing_tag
  (element_identifier) @open.selftag
  "/>" @close.selftag) @scope.selftag
