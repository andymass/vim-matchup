; inherits: quote

(method_definition
  ".method" @open.function
  ".end method" @close.function) @scope.function

(parameter_directive
  ".parameter" @open.parameter
  ".end parameter" @close.parameter) @scope.parameter

(param_directive
  ".param" @open.parameter
  ".end param" @close.parameter) @scope.parameter

((opcode) @mid.function.1
  (#lua-match? @mid.function.1 "^return"))

(annotation_directive
  ".annotation" @open.annotation
  ".end annotation" @close.annotation) @scope.annotation

(subannotation_directive
  ".subannotation" @open.subannotation
  ".end subannotation" @close.subannotation) @scope.subannotation

(array_data_directive
  ".array-data" @open.array-data
  ".end array-data" @close.array-data) @scope.array-data

(field_definition
  ".field" @open.field
  ".end field" @close.field) @scope.field

(sparse_switch_directive
  ".sparse-switch" @open.sparse-switch
  ".end sparse-switch" @close.sparse-switch) @scope.sparse-switch

(packed_switch_directive
  ".packed-switch" @open.packed-switch
  ".end packed-switch" @close.packed-switch) @scope.packed-switch
