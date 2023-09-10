/-  *wasm
|%
++  draft-interpret-func
  |=  [params=(list @) =func-type =function-body]
  ::  initialize locals
  ::
  ?>  =((lent params) num-params.func-type)
  =/  locals=(list @)
    %+  weld  params
    %+  reap
      (lent locals.function-body)     
    0
  ::  initialize stack
  ::
  =|  stack=(pole @)
  =/  expressions  expressions.function-body
  ::  loop through the instructions
  ::
  =;  out=(pole @)
    ?>  =((lent out) num-results.func-type)
    out
  |-  ^-  (pole @)
  ?~  expressions  stack
  =+  (apply-instruction i.expressions stack locals)  ::  [new-stack new-locals]
  %=  $
    expressions  t.expressions
    stack        new-stack
    locals       new-locals
  ==
::
++  apply-instruction
  |=  [=expression stack=(pole @) locals=(list @)]
  ^-  [new-stack=(pole @) new-locals=(list @)]
  ?-  expression
  ::
      [%local-get i=@]
    :_  locals
    [(snag i.expression locals) stack]
  ::
      [%local-set i=@]
    ?~  stack  !!
    :-  +.stack
    (snap locals i.expression -.stack)
  ::
      [%i32-add ~]
    ?+    stack  !!
        [a=@ b=@ rest=*]
      :_  locals
      =,  stack
      [(add a b) rest]
    ==
  ==
::
++  draft-interpret-module
  |=  [export-func=@tas =module params=(list @)]
  ::  resolve name
  =/  =export-section  (get-export-section module)
  =/  func-id=@
    =/  =export-desc  (~(got by export-section) export-func)
    ?+  export-desc  !!
      [%func i=@]  i.export-desc
    ==
  =/  =function-section  (get-function-section module)
  =/  func-type-id=@  (snag func-id function-types.function-section)
  =/  =type-section  (get-type-section module)
  =/  =func-type  (snag func-type-id types.type-section)
  =/  =code-section  (get-code-section module)
  =/  =function-body  (snag func-id functions.code-section)
  (draft-interpret-func params func-type function-body)
::
++  get-export-section
  |=  =module
  ^-  export-section
  (need export-section.module)
::
++  get-function-section
  |=  =module
  ^-  function-section
  (need function-section.module)
::
++  get-type-section
  |=  =module
  ^-  type-section
  (need type-section.module)
::
++  get-code-section
  |=  =module
  ^-  code-section
  (need code-section.module)
::
--