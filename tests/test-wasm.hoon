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
++  test-two
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
--