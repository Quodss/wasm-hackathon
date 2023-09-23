::  .wasm -> AST transformer
::  (main:wasm-to-ast wasm-file=@) returns AST representation of the module
::
::::  /hoon/wasm-to-ast/lib
  ::
/-  *wasm
|%
++  main
  |=  wasm=@
  ^-  module
  =/  wasm-bytes=(list @ux)  (rip 3 wasm)
  ?>  ~|  'malformed-wasm-header'
      .=  (scag 8 wasm-bytes)
      ^~  %+  weld
            `(list @ux)`[0x0 ((list @ux) "asm")]  ::  binary magic
          `(list @ux)`~[0x1 0x0 0x0 0x0]          ::  Wasm version
  ::
  ::  Wasm binary is a vector of [section-code=@ux section-size=@ux section-bytes=(list @ux)]
  ::
  =.  wasm-bytes  (slag 8 wasm-bytes)
  =|  out=module
  |-  ^-  module
  ?~  wasm-bytes  out
  =/  section-code=@ux  i.wasm-bytes
  ?~  t.wasm-bytes  !!
  =/  section-size=@  i.t.wasm-bytes
  =/  section-bytes=(list @ux)  (scag section-size t.t.wasm-bytes)
  ::  zero-padding
  ::
  =?  section-bytes  !=(section-size (lent section-bytes))
    (weld section-bytes (reap (sub section-size (lent section-bytes)) 0x0))
  =.  out
    ?+  section-code  out
    ::  each section is found only once in the binary file
    ::
      %0x1  out(type-section (get-type-section section-bytes))
      %0x3  out(function-section (get-function-section section-bytes))
      %0x7  out(export-section (get-export-section section-bytes))
      %0xa  out(code-section (get-code-section section-bytes))
    ==
  $(wasm-bytes (slag section-size t.t.wasm-bytes))
::
++  snip-u-n
  |=  [bytes=(list @ux) n=@]
  ^-  [@u (list @ux)]
  ?~  bytes  !!
  ?:  (lth i.bytes 128)
    ?>  (lth i.bytes (bex n))
    [i.bytes t.bytes]
  ?>  (gth n 7)
  =/  [m=@u rest-bytes=(list @ux)]  $(bytes t.bytes, n (sub n 7))
  :_  rest-bytes
  (add (sub i.bytes 128) (mul 128 m))
::
++  snip-s-n
  !:
  |=  [bytes=(list @ux) n=@]
  ^-  [@s (list @ux)]
  =,  si
  ?~  bytes  !!
  ?:  (lth i.bytes 64)
    ?>  (lth i.bytes (bex (dec n)))
    [(new & i.bytes) t.bytes]
  ?:  (lth i.bytes 128)
    ?>  |((gth n 8) (gte i.bytes (sub 128 (bex (dec n)))))
    [(dif (new & i.bytes) --128) t.bytes]
  ?>  (gth n 7)
  =/  [m=@s rest-bytes=(list @ux)]  $(bytes t.bytes, n (sub n 7))
  :_  rest-bytes
  (sum (new & (sub i.bytes 128)) (pro --128 m))
::
++  get-type-section
  |=  bytes=(list @ux)
  ^-  type-section
  ?:  =(~ bytes)  *type-section
  =|  out=type-section
  =^  num-types=@  bytes  (snip-u-n bytes 32)
  =/  type-bytes=(list @ux)  bytes
  |-  ^-  type-section
  ?:  =(~ type-bytes)
    ?>  =(num-types (lent out))
    (flop out)
  =^  =func-type  type-bytes
    (get-func-type type-bytes)
  $(out [func-type out])
::
++  get-func-type
  |=  bytes=(list @ux)
  ^-  [func-type (list @ux)]
  ?>  =((snag 0 bytes) %0x60)
  =.  bytes  (slag 1 bytes)
  =|  out=func-type
  =^  num-params=@  bytes  (snip-u-n bytes 32)
  =.  params.out  (turn (scag num-params bytes) get-valtype)
  =^  num-results=@  bytes  (snip-u-n (slag num-params bytes) 32)
  =.  results.out  (turn (scag num-results bytes) get-valtype)
  ?>  =(num-results (lent results.out))
  ?>  =(num-params (lent params.out))
  :-  out
  (slag num-results bytes)
::
++  get-valtype
  |=  byte=@ux
  ^-  valtype
  ?+  byte  !!
    %0x7f  %i32
    %0x7e  %i64
    %0x7d  %f32
    %0x7c  %f64
  ==
::
++  get-function-section
  |=  bytes=(list @ux)
  ^-  function-section
  ?:  =(~ bytes)  *function-section
  =^  num-functions=@  bytes  (snip-u-n bytes 32)
  =/  out=function-section  ((list u32) bytes)
  ?>  =(num-functions (lent out))
  out
::
++  get-export-section
  |=  bytes=(list @ux)
  ^-  export-section
  ?:  =(~ bytes)  *export-section
  =|  out=export-section
  =^  num-exports=u32  bytes  (snip-u-n bytes 32)
  =/  exports-bytes=(list @ux)  bytes
  ?:  =(0 num-exports)
    ?>  =(~ exports-bytes)
    out
  |-  ^-  export-section
  ?:  =(~ exports-bytes)
    ?>  =(0 num-exports)
    (flop out)
  =^  length-name=u32  exports-bytes  (snip-u-n exports-bytes 32)
  =/  name=@t
    %-  crip
    ;;  tape
    (scag length-name exports-bytes)
  =/  export-desc-byte=@ux  (snag length-name exports-bytes)
  ?>  =(export-desc-byte %0x0)
  =^  export-index-byte=u32  exports-bytes  (snip-u-n (slag +(length-name) exports-bytes) 32)
  %=  $
    out  [[name %func (u32 export-index-byte)] out]
    num-exports    (dec num-exports)
  ==
::
++  get-code-section
  |=  bytes=(list @ux)
  ^-  code-section
  ?:  =(~ bytes)  *code-section
  =|  out=code-section
  =^  num-codes=u32  bytes  (snip-u-n bytes 32)
  =/  codes-bytes=(list @ux)  bytes
  |-  ^-  code-section
  ?:  =(~ codes-bytes)
    ?>  =(num-codes 0)
    (flop out)
  =^  one-code-length=u32  codes-bytes  (snip-u-n codes-bytes 32)
  =/  one-code-bytes=(list @ux)
    (scag one-code-length codes-bytes)
  ?>  =(one-code-length (lent one-code-bytes))
  %=  $
    num-codes    (dec num-codes)
    codes-bytes  (slag one-code-length codes-bytes)
    out          [(get-code one-code-bytes) out]
  ==
::
++  get-code
  |=  bytes=(list @ux)
  ^-  code
  ?:  =(~ bytes)  *code
  |^
  =|  out=code
  =^  locals-number=u32  bytes  (snip-u-n bytes 32)
  =^  locals=(list valtype)  bytes  (handle-locals locals-number bytes)
  out(expression (parse-instructions bytes), locals locals)
  ::
  ++  handle-locals
    |=  [locals-number=@ bytes=(list @ux)]
    ^-  [(list valtype) (list @ux)]
    ?:  =(locals-number 0)
      [~ bytes]
    =^  valtype-number=u32  bytes  (snip-u-n bytes 32)
    ?~  bytes  !!
    =/  v=valtype  (get-valtype i.bytes)
    =^  rest-locals=(list valtype)  t.bytes
      $(locals-number (dec locals-number), bytes t.bytes)
    :_  t.bytes
    (weld (reap valtype-number v) rest-locals)
  ::
  --
::
  ++  parse-instructions
  |=  bytes=(pole @ux)
  ^-  (list instruction)
  |^
  (scan (tape bytes) expression-end)
  ::  Functional parser utils for expression parsing
  ::
  ::  ++i-n: parse n-bit integer
  ::
  ++  i-n
    |=  n-bits=@
    =*  this  $
    %+  knee  *@
    |.  ~+
    ;~  pose
      ::  multiple byte case
      ::
      ?:  (lte n-bits 7)  fail
      %+  cook
        |=  [n=@ m=@]
        %+  add
          (mul 128 m)
        (sub n 128)
      ;~  plug
        (shim 128 255)
        this(n-bits (sub n-bits 7))
      ==
      ::  single byte case
      ::
      (cook ,@ (shim 0 (dec (bex (min n-bits 7)))))
    ==
  ::  ++bild: if an edge `vex` reflects a failure, fail,
  ::  otherwise connect `vex` with a rule built from the parsing result
  ::  slammed against the gate `gat`
  ::
  ++  bild
    |*  [vex=edge gat=_=>(rule |*(* *rule))]
    ?~  q.vex
      vex
    %.  [vex (gat p.u.q.vex)]
    (comp |*([a=* b=*] b))
  ::  parse i32 vector
  ::
  ++  vec-i-32
    %+  cook  ,(list @)
    ;~  bild
      (i-n 32)
      |=  n=@
      (stun [n n] (cook ,@ (i-n 32)))
    ==
  ::
  ++  f64
    %+  cook
      |=  =(list @)
      ;;  @rd
      %+  can  3
      %+  fuse  (reap 8 1)
      list
    (stun [8 8] next)
  ::
  ++  f32
    %+  cook
      |=  =(list @)
      ;;  @rs
      %+  can  3
      %+  fuse  (reap 4 1)
      list
    (stun [4 4] next)
  ::
  ++  fuse                                                ::  from ~paldev
    |*  [a=(list) b=(list)]
    ^-  (list [_?>(?=(^ a) i.a) _?>(?=(^ b) i.b)])
    ?~  a  ~
    ?~  b  ~
    :-  [i.a i.b]
    $(a t.a, b t.b)
::
  ::  parse an expression that ends with `end` (0xb)
  ::
  ++  expression-end
    |-
    =*  this  $
    %+  knee  *(list instruction)
    |.  ~+
    ;~  pose
      (cold ~ end)         ::  just end
      ;~(plug instr this)  ::  parse one instr at a time
    ==
  ::  parse an expression that ends with `else` (0x5)
  ::
  ++  expression-else
    |-
    =*  this  $
    %+  knee  *(list instruction)
    |.  ~+
    ;~  pose
      (cold ~ else)         ::  just else
      ;~(plug instr this)  ::  parse one instr at a time
    ==
  ::
  ++  end  (just '\0b')
  ++  else  (just '\05')
  ::  parse an instruction
  ::
  ++  instr
    ;~  pose
      instr-zero
      instr-one
      instr-two
      block
      loop
      if
      if-else
    ==
  ::
  ::  Instruction parsers
  ::
  ++  instr-zero  (cook handle-zero-args (mask mask-zero))
  ++  instr-one
    ;~  pose
      %+  cook  handle-one-arg-i32
      ;~(plug (mask mask-one-i32) (i-n 32))
    ::
      %+  cook  handle-const-i64
      ;~(plug (just '\42') (i-n 64))
    ::
      %+  cook  handle-const-f32
      ;~(plug (just '\43') f32)
    ::
      %+  cook  handle-const-f64
      ;~(plug (just '\44') f64)
    ==
  ::
  ++  instr-two
    ;~  pose
      %+  cook  handle-two-args-i32
      ;~(plug (mask mask-two-i32) (i-n 32) (i-n 32))
    ::
      %+  cook  handle-br-table
      ;~(plug (just '\0e') vec-i-32 (i-n 32))
    ==
  ::
  ++  block
    %+  cook  handle-block
    ;~(pfix (just '\02') ;~(plug next expression-end))
  ::
  ++  loop
    %+  cook  handle-loop
    ;~(pfix (just '\03') ;~(plug next expression-end))
  ::
  ++  if
    %+  cook  handle-if
    ;~(pfix (just '\04') ;~(plug next expression-end))
  ::
  ++  if-else
    %+  cook  handle-if-else
    ;~(pfix (just '\04') ;~(plug next expression-else expression-end))
  ::
  ::  All handle-X functions must return `instruction` type
  ::
  ++  mask-zero
    ^~
    %+  skim  (gulf '\00' '\ff')
    |=  op=char
    ?=(bin-opcodes-zero-args op)
  ::
  ++  handle-zero-args
    |=  op=char
    ^-  instruction
    ?+  op  ~|(op !!)
      %0x6a  [%add %i32]
      %0x63  [%lt %f64 ~]
      %0xa1  [%sub %f64]
      %0xa2  [%mul %f64]
    ==
  ::
  ++  mask-one-64
    ^-  (list char)
    :~  '\42'
        '\44'
    ==
  ++  mask-one-i32
    ^~
    %+  skim  (gulf '\00' '\ff')
    |=  op=char
    ?&  ?=(bin-opcodes-one-arg op)
        !(~(has in (silt mask-one-64)) op)
        !=(op '\43')
    ==
  ::
  ++  handle-one-arg-i32
    |=  [op=char arg=@]
    ^-  instruction
    ?+  op  !!
      %0x10  [%call arg]
      %0x20  [%local-get arg]
      %0x21  [%local-set arg]
      %0x41  [%const %i32 arg]
    ==
  ::
  ++  mask-two-i32
    ^~
    %+  skim  (gulf '\00' '\ff')
    |=  op=char
    ?&  ?=(bin-opcodes-two-args op)
        !=(op '\0e')
    ==
  ::
  ++  handle-two-args-i32
    |=  [op=char arg1=@ arg2=@]
    ^-  instruction
    !!
  ::
  ++  handle-br-table
    |=  [op=char vec=(list @) i=@]
    ^-  instruction
    ?>  ?=(%0xe op)
    [%br-table vec i]
  ::
  ++  handle-block
    |=  [blocktype-index=@ body=(list instruction)]
    ^-  instruction
    [%block ~ body]
  ::
  ++  handle-loop
    |=  [blocktype-index=@ body=(list instruction)]
    ^-  instruction
    [%loop ~ body]
  ::
  ++  handle-if
    |=  [blocktype-index=@ body=(list instruction)]
    ^-  instruction
    [%if ~ body ~]
  ::
  ++  handle-if-else
    |=  $:  blocktype-index=@
            body-true=(list instruction)
            body-false=(list instruction)
        ==
    ^-  instruction
    [%if ~ body-true body-false]
  ::
  ++  handle-const-f64
    |=  [op=char i=@rd]
    ^-  instruction
    [%const %f64 i]
  ::
  ++  handle-const-f32
    |=  [op=char i=@rs]
    ^-  instruction
    [%const %f32 i]
  ::
  ++  handle-const-i64
    |=  [op=char i=@]
    ^-  instruction
    !!
  ::
  --
::
--