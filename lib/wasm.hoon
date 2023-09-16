/-  *wasm
|%
++  draft-interpret-func
  |=  [params=(list @) =func-type =code]
  ::  initialize locals
  ::
  ?>  =((lent params) (lent params.func-type))
  =/  locals=(list @)
    %+  weld  params
    %+  reap
      (lent locals.code)     
    0
  ::  initialize stack
  ::
  =|  stack=(pole @)
  =/  expressions  expressions.code
  ::  loop through the instructions
  ::
  =;  out=(pole @)
    ?>  =((lent out) (lent results.func-type))
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
  ?+  expression  !!
  ::
      [%local-get index=u32]
    :_  locals
    [(snag index.expression locals) stack]
  ::
      [%local-set index=u32]
    ?~  stack  !!
    :-  +.stack
    (snap locals index.expression -.stack)
  ::
      [%add %i32]
    ?+    stack  !!
        [a=@ b=@ rest=*]
      :_  locals
      =,  stack
      [(~(sum fo (bex 32)) a b) rest]
    ==
  ::
      [%end ~]
    [stack locals]
  ==
::
++  draft-interpret-module
  |=  [export-func=@tas =module params=(list @)]
  ::  resolve name
  ::
  =/  =export-section  (get-export-section module)
  =/  func-id=@
    =/  =export-desc  (~(got by (make-export-map export-section)) export-func)
    ?+  export-desc  !!
      [%func i=@]  i.export-desc
    ==
  =/  =function-section  (get-function-section module)
  =/  func-type-id=@  (snag func-id function-section)
  =/  =type-section  (get-type-section module)
  =/  =func-type  (snag func-type-id type-section)
  =/  =code-section  (get-code-section module)
  =/  =code  (snag func-id code-section)
  (draft-interpret-func params func-type code)
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
++  make-export-map
  |=  =export-section
  =|  out=(map @t export-desc)
  |-  ^-  (map @t export-desc)
  ?~  export-section  out
  =,  i.export-section
  %=  $
    out  (~(put by out) name export-desc)
    export-section  t.export-section
  ==
::
--