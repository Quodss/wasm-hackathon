::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/*  bin-wasm  %wasm  /flopper/wasm
:: /*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
::
:: =>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: -:(call-id (find-func-id 'fib' module) ~[[%i32 11]])
:: =+  buffer=buffer:(call-id (find-func-id 'fill' module) ~):(instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
:: (rip 3 buffer)
(main:wasm-to-ast bin-wasm)
