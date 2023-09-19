::  AST interpreter utilities
::  Call: (draft-interpret-module func-name=@t =module input-params=(list @))
::
::::  /hoon/wasm/lib
  ::
/-  *wasm
|%
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
++  call-exported-function
  |=  [export-func=@t =module params=(list @)]
  =,  module
  =<
    =/  func-id=@
      =/  =export-desc  (~(got by (make-export-map export-section)) export-func)
      ?>  ?=(%func -.export-desc)
      i.export-desc
    (call-func-id func-id params)
  ::
  |%
  ++  call-func-id
    |=  [func-id=u32 params=(list @)]
    =/  func-type-id=@  (snag func-id function-section)
    =/  =func-type  (snag func-type-id type-section)
    =/  =code  (snag func-id code-section)
    ::  initialize locals
    ::
    ?>  =((lent params) (lent params.func-type))
    =/  locals=(list @)  (weld params (reap (lent locals.code) 0))
    ::  initialize stack
    ::
    =|  stack=(pole @)
    =/  expression  expression.code
    ::  loop through the instructions
    ::
    =;  out=(pole @)
      ?>  =((lent out) (lent results.func-type))
      out
    |-  ^-  (pole @)
    ?~  expression  stack
    =+  (apply-instruction i.expression stack locals)  ::  [new-stack new-locals]
    %=  $
      expression  t.expression
      stack        new-stack
      locals       new-locals
    ==
  ::
  ++  apply-instruction
    |=  [=instruction stack=(pole @) locals=(list @)]
    ^-  [new-stack=(pole @) new-locals=(list @)]
    ?+  instruction  !!
    ::
        [%local-get index=u32]
      :_  locals
      [(snag index.instruction locals) stack]
    ::
        [%local-set index=u32]
      ?~  stack  !!
      :-  +.stack
      (snap locals index.instruction -.stack)
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
    ::
        [%call func-id=u32]
      =/  func-type-id=@  (snag func-id.instruction function-section)
      =/  =func-type  (snag func-type-id type-section)
      =/  len-params=@  (lent params.func-type)
      =/  params=(list @)  (scag len-params stack)
      :_  locals
      (weld (call-func-id func-id.instruction params) (slag len-params stack))
    ::
        [%const *]
      :_  locals
      (handle-const stack instruction)
    ==
  ::
  ++  handle-const
    |=  [stack=(pole @) %const =dime-wasm]
    ^-  (pole @)
    [n.dime-wasm stack]
  ::
  --
--