/-  *wasm
/+  *test
/+  ast-interpreter
/+  wasm-to-ast
/+  handle=handle-operators
/*  div-table  %wasm  /del-table/wasm
/*  fac-loop   %wasm  /fac-br/wasm
/*  fib-rust   %wasm  /fib/wasm
/*  fac-if     %wasm  /fac/wasm
/*  two-func   %wasm  /two-functions/wasm
/*  flopper    %wasm  /flopper/wasm
|%
++  test-table
  %+  expect-eq
    !>  `(list coin-wasm)`~[[type=%f32 n=.5.5]]
    !>
    =>  (instantiate:ast-interpreter (main:wasm-to-ast div-table))
    -:(call-id (find-func-id 'testdivtable' module) ~[[%f32 .11] [%f32 .2]])
::
++  test-loop
  %+  expect-eq
    !>  `(list coin-wasm)`~[[type=%i32 n=362.880]]
    !>
    =>  (instantiate:ast-interpreter (main:wasm-to-ast fac-loop))
    -:(call-id (find-func-id 'factorial' module) ~[[%i32 9]])
::
++  test-rust
  %+  expect-eq
    !>  `(list coin-wasm)`~[[type=%i32 n=102.334.155]]
    !>
    =>  (instantiate:ast-interpreter (main:wasm-to-ast fib-rust))
    -:(call-id (find-func-id 'fib' module) ~[[%i32 40]])
::
++  test-if
  %+  expect-eq
    !>  `(list coin-wasm)`~[[type=%f64 n=.~362880]]
    !>
    =>  (instantiate:ast-interpreter (main:wasm-to-ast fac-if))
    -:(call-id (find-func-id 'fac' module) ~[[%f64 .~9]])
::
++  test-two-functions
  %+  expect-eq
    !>  `(list coin-wasm)`~[[type=%i32 n=43]]
    !>
    =>  (instantiate:ast-interpreter (main:wasm-to-ast two-func))
    -:(call-id (find-func-id 'addTwo' module) ~[[%i32 21] [%i32 21]])
::
++  test-shr
  %+  expect-eq
    !>  -27
    !>
    %+  complement-to-si:handle  32
    =<  n
    %^  shr:handle  %i32  %s
    :-  [%i32 (si-to-complement:handle 32 -105)]
    [%i32 2]
++  test-flopper
  %+  expect-eq
    !>  `tape`(flop (gulf 'a' 'z'))
    !>
    =/  string-in=tape  (gulf 'a' 'z')
    =+  hwasm=(instantiate:ast-interpreter (main:wasm-to-ast flopper))
    ::  get retptr:
    ::
    =^  out  hwasm
      %+  call-id:hwasm
        (find-func-id:hwasm '__wbindgen_add_to_stack_pointer' module.hwasm)
      ~[[%i32 (si-to-complement:handle 32 -16)]]
    =/  retptr=@  ?>(?=(^ out) n.i.out)
    ::  pass string to wasm:
    ::
    =^  out  hwasm
      %+  call-id:hwasm
        (find-func-id:hwasm '__wbindgen_malloc' module.hwasm)
      ~[[%i32 (lent string-in)] [%i32 1]]
    =/  ptr0=@  ?>(?=(^ out) n.i.out)
    =/  len0=@  (lent string-in)
    =.  buffer.hwasm
      (sew bloq=3 [ptr0 size=len0 (crip string-in)] buffer.hwasm)
    ::  run `process`
    ::
    =.  hwasm
      =<  +
      %+  call-id:hwasm
        (find-func-id:hwasm 'process' module.hwasm)
      ~[[%i32 retptr] [%i32 ptr0] [%i32 len0]]
    ::  get r0 and r1 at retptr
    ::
    =/  r0=@  (cut 3 [retptr 4] buffer.hwasm)
    =/  r1=@  (cut 3 [(add retptr 4) 4] buffer.hwasm)
    ::  get string with r0 and r1
    ::
    =/  string-out=tape
      %-  trip
      (cut 3 [r0 r1] buffer.hwasm)
    ::  free the memory? nah, later
    string-out
  ::
  --