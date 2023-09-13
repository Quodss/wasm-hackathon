::  /lib/wasm-to-ast.hoon
::  .wasm -> AST transformer
::  (main:wasm-to-ast wasm-file) returns AST representation of the module
::
/-  *wasm
|%
++  main
  |=  wasm=@
  ^-  module
  =/  wasm-bytes=(list @ux)  (rip 3 wasm)
  ?>  .=  (scag 8 wasm-bytes)
      ^~  %+  weld
            `(list @ux)`[0x0 ;;((list @ux) "asm")]        ::  binary magic
          `(list @ux)`~[0x1 0x0 0x0 0x0]                   ::  Wasm version
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
      %0x1   out(type-section `(get-type-section section-bytes))
      %0x3   out(function-section `(get-function-section section-bytes))
      %0x7   out(export-section `(get-export-section section-bytes))
      %0xa  out(code-section `(get-code-section section-bytes))
    ==
  $(wasm-bytes (slag section-size t.t.wasm-bytes))
::
++  get-type-section
  |=  bytes=(list @ux)
  ^-  type-section
  ?~  bytes  *type-section
  =|  out=type-section
  =/  num-types=@  i.bytes
  =.  num-types.out  num-types
  =/  type-bytes=(list @ux)  t.bytes
  |-  ^-  type-section
  ?:  =(~ type-bytes)  out(types (flop types.out))
  :: ?>  =((snag 0 type-bytes) %0x60)
  :: $(types.out [(get-func-type t.type-bytes) types.out])
  =^  =func-type  type-bytes
    (get-func-type type-bytes)
  $(types.out [func-type types.out])
::
++  get-func-type
  |=  bytes=(list @ux)
  ^-  [func-type (list @ux)]
  ?>  =((snag 0 bytes) %0x60)
  =.  bytes  (slag 1 bytes)
  =|  out=func-type
  =.  num-params.out  (snag 0 bytes)
  =.  params.out  (turn (swag [1 num-params.out] bytes) get-valtype)
  =.  num-results.out  (snag (add 1 num-params.out) bytes)
  =.  results.out  (turn (swag [(add 2 num-params.out) num-results.out] bytes) get-valtype)
  ?>  =(num-results.out (lent results.out))
  :-  out
  (slag :(add 2 num-params.out num-results.out) bytes)
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
  =|  out=function-section
  =.  num-functions.out  i.bytes
  =.  function-types.out  t.bytes
  ?>  =(num-functions.out (lent function-types.out))
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
  =.  num-exports.out  num-exports
  |-  ^-  export-section
  ?:  =(~ exports-bytes)
    ?>  =(0 num-exports)
    out
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
    exports.out
      (~(put by exports.out) name %func export-index-byte)
    num-exports    (dec num-exports)
  ==
::
++  get-code-section
  |=  bytes=(list @ux)
  ^-  code-section
  ?~  bytes  *code-section
  =|  out=code-section
  =.  num-functions.out  i.bytes
  =/  num-functions=@  i.bytes
  =/  functions-bytes=(list @ux)  t.bytes
  |-  ^-  code-section
  ?:  =(~ functions-bytes)
    ?>  =(num-functions 0)
    out(functions (flop functions.out))
  =/  one-function-length=@  (snag 0 functions-bytes)
  =/  one-function-bytes=(list @ux)
    %+  scag
      one-function-length
    (slag 1 functions-bytes)
  ?>  =(one-function-length (lent one-function-bytes))
  %=  $
    num-functions    (dec num-functions)
    functions-bytes  (slag (add 1 one-function-length) functions-bytes)
    functions.out    [(get-code one-function-bytes) functions.out]
  ==
::
++  get-code
  |=  bytes=(list @ux)
  ^-  function-body
  ?~  bytes  *function-body
  =|  out=function-body
  =/  locals-number=@  i.bytes
  =?  locals.out  !=(0 locals-number)
    =/  locals-bytes=(list @ux)  (scag (mul 2 locals-number) t.bytes)
    (unpack-locals-vector locals-bytes)
  =/  expressions-bytes=(list @ux)  (slag (mul 2 locals-number) t.bytes)
  out(expressions (parse-expressions expressions-bytes))
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
++  parse-expressions
  |=  bytes=(pole @ux)
  ^-  (list expression)
  ?:  =(~ bytes)  ~
  ?+    bytes  ~|(bytes !!)
      [op=?(%0x6a %0xb) rest=*]     ::  no immediate args
    =,  bytes
    [(parse-zero op) $(bytes rest)]
  ::
      [op=?(%0x20 %0x21) arg=@ux rest=*]  ::  one immediate arg
    =,  bytes
    [(parse-one op arg) $(bytes rest)]
  ==
::
++  parse-zero
  |=  op=?(%0x6a %0xb)
  ^-  expression
  ?-  op
    %0x6a  [%i32-add ~]
    %0xb  [%end ~]
  ==
::
++  parse-one
  |=  [op=?(%0x20 %0x21) arg=@ux]
  ^-  expression
  ?-  op
    %0x20  [%local-get arg]
    %0x21  [%local-set arg]
  ==
::
--