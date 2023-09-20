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
  :: ?~  bytes  *type-section
  ?:  =(~ bytes)  *type-section
  =|  out=type-section
  :: =/  num-types=@  i.bytes
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
  ?:  =(~ bytes)  ~
  ?+    bytes  ~|(bytes !!)
      [op=bin-opcodes-zero-args rest=*]        ::  no immediate args
    =,  bytes
    [(parse-zero op) $(bytes rest)]
  ::
      [op=bin-opcodes-one-arg rest=*]
    =^  arg=u32  rest.bytes  (snip-u-n rest.bytes 32)  ::  XX  branch on different arg types
    [(parse-one op.bytes arg) $(bytes rest.bytes)]
  ==
::
++  parse-zero
  |=  op=bin-opcodes-zero-args
  ^-  instruction
  ?+  op  !!
    %0x6a  [%add %i32]  ::[%i32-add ~]
    %0xb  [%end ~]
  ==
::
++  parse-one
  |=  [op=bin-opcodes-one-arg arg=@ux]
  ^-  instruction
  ?+  op  !!
    %0x10  [%call (u32 arg)]
    %0x20  [%local-get (u32 arg)]
    %0x21  [%local-set (u32 arg)]
    %0x41  [%const %i32 (u32 arg)]
  ==
::
--