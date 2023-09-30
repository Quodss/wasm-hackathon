::  Web Assembly AST interpreter
::
::::  /hoon/ast-interpreter/lib
  ::
/-  *wasm
|%
::  +make-export-map: turns export-section into a map [name=@t =export-desc]
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
::  +find-func-id: find func-id from a name of an exported function
::
++  find-func-id
  |=  [name=@t =module]
  ^-  @
  =,  module
  =/  =export-desc  (~(got by (make-export-map export-section)) name)
  ?>  ?=(%func -.export-desc)
  i.export-desc
::  +get-types: turn a (list coin-wasm) into a list of types of coins
::
++  get-types
  |=  a=(list coin-wasm)
  ^-  (list valtype)
  ?~  a  ~
  [type.i.a $(a t.a)]
::  +mint:  reverse of +get-types
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
::  +instantiate: prepare module
::
++  instantiate
  |=  =module
  =,  module
  ::  This is where globally available structures are defined: globals, memory,
  ::  imports, start function application etc. Returns core for module handling
  ::
  ::  =+  state  ...
  ::
  |%
  ++  call-id
    |=  [func-id=@ input-params=(list coin-wasm)]
    =/  =func-type  (snag (snag func-id function-section) type-section)
    =/  =code  (snag func-id code-section)
    =/  expression  expression.code
    ::  Type check:
    ::
    ?>  =(params.func-type (get-types input-params))
    ::  Initialize locals:
    ::
    =/  locals=(list coin-wasm)  (weld input-params (mint locals.code))
    =/  out=stack  return:reduce:(hwasm-instance func-type locals expression)
    ::  Assert: no branch or branch with label 0
    ::
    ?>  |(?=(~ p.out) =(0 u.p.out))
    ::  Type check
    ::
    :: ?>  =((get-types q.out) results.func-type)
    ?.  =((get-types q.out) results.func-type)
      ~|  [(get-types q.out) results.func-type]
      ~|  q.out
      !!
    q.out
  ::  +hwasm-instance: core for expression computation
  ::
  ++  hwasm-instance
    |=  $:  expr-type=func-type
            locals=(list coin-wasm)
            expression=(list instruction)
        ==
    =|  s=stack
    |%
    ++  this  .
    ++  return
      ^-  stack
      s
    ::
    ++  reduce
      |-  ^+  this
      ::  terminate when no instructions left or navigating br
      ::
      ?:  |(=(~ expression) !=(p.s ~))  this  ::  TMI
      ::  else, apply instruction
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
          [%local-tee index=@]
        ?>  ?=([a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        ?>  =(type.a type:(snag index locals))
        this(locals (snap locals index a))
      ::  ATTENTION: operands are inversed
      ::
          [%add type=valtype]
        ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        this(q.s [(handle-add type a b) rest])
      ::
          [%ne type=valtype]
        ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        this(q.s [(handle-ne type a b) rest])
      ::
          [%call func-id=@]
        =,  instruction
        =/  subfunc-type=func-type
          (snag (snag func-id function-section) type-section)
        =/  input-values=(list coin-wasm)
          %-  flop  ::  reversed order of operands in the stack
          (scag (lent params.subfunc-type) q.s)
        ?>  =((get-types input-values) params.subfunc-type)
        =/  out=(list coin-wasm)  (call-id func-id input-values)
        this(q.s (weld (flop out) (slag (lent params.subfunc-type) q.s)))
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
            return:reduce:this(s *stack, expression branch-true)
          return:reduce:this(s *stack, expression branch-false)
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
      ::
          [%block ~ body=*]
        =,  instruction
        =/  block-instance  reduce:this(s *stack, expression body)
        =/  br=(unit branch)
          ?~  p.s.block-instance  ~
          ?:  =(0 u.p.s.block-instance)  ~
          `(dec u.p.s.block-instance)
        %=  this
          p.s     br
          q.s     (weld q.s.block-instance q.s)
          locals  locals.block-instance
        ==
      ::
          [%br label=@]
        =,  instruction
        this(p.s `label)
      ::
          [%br-if label=@]
        ?>  ?=([a=[type=%i32 n=@] rest=*] q.s)
        =,  instruction
        =,  q.s
        ?:  =(n.a 1)
          this(p.s `label, q.s rest)
        this(q.s rest)
      ::
          [%loop ~ body=*]
        =,  instruction
        |-  ^+  this
        =/  loop-instance  reduce:this(s *stack, expression body)
        ?:  &(?=(^ p.s.loop-instance) =(0 u.p.s.loop-instance))
          $(locals locals.loop-instance)
        =/  br=(unit branch)
          ?~  p.s.loop-instance  ~
          `(dec u.p.s.loop-instance)
        %=  this
          p.s     br
          q.s     (weld q.s.loop-instance q.s)
          locals  locals.loop-instance
        ==
      ==
    --
  --
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
  ::
      %f64
    :-  %i32
    ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
    ?:  (lth:rd n.a n.b)
      1
    0
  ::
      %i32
    :-  %i32
    ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
    ?:  (lth n.a n.b)
      1
    0
  ==
::
++  handle-ne
  |=  [type=valtype a=coin-wasm b=coin-wasm]
  ^-  coin-wasm
  ?-    type
      %i32
    :-  %i32
    ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
    ?:(!=(n.a n.b) 1 0)
  ::
      %i64
    :-  %i32
    ?>  &(?=(%i64 type.a) ?=(%i64 type.b))
    ?:(!=(n.a n.b) 1 0)
  ::
      %f32
    :-  %i32
    ?>  &(?=(%f32 type.a) ?=(%f32 type.b))
    ?:(!=(n.a n.b) 1 0)
  ::
      %f64
    :-  %i32
    ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
    ?:(!=(n.a n.b) 1 0)
  ==
::
--