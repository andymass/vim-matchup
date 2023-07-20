; --------------- module/where ---------------
(_ (
  ("module" @open.module (module))
  (where) @mid.module.1
)) @scope.module


; ----------------- case/of ------------------
(exp_case 
  "case" @open.case (_) 
  "of" @mid.case.1
  (alts
    (alt (_) "->" @mid.case.2 (_))
  ) 
) @scope.case


; --------------- lambda case ----------------
(exp_lambda_case 
  "\case" @open.case
  (alts
    (alt (_) "->" @mid.case.1 (_))
  ) 
) @scope.case


; -------------- if/then/else ----------------
(exp_cond
 "if" @open.if (_)
 "then" @mid.if.1 (_)
 "else" @mid.if.2 (_)
) @scope.if


;------------------ let/in -------------------
(exp_let_in
  (exp_let
    "let" @open.let (_)) 
  (exp_in
    "in" @mid.let.1 (_)) 
) @scope.let

; -------- ADT data/constructors -------------
(adt
  "data" @open.adt (_)
  "=" @mid.adt.1
  (constructors
    "|" @mid.adt.2 (data_constructor)
  )
) @scope.adt

; --------------- ADT record ------------------
(adt
  "data" @open.rec (_)
  (constructors
    (data_constructor_record
      (record_fields
        "{" @mid.rec.1 (_)
        "}" @mid.rec.2
      )
    )
  )
) @scope.rec


; ------------- GADT data/where ---------------
(adt
  "data" @open.gadt (_)
  (where) @mid.gadt.1
  (gadt_constructor
    (constructor) @mid.gadt.2
  )
) @scope.gadt


; --------------- class/where -----------------
(class
  "class" @open.class (_)
  (class_body
    (where) @mid.class.1
    (signature
      (variable) @mid.class.2
    )
  )
) @scope.class


; ------------- type signature ----------------
(signature
  (variable) @open.sig
  (fun
    [ (type_apply)
      (type_name)
    ] @mid.sig.1
  )
) @scope.sig

; ------------- function/args -----------------
(function
  (variable) @open.fun
  (_) @mid.fun.1
) @scope.fun
