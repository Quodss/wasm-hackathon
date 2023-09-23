::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
:: 
%^    call-exported-function.ast-interpreter
    'addTwo'
  (main:wasm-to-ast bin-wasm) ::  .wasm -> AST parser
~[1.000 50]






