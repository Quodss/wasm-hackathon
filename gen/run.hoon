::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/+  handle=handle-operators
/*  bin-wasm  %wasm  /flopper/wasm
:: /*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
::
:: =>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: -:(call-id (find-func-id 'fib' module) ~[[%i32 11]])
:: =>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: -:(call-id (find-func-id 'testdivtable' module) ~[[%f32 .11] [%f32 .2]])
:: =+  buffer=buffer:(call-id (find-func-id 'fill' module) ~):(instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: (rip 3 buffer)
:: (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: (main:wasm-to-ast bin-wasm)
=/  string-in=tape  (zing (reap 100 (gulf 'a' 'z')))
=+  hwasm=(instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
::  get retptr:
::
=^  out  hwasm
  ~&  "ADD TO STACK POINTER"
  %+  call-id:hwasm
    (find-func-id:hwasm '__wbindgen_add_to_stack_pointer' module.hwasm)
  ~[[%i32 (si-to-complement:handle 32 -16)]]
=/  retptr=@  ?>(?=(^ out) n.i.out)
~&  "retptr={<retptr>}"
::  pass string to wasm:
::
=^  out  hwasm
  ~&  "MALLOC"
  %+  call-id:hwasm
    (find-func-id:hwasm '__wbindgen_malloc' module.hwasm)
  ~[[%i32 (lent string-in)] [%i32 1]]
=/  ptr0=@  ?>(?=(^ out) n.i.out)
=/  len0=@  (lent string-in)
=.  buffer.hwasm
  (sew bloq=3 [ptr0 size=len0 (crip string-in)] buffer.hwasm)
~&  "ptr0={<ptr0>}"
::  run `process`
::
=.  hwasm
  =<  +
  ~&  "PROCESS"
  %+  call-id:hwasm
    (find-func-id:hwasm 'process' module.hwasm)
  ~[[%i32 retptr] [%i32 ptr0] [%i32 len0]]
::  get r0 and r1 at retptr
::
=/  r0=@  (cut 3 [retptr 4] buffer.hwasm)
=/  r1=@  (cut 3 [(add retptr 4) 4] buffer.hwasm)
~&  [r0 r1]
::  get string with r0 and r1
::
=/  string-out=tape
  %-  trip
  (cut 3 [r0 r1] buffer.hwasm)
::  free the memory? nah, later
::
:: hwasm
string-out