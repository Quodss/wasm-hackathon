::  %say generator without arguments, used for testing
::
/-  *wasm
/+  wasm
/+  wasm-to-ast
/*  addtwo-wasm  %wasm  /add-two/wasm
:-  %say  |=  *  :-  %noun
::  end-to-end Wasm module interpretation
:: 
%^    draft-interpret-module.wasm
    'addTwo'
  (main:wasm-to-ast addtwo-wasm)
~[10 2]








