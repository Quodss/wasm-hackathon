::  %say generator without arguments, used for testing
::
/-  *wasm
/+  wasm
/+  wasm-to-ast
/*  two-functions-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun
::  end-to-end Wasm module interpretation
:: 
%^    call-exported-function.wasm
    'addTwo'
  (main:wasm-to-ast two-functions-wasm)
~[30 50]








