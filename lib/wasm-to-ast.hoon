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
++  get-type-section
  |=  bytes=(list @ux)
  ^-  type-section
  ?~  bytes  *type-section
  =|  out=type-section
  =/  num-types=@  i.bytes
  =/  type-bytes=(list @ux)  t.bytes
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
  =/  num-params=@  (snag 0 bytes)
  =.  params.out  (turn (swag [1 num-params] bytes) get-valtype)
  =/  num-results=@  (snag (add 1 num-params) bytes)
  =.  results.out  (turn (swag [(add 2 num-params) num-results] bytes) get-valtype)
  ?>  =(num-results (lent results.out))
  ?>  =(num-params (lent params.out))
  :-  out
  (slag :(add 2 num-params num-results) bytes)
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
  ?~  bytes  *function-section
  =/  num-functions=@  i.bytes
  =/  out=function-section  ((list u32) t.bytes)
  ?>  =(num-functions (lent out))
  out
::
++  get-export-section
  |=  bytes=(list @ux)
  ^-  export-section
  ?~  bytes  *export-section
  =|  out=export-section
  =/  num-exports=@  i.bytes
  =/  exports-bytes=(list @ux)  t.bytes
  ?:  =(0 num-exports)
    ?>  =(~ exports-bytes)
    out
  |-  ^-  export-section
  ?:  =(~ exports-bytes)
    ?>  =(0 num-exports)
    (flop out)
  =/  length-name=@  (snag 0 exports-bytes)
  =/  one-export-bytes=(list @ux)  (swag [1 (add 2 length-name)] exports-bytes)
  ?>  =((add 2 length-name) (lent one-export-bytes))
  =/  name=@t
    %-  crip
    ;;  tape
    (scag length-name one-export-bytes)
  =/  export-desc-byte=@ux  (snag length-name one-export-bytes)
  ?>  =(export-desc-byte %0x0)
  =/  export-index-byte=@ux  (snag (add 1 length-name) one-export-bytes)
  %=  $
    exports-bytes  (slag (add 3 length-name) exports-bytes)
    out  [[name %func (u32 export-index-byte)] out]
    num-exports    (dec num-exports)
  ==
::
++  get-code-section
  |=  bytes=(list @ux)
  ^-  code-section
  ?~  bytes  *code-section
  =|  out=code-section
  =/  num-codes=@  i.bytes
  =/  codes-bytes=(list @ux)  t.bytes
  |-  ^-  code-section
  ?:  =(~ codes-bytes)
    ?>  =(num-codes 0)
    (flop out)
  =/  one-code-length=@  (snag 0 codes-bytes)
  =/  one-code-bytes=(list @ux)
    %+  scag
      one-code-length
    (slag 1 codes-bytes)
  ?>  =(one-code-length (lent one-code-bytes))
  %=  $
    num-codes    (dec num-codes)
    codes-bytes  (slag (add 1 one-code-length) codes-bytes)
    out          [(get-code one-code-bytes) out]
  ==
::
++  get-code
  |=  bytes=(list @ux)
  ^-  code
  ?~  bytes  *code
  =|  out=code
  =/  locals-number=@  i.bytes
  =?  locals.out  !=(0 locals-number)
    =/  locals-bytes=(list @ux)  (scag (mul 2 locals-number) t.bytes)
    (unpack-locals-vector locals-bytes)
  =/  instructions-bytes=(list @ux)  (slag (mul 2 locals-number) t.bytes)
  out(expression (parse-instructions instructions-bytes))
::
++  unpack-locals-vector
  |=  bytes=(pole @ux)
  ^-  (list valtype)
  =;  out=(list @ux)
    (turn out get-valtype)
  |-  ^-  (pole @ux)
  ?~  bytes  ~
  ?>  ?=([type-count=@ type=@ux rest=*] bytes)
  =,  bytes
  (weld (reap type-count type) $(bytes rest))
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
      [op=bin-opcodes-one-arg arg=@ux rest=*]  ::  one immediate arg
    =,  bytes
    [(parse-one op arg) $(bytes rest)]
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