(for "for" @open.loop "in" @mid.loop.3) @scope.loop
(while "while" @open.loop) @scope.loop
(block "block" @open.loop) @scope.loop
(break_statement "break" @mid.loop.1)
(continue_statement "continue" @mid.loop.2)

(if "if" @open.conditional) @scope.conditional
(when "when" @open.conditional) @scope.conditional
(elif_branch "elif" @mid.conditional.1)
(else_branch "else" @mid.conditional.2)

(case "case" @open.conditional) @scope.conditional
(of_branch "of" @mid.conditional.3)

(variant_declaration "case" @open.conditional) @scope.conditional
(conditional_declaration "when" @open.conditional) @scope.conditional

(try "try" @open.try) @scope.try
(except_branch "except" @mid.try.1 )
(finally_branch "finally" @mid.try.2)

(proc_declaration "proc" @open.routine) @scope.routine
(func_declaration "func" @open.routine) @scope.routine
(method_declaration "method" @open.routine) @scope.routine
(converter_declaration "converter" @open.routine) @scope.routine
(template_declaration "template" @open.routine) @scope.routine
(macro_declaration "macro" @open.routine) @scope.routine

(proc_expression "proc" @open.routine) @scope.routine
(func_expression "func" @open.routine) @scope.routine

(return_statement "return" @mid.routine.1)

(iterator_declaration "iterator" @open.iterator) @scope.iterator
(iterator_expression "iterator" @open.iterator) @scope.iterator

(yield_statement "yield" @mid.iterator.1)

(import_statement
  "import" @open.import
  (except_clause
    "except" @mid.import.1)) @scope.import

(import_from_statement
  "from" @open.from
  "import" @mid.from.1) @scope.from

(char_literal
  . "'" @open.char
  "'" @close.char .) @scope.char

(interpreted_string_literal
  . "\""  @open.string
  "\"" @close.string .) @scope.string

(raw_string_literal
  . ["r\"" "R\""]  @open.string
  "\"" @close.string .) @scope.string

(long_string_literal
  . ["\"\"\"" "r\"\"\"" "R\"\"\""] @open.multistring
  "\"\"\"" @close.multistring .) @scope.multistring

(generalized_string
  function: (_)
  . ["\"" "\"\"\""] @open.multistring
  ["\"" "\"\"\""] @close.multistring .) @scope.multistring

(accent_quoted
  . "`" @open.accent
  "`" @close.accent .) @scope.accent

(block_documentation_comment
  . "##[" @open.doc_comment
  "]##" @close.doc_comment .) @scope.doc_comment

(block_comment
  . "#[" @open.comment
  "]#" @close.comment .) @scope.comment

(pragma_list
  . "{." @open.pragma
  ["}" ".}"] @close.pragma .) @scope.pragma
