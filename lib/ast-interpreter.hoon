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
  =+  :*  buffer=0
          n-pages=`@`?:(?=(@ memory-section.module) 0 min.i.memory-section.module)
          max-pages=`(unit @)`?:(?=(@ memory-section.module) `0 max.i.memory-section.module)
          table=`(list @)`~  ::  XX actually incorrect, deal with this later

      ==
  =*  state-global  -
  ::  instantiate table
  ::
  =?  table  ?=(^ elem-section.module)
    ?>  ?=(@ t.elem-section.module)
    =*  elem  i.elem-section.module
    ?>  ?=([[%const [%i32 @]] ~] offset.elem)  ::  XX the DIRTIEST hack, to be fixed
    ~!  elem
    (weld (reap n.p.i.offset.elem 0) y.elem)
  ::
  |%
  ++  this  .
  ++  call-id
    |=  [func-id=@ input-params=(list coin-wasm)]
    ^-  [(list coin-wasm) _this]
    =/  =func-type  (snag (snag func-id function-section) type-section)
    =/  =code  (snag func-id code-section)
    =/  expression  expression.code
    ::  Type check:
    ::
    ?>  =(params.func-type (get-types input-params))
    ::  Initialize locals:
    ::
    =/  locals=(list coin-wasm)  (weld input-params (mint locals.code))
    :: =/  out=stack  return:reduce:(hwasm-instance func-type locals expression)
    =/  reduced  reduce:(hwasm-instance func-type locals expression)
    =/  out=stack  return:reduced
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
    [q.out this(state-global state-global:reduced)]
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
        =+  [out instance]=(call-id func-id input-values)
        %=  this
          q.s  (weld (flop out) (slag (lent params.subfunc-type) q.s))
          state-global  state-global:instance
        ==
      ::
          [%call-indirect type-id=@ table-id=%0x0]
        ?>  ?=([func-table-index=coin-wasm rest=*] q.s)
        =,  instruction
        =,  q.s
        =/  subfunc-type=func-type
          (snag type-id type-section)
        =/  input-values=(list coin-wasm)
          %-  flop  ::  reversed order of operands in the stack
          (scag (lent params.subfunc-type) rest)
        ?>  =((get-types input-values) params.subfunc-type)
        =+  [out instance]=(call-id (snag n.func-table-index table) input-values)
        %=  this
          q.s  (weld (flop out) (slag (lent params.subfunc-type) rest))
          state-global  state-global:instance
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
          [%gt type=valtype mode=(unit ?(%s %u))]
        ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        this(q.s [(handle-gt type mode a b) rest])
      ::
          [%le type=valtype mode=(unit ?(%s %u))]
        ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        this(q.s [(handle-le type mode a b) rest])
      ::
          [%if *]
        ?>  ?=([a=[type=%i32 n=@] rest=*] q.s)
        =,  q.s
        =,  instruction
        =/  if-instance
          ?:  =(n.a 1)
            reduce:this(s *stack, expression branch-true)
          reduce:this(s *stack, expression branch-false)
        =/  br=(unit branch)
          ?~  p.s.if-instance  ~
          ?:  =(0 u.p.s.if-instance)  ~
          `(dec u.p.s.if-instance)
        %=  this
          p.s     br
          q.s     (weld q.s.if-instance rest)
          locals  locals.if-instance
          state-global  state-global.if-instance
        ==
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
          [%div type=valtype mode=(unit ?(%s %u))]
        ?>  ?=([b=coin-wasm a=coin-wasm rest=*] q.s)
        =,  q.s
        =,  instruction
        this(q.s [(handle-div type mode a b) rest])
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
          state-global  state-global.block-instance
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
          [%br-table *]  ::  [%br-table label-vec=(list @) label-default=@]
        ?>  ?=([a=[type=%i32 n=@] rest=*] q.s)
        =,  instruction
        =,  q.s
        ?:  (gte n.a (lent label-vec))
          this(p.s `label-default, q.s rest)
        this(p.s `(snag n.a label-vec), q.s rest)
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
      ::
          [%store %i32 *]
        ?>  ?=([content=[type=%i32 n=@] addr=[type=%i32 n=@] rest=*] q.s)
        =,  q.s
        =,  instruction
        =/  i=@  (add n.addr offset.m)
        ?>  (lth (add i 4) (mul 65.536 n-pages))
        %=    this
          q.s  rest
            buffer
          (sew bloq=3 [i size=4 n.content] buffer)
        ==
      ::
          [%store %i64 *]
        ?>  ?=([content=[type=%i64 n=@] addr=[type=%i32 n=@] rest=*] q.s)
        =,  q.s
        =,  instruction
        =/  i=@  (add n.addr offset.m)
        ?>  (lth (add i 8) (mul 65.536 n-pages))
        %=    this
          q.s  rest
            buffer
          (sew bloq=3 [i size=8 n.content] buffer)
        ==
      ::
          [%load %i32 *]
        ?>  ?=([addr=[type=%i32 n=@] rest=*] q.s)
        =,  q.s
        =,  instruction
        =/  i=@  (add n.addr offset.m)
        ?>  (lth (add i 4) (mul 65.536 n-pages))
        %=    this
            q.s
          [[%i32 (cut 3 [i 4] buffer)] rest]
        ==
      ::
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
++  handle-gt
  |=  [type=valtype mode=(unit ?(%s %u)) a=coin-wasm b=coin-wasm]
  ^-  coin-wasm
  ?+    type  !!
  ::
      %f64
    :-  %i32
    ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
    ?:  (gth:rd n.a n.b)
      1
    0
  ::
      %i32
    :-  %i32
    ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
    ?:  (gth n.a n.b)
      1
    0
  ==
::
++  handle-le
  |=  [type=valtype mode=(unit ?(%s %u)) a=coin-wasm b=coin-wasm]
  ^-  coin-wasm
  ?+    type  !!
  ::
      %f64
    :-  %i32
    ?>  &(?=(%f64 type.a) ?=(%f64 type.b))
    ?:  (lte:rd n.a n.b)
      1
    0
  ::
      %i32
    :-  %i32
    ?>  &(?=(%i32 type.a) ?=(%i32 type.b))
    ?:  (lte n.a n.b)
      1
    0
  ==
::
++  handle-div
  |=  [type=valtype mode=(unit ?(%s %u)) a=coin-wasm b=coin-wasm]
  ^-  coin-wasm
  ?+    type  !!
  ::
      %f32
    :-  %f32
    ?>  &(?=(%f32 type.a) ?=(%f32 type.b))
    (div:rs n.a n.b)
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