::  Very rough sketch, didn't try to compile
::
/-  *wasm
|^  wasm=@
^-  module
=/  wasm-bytes=(list @ux)  (rip 3 addtwo)
?>  .=  (scag 8 wasm-bytes)
    ^~  %+  weld
          ~[0x0 "asm"]        ::  binary magic
        ~[0x1 0x0 0x0 0x0]    ::  Wasm version
=.  wasm-bytes  (slag 8 wasm-bytes)
=|  =module
|-  ^-  module
?~  wasm-bytes  module
=/  section-code=@ux  i.wasm-bytes
?~  t.wasm-bytes  !!
=/  section-size=@  i.t.wasm-bytes
=/  section-bytes=(list @ux)  (scag section-size t.t.wasm-bytes)
?>  =(section-size (lent section-bytes))
?+  section-code  !!
  %0x1   $(type-section.module (get-type-section section-bytes), wasm-bytes (slag section-size t.t.wasm-bytes))
  %0x3   $(function-section.module (get-function-section section-bytes), wasm-bytes (slag section-size t.t.wasm-bytes))
  %0x7   $(export-section.module (get-export-section section-bytes), wasm-bytes (slag section-size t.t.wasm-bytes))
  %0x10  $(code-section.module (get-code-section section-bytes), wasm-bytes (slag section-size t.t.wasm-bytes))
  %0x0   $(wasm-bytes (slag section-size t.t.wasm-bytes))  ::  custom section is ignored
==
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
  ?~  type-bytes  out(types (flop types))
  ?>  =(i.type-bytes %0x60)
  $(types.out [(get-func-type t.type-bytes) types.out])
::
++  get-func-type
  |=  bytes=(list @ux)
  ^-  func-type
  =|  out=func-type
  =.  num-params.out  (snag 0 bytes)
  =.  params.out  (turn (swag [1 num-params.out] bytes) get-valtype)
  =.  num-results.out  (snag (add 1 num-params.out) bytes)
  =.  results.out  (turn (swag [(add 2 num-params.out) num-results.out] bytes) get-valtype)
  ?>  =(num-results.out (lent results.out))
  out
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
  |-  ^-  export-section
  =/  length-name=@  (snag 0 exports-bytes)
  =/  one-export-bytes=(list @ux)  (swag [1 (add 2 length-name)] exports-bytes)
  ?>  =((add 2 length-name) (lent one-export-bytes))
  =/  name=@t  (crip (slag length-name one-export-bytes))
  =/  export-desc-byte=@ux  (snag length-name one-export-bytes)
  ?>  =(export-desc-byte %0x0)
  =/  export-index-byte=@ux  (snag (add 1 length-name) one-export-bytes)
  %=  $
    exports-bytes  (slag (add 3 length-name) exports-bytes)
    out  (~(put by out) name %func export-index-byte)
  ==
::
++  get-code-section
  |=  bytes=(list @ux)
  ^-  code-section
  !!
