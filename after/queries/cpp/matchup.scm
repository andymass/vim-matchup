; inherits: c,quote

(template_parameter_list
  "<" @open.template
  ">" @close.template) @scope.template

(template_argument_list
  "<" @open.template_arg
  ">" @close.template_arg) @scope.template_arg
