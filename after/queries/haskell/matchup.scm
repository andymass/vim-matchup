; --------------- module/where ---------------
(header (
  ("module" @open.module (module))
  ("where" @mid.module.1)
)) @scope.module

; ----------------- case/of ------------------
(expression/case 
  "case" @open.case (_) 
  "of" @mid.case.1
  (alternatives
    (alternative) @mid.case.2
  ) 
) @scope.case

; --------------- lambda case ----------------
(expression/lambda_case 
  "\case" @open.case
  (alternatives
    (alternative) @mid.case.1
  ) 
) @scope.case

; -------------- if/then/else ----------------
(expression/conditional
 "if" @open.if (_)
 "then" @mid.if.1 (_)
 "else" @mid.if.2 (_)
) @scope.if

;------------------ let/in -------------------
(expression/let_in
  ("let" @open.let (local_binds)) 
  ("in" @mid.let.1 (_)) 
) @scope.let

; -------- ADT data/constructors -------------
(data_type
  "data" @open.adt (_)
  constructors: (data_constructors
    (data_constructor
      constructor: (_) @mid.adt.2
    ))
) @scope.adt

; --------------- ADT record ------------------
(data_type
  "data" @open.rec (_)
  constructors: (data_constructors
    constructor: (data_constructor
      (constructor/record
        fields: (fields
          "{" @mid.rec.1 (_)
          "}" @mid.rec.2
        )
      )
    )
  )
) @scope.rec

; ------------- GADT data/where ---------------
(data_type
  "data" @open.gadt (_)
  "where" @mid.gadt.1
  constructors: (gadt_constructors
    constructor: (gadt_constructor
      name: (constructor) @mid.gadt.2
    )
  )
) @scope.gadt

; --------------- class/where -----------------
(class
  "class" @open.class
  "where" @mid.class.1
  declarations: (class_declarations
    declaration: (_
      name: (variable) @mid.class.2
    )
  )
) @scope.class
