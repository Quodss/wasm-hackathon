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
++  resolve-name
  |=  [name=@t =module]
  ^-  @
  =,  module
  =/  =export-desc  (~(got by (make-export-map export-section)) name)
  ?>  ?=(%func -.export-desc)
  i.export-desc
::
++  call-name
  |=  [name=@t =module input-params=(list coin-wasm)]
  ^-  (list coin-wasm)
  =;  out=stack
    (need-done out)
  execute:(call-id (resolve-name name module) module input-params)
::
++  get-types
  |=  a=(list coin-wasm)
  ^-  (list valtype)
  ?~  a  ~
  [type.i.a $(a t.a)]
::
++  mint
  |=  a=(list valtype)
  ^-  (list coin-wasm)
  ?~  a  ~
  :_  $(a t.a)
  ^-  coin-wasm
  ?-  i.a
    %i32  [i.a *@]
    %i64  [i.a *@]
    %f32  [i.a *@rs]
    %f64  [i.a *@rd]
  ==
::
++  need-done
  |=  =stack
  ^-  (list coin-wasm)
  ?>  ?=(~ p.stack)
  q.stack
::
++  call-id
  |=  [func-id=@ =module input-params=(list coin-wasm)]
  =,  module
  =/  =func-type  (snag (snag func-id function-section) type-section)
  =/  =code  (snag func-id code-section)
  =/  locals  locals.code
  =/  expression  expression.code
  ::  Type check:
  ::
  ?>  =(params.func-type (get-types input-params))
  ::  Initialize locals:
  ::
  =/  locals=(list coin-wasm)  (weld input-params (mint locals.code))
  ::  Initialize stack
  ::
  =|  s=stack
  ::  Announce depth
  ::
  =/  depth=@  0
  ::
  ::  Define result type
  =/  result-type  results.func-type
  ::
  |%
  ++  this  .
  ++  execute
    |-  ^-  stack
    ::  check if branch command is on the stack
    ::
    ?.  =(~ p.s)  ::  TMI
      ::  if yes, if label=0: pop needed amount of values
      ::
      ?>  ?=(^ p.s)
      =,  s
      ?:  =(label.u.p 0)
        [[~] (slag (lent result-type) q.s)]
      ::  if label > 0, assert label <= depth, decrement and forward
      ::
      ?>  (lte label.u.p depth)
      [(some [%branch (dec label.u.p)]) q.s]
    ::  else, return stack if no intructions left
    ::
    ?:  =(~ expression)  s  ::  TMI
    ::  if no, carry on...
    ::
    =.  this  (apply-instruction (snag 0 expression))
    $(expression (slag 1 expression))
  ::
  ++  apply-instruction
    |=  =instruction
    ^+  this
    ?+  instruction  ~|(instruction !!)
    ::
        [%local-get index=@]
      =,  instruction
      this(q.s [(snag index locals) q.s])
    ::
        [%local-set index=@]
      ?>  ?=([a=coin-wasm rest=*] q.s)
      =,  q.s
      =,  instruction
      ?>  =(type.a type:(snag index locals))
      this(q.s rest, locals (snap locals index a))
    ::
        [%add type=valtype]
      ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
      =,  q.s
      =,  instruction
      this(q.s [(handle-add type a b) rest])
    ::
        [%call func-id=@]
      =,  instruction
      ~!  instruction
      =/  subfunc-type=^func-type  (snag (snag func-id function-section) type-section)
      =/  n-params=@  (lent params.func-type)
      %=    this
          q.s
        %+  weld
          =+  out=execute:(call-id func-id module (scag n-params q.s))
          ?>  ?=(~ p.out)
          q.out
        (slag n-params q.s)
      ==
    ::
        [%const p=coin-wasm]
      =,  instruction
      this(q.s [p q.s])
    ::
        [%lt type=valtype mode=(unit ?(%s %u))]
      ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
      =,  q.s
      =,  instruction
      this(q.s [(handle-lt type mode a b) rest])
    ::
        [%if *]
      ?>  ?=([a=[type=%i32 n=@] rest=*] q.s)
      =,  q.s
      =,  instruction
      =/  new-stack=stack
        ?:  =(n.a 1)
          execute:this(s *stack, expression branch-true)
        execute:this(s *stack, expression branch-false)
      this(p.s p.new-stack, q.s (weld q.new-stack rest))
    ::
        [%sub type=valtype]
      ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
      =,  q.s
      =,  instruction
      this(q.s [(handle-sub type a b) rest])
    ::
        [%mul type=valtype]
      ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
      =,  q.s
      =,  instruction
      this(q.s [(handle-mul type a b) rest])
    ==
  ::
  ++  handle-add
    |=  [type=valtype a=coin-wasm b=coin-wasm]
    ^-  coin-wasm
    ?-    type
        %i32
      :-  %i32
      ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
      (~(sum fo (bex 32)) n.a n.b)
    ::
        %i64
      :-  %i64
      ?>  &(?=(%i64 type.a) ?=(%i64 type.b))
      (~(sum fo (bex 64)) n.a n.b)
    ::
        %f32
      :-  %f32
      ?>  &(?=(%f32 type.a) ?=(%f32 type.b))
      (add:rs n.a n.b)
    ::
        %f64
      :-  %f64
      ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
      (add:rd n.a n.b)
    ==
  ::
  ++  handle-sub
    |=  [type=valtype a=coin-wasm b=coin-wasm]
    ^-  coin-wasm
    ?-    type
        %i32
      :-  %i32
      ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
      (~(dif fo (bex 32)) n.a n.b)
    ::
        %i64
      :-  %i64
      ?>  &(?=(%i64 type.a) ?=(%i64 type.b))
      (~(dif fo (bex 64)) n.a n.b)
    ::
        %f32
      :-  %f32
      ?>  &(?=(%f32 type.a) ?=(%f32 type.b))
      (sub:rs n.a n.b)
    ::
        %f64
      :-  %f64
      ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
      (sub:rd n.a n.b)
    ==
  ::
  ++  handle-mul
    |=  [type=valtype a=coin-wasm b=coin-wasm]
    ^-  coin-wasm
    ?-    type
        %i32
      :-  %i32
      ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
      (~(pro fo (bex 32)) n.a n.b)
    ::
        %i64
      :-  %i64
      ?>  &(?=(%i64 type.a) ?=(%i64 type.b))
      (~(pro fo (bex 64)) n.a n.b)
    ::
        %f32
      :-  %f32
      ?>  &(?=(%f32 type.a) ?=(%f32 type.b))
      (mul:rs n.a n.b)
    ::
        %f64
      :-  %f64
      ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
      (mul:rd n.a n.b)
    ==
  ::
  ++  handle-lt
    |=  [type=valtype mode=(unit ?(%s %u)) a=coin-wasm b=coin-wasm]
    ^-  coin-wasm
    ?+    type  !!
        %f64
      :-  %i32
      ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
      ?:  (lth:rd n.a n.b)
        1
      0
    ==
  --
--