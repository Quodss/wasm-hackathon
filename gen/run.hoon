::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/*  two-functions-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun
::  end-to-end Wasm module interpretation
:: 
%^    call-exported-function.ast-interpreter
    'addTwo'
  (main:wasm-to-ast two-functions-wasm)
~[30 50]








