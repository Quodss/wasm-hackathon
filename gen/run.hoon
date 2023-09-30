::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/*  bin-wasm  %wasm  /fac-br/wasm
:: /*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
::
=>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
(call-id (find-func-id 'factorial' module) ~[[%i32 10]])
::
